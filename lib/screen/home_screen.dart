import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:developer';
import 'dart:ui';

import 'package:iochat/utilities/local_notification_service.dart';
import 'package:iochat/utilities/useragent.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:flutter/material.dart';

import '../utilities/action_decider.dart';
import '../utilities/app_uni_link.dart';
import '../utilities/common_util.dart';
import '../utilities/di.dart';
import '../utilities/file_download_util.dart';
import '../utilities/firebase_init.dart';
import '../utilities/navigation_service.dart';
import '../utilities/receive_share_content.dart';
import '../utilities/subject.dart';
import '../widgets/nav_bar.dart';
import '../utilities/constants.dart';
import '../widgets/app_bar.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/homeScreen';
  final homeScreenKey = GlobalKey<_HomeScreenState>();

  HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final Completer<InAppWebViewController> _webViewCompleter = locator<Completer<InAppWebViewController>>();
  InAppWebViewController? webViewController;

  final ReceivePort _port = ReceivePort();
  // late String _webUserAgent;
  bool isAppBarDataExists = false;
  bool isNavBarDataExists = false;
  Map<dynamic, dynamic> appBarData = {};
  List<dynamic> navBarData = [];
  bool isLoading = true;
  bool _isOnLoadError = false;
  String _errorMessage = '';
  late PullToRefreshController pullToRefreshController;
  final CookieManager _cookieManager = locator<CookieManager>();
  final Subject _subject = Subject.getInstance();

  int progress = 0;
  Widget animatedWidget = const SizedBox.shrink();

  final ReceiveShareContent _receiveShareContent = ReceiveShareContent.getInstance();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) async {
      await FileDownloadUtil.fileDownloadStatus(data);
    });

    FlutterDownloader.registerCallback(_downloadCallback);

    // getUserAgent().then((userAgent) {
    setState(() {
      // _webUserAgent = userAgent;
      isLoading = false;
    });
    // });

    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Constants.progressIndicatorColor,
        // backgroundColor: Colors.transparent,
      ),
      onRefresh: () async {
        reloadWebView();
      },
    );

    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      _receiveShareContent.listenShareMediaFiles(context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
    }
  }

  @override
  Widget build(BuildContext context) {
    AppUniLink appUniLink = Provider.of<AppUniLink>(context);
    return WillPopScope(
        onWillPop: () async {
          return handleBack();
        },
        child: Scaffold(
            extendBodyBehindAppBar: Constants.behindAppBar && isAppBarDataExists,
            appBar: isAppBarDataExists ? CustomAppBar(appBarData) : topSafeArea(),
            body: SafeArea(
              top: !Constants.behindAppBar || !isAppBarDataExists,
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                      color: Constants.progressIndicatorColor,
                    ))
                  : Stack(
                      children: [
                        InAppWebView(
                          initialUrlRequest: _getInitialUrl(),
                          pullToRefreshController: pullToRefreshController,
                          initialSettings: InAppWebViewSettings(
                            useOnDownloadStart: true,
                            javaScriptCanOpenWindowsAutomatically: true,
                            mediaPlaybackRequiresUserGesture: false,
                            cacheEnabled: true,
                            useShouldOverrideUrlLoading: true,
                            javaScriptEnabled: true,
                            applicationNameForUserAgent: UserAgent.getInstance().get(),
                            useHybridComposition: true,
                            allowsInlineMediaPlayback: true,
                          ),
                          onLoadStart: (controller, url) {
                            _isOnLoadError = false;
                            if (isImmediateReload()) {
                              setState(() {
                                animatedWidget = _customCircularProgressIndicator();
                              });
                            } else {
                              Future.delayed(const Duration(seconds: 1), () {
                                if (progress < 100) {
                                  setState(() {
                                    animatedWidget = _customCircularProgressIndicator();
                                  });
                                }
                              });
                            }
                          },
                          onProgressChanged: (controller, progress) {
                            this.progress = progress;
                          },
                          onWebViewCreated: (controller) async {
                            webViewController = controller;
                            _webViewCompleter.complete(controller);
                            _webViewCompleter.future
                                .then((webViewController) => appUniLink.controller = webViewController);
                            appUniLink.initialize();
                          },
                          shouldOverrideUrlLoading: (controller, navigationAction) async {
                            handleBackSwipe();

                            WebUri? requestUrl = navigationAction.request.url;
                            if (requestUrl == null) {
                              return NavigationActionPolicy.CANCEL;
                            }

                            // hack: txt & xml files does not call on onDownloadStartRequest
                            String fileUrl = requestUrl.toString();
                            List<String> pathSegments = WebUri(fileUrl).pathSegments;
                            if (pathSegments.isNotEmpty) {
                              String fileName = pathSegments.last;
                              String fileExtension = fileName.split('.').last;
                              bool isFileExtensionMatched = Constants.unsupportedFileExtensions.contains(fileExtension);
                              if (Platform.isIOS && isFileExtensionMatched) {
                                FileDownloadUtil.setDownloadRequestFilename(fileName);
                                await FileDownloadUtil.downloadFile(requestUrl);
                                return NavigationActionPolicy.CANCEL;
                              }
                            }

                            // allows iframe urls
                            if (!navigationAction.isForMainFrame) {
                              return NavigationActionPolicy.ALLOW;
                            }

                            if (isInternalUrl(requestUrl)) {
                              return NavigationActionPolicy.ALLOW;
                            }

                            if (_isOpenIdConnectLogin(requestUrl)) {
                              await _startOpenIdConnectLoginSession(requestUrl.toString(), controller);
                              return NavigationActionPolicy.CANCEL;
                            }

                            redirectToExternalBrowser(requestUrl);
                            return NavigationActionPolicy.CANCEL;
                          },
                          onLoadStop: (controller, uri) async {
                            pullToRefreshController.endRefreshing();
                            if (!_isOnLoadError) {
                              setState(() {
                                animatedWidget = const SizedBox.shrink();
                              });
                            }

                            // get json for the app navigation
                            dynamic appNavigation = await controller.evaluateJavascript(
                              source: '''
                                var result = null;
                                if (typeof appNavigation !== 'undefined' && appNavigation !== null) {
                                  result = JSON.stringify(appNavigation);
                                }
                                result;
                              ''',
                            );
                            _parseAppNavigationJson(appNavigation);

                            // moved to server-side
                            // viadesk hack: scroll to bottom of the direct message page
                            // controller.evaluateJavascript(source: '''
                            //   const conversationContainer = document.querySelector(".conversation-container");
                            //   if (conversationContainer) {
                            //     conversationContainer.scrollTop = conversationContainer.scrollHeight;
                            //   }
                            // ''');

                            await _updateBadgeCount();

                            Cookie? cookie = await _cookieManager.getCookie(url: uri!, name: 'session');
                            String cookieString = cookie?.value ?? '';

                            Future.delayed(const Duration(seconds: 2)).then((val) async {
                              dynamic currentUser = await controller.evaluateJavascript(
                                source: '''
                                  var result = null;
                                  if (typeof currentUser !== 'undefined' && currentUser !== null) {
                                    result = JSON.stringify(currentUser);
                                  }
                                  result;
                                ''',
                              );
                              if (currentUser != null) {
                                print('currentUser delayed $currentUser');
                                Map<dynamic, dynamic> user = jsonDecode(currentUser);
                                print('uid>>>> ${user['uid']}');
                                listenFCMDeviceToken(user['uid']);
                              }
                            });
                          

                            // update and save the subject
                            if (isNotSharePath(uri) &&
                                !isLoginUrl(uri) &&
                                isInternalUrl(uri) &&
                                _subject.update(uri.toString(), cookieString)) {
                              _subject.save(uri.toString(), cookieString);
                            }

                            // Set SharePanel value false to reload the expired page when necessary
                            _receiveShareContent.setSharePanel(false);
                          },
                          onReceivedError: (controller, request, error) {
                            if (error.type.toNativeValue() == Constants.offline) {
                              setState(() {
                                _isOnLoadError = true;
                                _errorMessage = error.description;
                                animatedWidget =
                                    Container(color: Colors.white, child: Center(child: Text(_errorMessage)));
                              });
                              pullToRefreshController.endRefreshing();
                            }
                          },
                          onDownloadStartRequest: (controller, request) async {
                            FileDownloadUtil.setDownloadRequestFilename(request.suggestedFilename ?? '');
                            await FileDownloadUtil.downloadFile(request.url);
                          },
                          onJsAlert: (controller, jsAlertRequest) async {
                            String title = jsAlertRequest.message.toString().substring(0, 30);
                            String content = jsAlertRequest.url.toString();
                            showAlertDialog(context, title, content);
                            return JsAlertResponse(handledByClient: true);
                          },
                        ),
                        AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: animatedWidget)
                      ],
                    ),
            ),
            bottomNavigationBar: CustomNavBar(
              navBarData: navBarData,
              key: widget.homeScreenKey,
            )));
  }

  Container _customCircularProgressIndicator() {
    return Container(
      color: Colors.white.withOpacity(0.8),
      child: Center(
          child: Container(
        width: 64.0,
        height: 64.0,
        padding: const EdgeInsets.all(15.0),
        decoration: const BoxDecoration(
          // color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const CircularProgressIndicator(
          color: Constants.progressIndicatorColor,
        ),
      )),
    );
  }

  void _parseAppNavigationJson(dynamic appNavigation) {
    if (appNavigation != null) {
      Map<dynamic, dynamic> jsonData = jsonDecode(appNavigation);
      setState(() {
        isAppBarDataExists = jsonData[Constants.top] != null;
        appBarData = isAppBarDataExists ? jsonData[Constants.top] : {};

        isNavBarDataExists = jsonData[Constants.bottom] != null;
        navBarData = isNavBarDataExists ? jsonData[Constants.bottom]['center'][0]['items'] : [];
      });
    } else {
      setState(() {
        isAppBarDataExists = false;
        isNavBarDataExists = false;
        appBarData = {};
        navBarData = [];
      });
    }
  }

  Future<void> _updateBadgeCount() async {
    if (await FlutterAppBadger.isAppBadgeSupported()) {
      int badgeCount = 0;
      for (Map<String, dynamic> navdata in navBarData) {
        String? type = navdata['type'];
        if (Constants.iconButton == type) {
          int unreadCount = navdata['unreadCount'] ?? 0;
          badgeCount += unreadCount;
        }
      }
      if (badgeCount == 0) {
        await LocalNotificationService.clearAllNotifications();
      }
      FlutterAppBadger.updateBadgeCount(badgeCount);
    }
  }

  bool _isOpenIdConnectLogin(WebUri uri) {
    String url = uri.toString();
    return url.contains(Constants.clientID) && url.contains(Constants.redirectURI);
  }

  Future<void> _startOpenIdConnectLoginSession(String url, InAppWebViewController controller) async {
    final result = await FlutterWebAuth.authenticate(url: url, callbackUrlScheme: Constants.callbackUrlScheme);
    String redirectUrl = result.replaceFirst(Constants.callbackUrlScheme, 'https');
    controller.loadUrl(urlRequest: URLRequest(url: WebUri(redirectUrl)));
  }

  URLRequest _getInitialUrl() {
    WebUri url = _subject.hasCurrentUrl() ? WebUri(_subject.getCurrentUrl()) : WebUri(Constants.baseUrl);
    return URLRequest(url: url, headers: getHeaders());
  }

  bool isNotSharePath(Uri uri) => !uri.path.contains(Constants.sharePath);
}

@pragma('vm:entry-point')
void _downloadCallback(String id, int status, int progress) {
  try {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send!.send([id, status, progress]);
  } on Exception catch (e) {
    log(e.toString());
  }
}

Material bottomSafeArea() {
  BuildContext? context = NavigationService.navigatorKey.currentContext;
  EdgeInsets padding = context != null
      ? EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom)
      : const EdgeInsets.only(bottom: 0);
  return Material(
    color: Constants.navBarBackgroudColor,
    child: Padding(
      padding: padding,
    ),
  );
}

PreferredSizeWidget topSafeArea() {
  return AppBar(
      elevation: 0,
      toolbarHeight: 0,
      backgroundColor: Constants.appBarBackgroundColor,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Constants.appBarBackgroundColor,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ));
}
