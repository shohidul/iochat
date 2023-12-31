// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:iochat/screen/home_screen.dart';
import 'package:iochat/utilities/constants.dart';
import 'package:iochat/utilities/di.dart';
// import 'package:iochat/utilities/navigation_service.dart';
import 'package:iochat/utilities/subject.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

final Completer<InAppWebViewController> _webViewCompleter = locator<Completer<InAppWebViewController>>();

// Future<String> getUserAgent() async {
//   PackageInfo packageInfo = await PackageInfo.fromPlatform();
//   String os = Platform.operatingSystem;
//   String osVer = Platform.operatingSystemVersion;
//   String appVer = '${packageInfo.version}+${packageInfo.buildNumber}';
//   return '$os/$osVer iochat/$appVer (${Constants.callbackUrlScheme}) ${getSafeAreaPadding()}';
// }

// String getSafeAreaPadding() {
//   String padding = '';

//   BuildContext? context = NavigationService.navigatorKey.currentContext;
//   if (context != null) {
//     EdgeInsets insets = MediaQuery.of(context).padding;
//     int paddingTop = insets.top.toInt();
//     int paddingRight = insets.right.toInt();
//     int paddingBottom = insets.bottom.toInt();
//     int paddingLeft = insets.left.toInt();
//     padding = '(SafeArea $paddingTop $paddingRight $paddingBottom $paddingLeft)';
//   }
//   return padding;
// }

void handleBackSwipe() {
  if (Subject.getInstance().hasAuthenticationCookie()) {
    _webViewCompleter.future.then((controller) async {
      controller.getUrl().then((url) async {
        if (isLoginUrl(url)) {
          controller.callAsyncJavaScript(functionBody: 'document.body.style.opacity="0"');
          controller.goForward();
        }
      });
    });
  }
}

bool isLoginUrl(url) {
  String? currentPath = url!.toString();
  String currentHost = Uri.parse(currentPath).host;
  if (currentPath != '' &&
      (Constants.loginUrls.contains(currentHost) ||
          currentPath.contains('$currentHost/do/login') ||
          currentPath.contains('$currentHost/login') ||
          (currentPath.contains('/login-form')))) {
    return true;
  }
  return false;
}

Future<bool> handleBack() {
  _webViewCompleter.future.then((controller) async {
    if (await controller.canGoBack()) {
      await controller.getUrl().then((url) async {
        String? currentPath = url?.path;
        String previousPath = await _previousPath(controller, currentPath);
        String previousHost = Uri.parse(previousPath).host;
        if (previousPath != '' &&
            !Constants.loginUrls.contains(previousHost) &&
            !previousPath.contains('$previousHost/do/login') &&
            !previousPath.contains('$previousHost/login') &&
            !(currentPath != null && currentPath.contains('/login-form'))) {
          controller.goBack();
        } else {
          controller.loadUrl(urlRequest: URLRequest(url: WebUri(Subject.getInstance().getDomainUrl())));
        }
      });
    } else {
      // if no history redirect home
      controller.loadUrl(urlRequest: URLRequest(url: WebUri(Subject.getInstance().getDomainUrl())));
    }
  });
  return Future.value(false);
}

Future<String> _previousPath(InAppWebViewController controller, currentPath) async {
  WebHistory? webHistory = await controller.getCopyBackForwardList();
  String previousPath = '';
  List<WebHistoryItem>? webHistoryItems = webHistory?.list;

  for (WebHistoryItem webHistoryItem in webHistoryItems!) {
    if (webHistoryItem.url!.path == currentPath) {
      break;
    }
    previousPath = webHistoryItem.url!.origin + webHistoryItem.url!.path;
  }
  return previousPath;
}

String getLocale() => Platform.localeName;

Future<void> redirectToExternalBrowser(WebUri uri) async {
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw 'Couldn\'t launch ${uri.toString()}';
  }
}

bool isInternalUrl(WebUri? uri) {
  String? hostUrl = uri?.host;
  if (hostUrl == null || hostUrl.isEmpty || Constants.disallowedDomains.contains(hostUrl)) {
    return false;
  }

  List<String> parts = hostUrl.split('.');
  String domainName = parts[parts.length - 2];
  String tld = parts[parts.length - 1];

  List<String> domains = [...Constants.allowedDomains, ...Constants.customDomains.split(',')];
  bool isDomainAllowed = domains.any((element) => element.endsWith('$domainName.$tld'));
  return isDomainAllowed;
}

void showSnackBar(context, message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    duration: const Duration(seconds: 2),
    backgroundColor: Colors.black54,
    action: SnackBarAction(
      label: 'Dismiss',
      onPressed: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      },
    ),
  ));
}

void showAlertDialog(BuildContext context, String title, String content) {
  // close any open dialog but HomeScreen
  Navigator.popUntil(context, ModalRoute.withName(HomeScreen.routeName));
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [TextButton(child: const Text('OK'), onPressed: () => Navigator.pop(context))],
    ),
  );
}

String getDeviceType() {
  final data = MediaQueryData.fromView(PlatformDispatcher.instance.views.first);
  return data.size.shortestSide < 600 ? Constants.typeDevicePhone : Constants.typeDeviceTablet;
}

Map<String, String> getHeaders() => {'ngrok-skip-browser-warning': 'anyvalue'};
