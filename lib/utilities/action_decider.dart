// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:iochat/screen/home_screen.dart';
import 'package:iochat/utilities/constants.dart';
import 'package:iochat/utilities/common_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'di.dart';
import 'subject.dart';
import 'widget_builder.dart';

final Completer<InAppWebViewController> _webViewCompleter = locator<Completer<InAppWebViewController>>();
bool _isImmediateReload = false;

void customAction(String parent, Map<dynamic, dynamic> actionData, BuildContext context, {dynamic data}) async {
  var action = actionData['type'];
  _isImmediateReload = false;
  if (Constants.openUrl == action) {
    WebUri url = WebUri(actionData['url']);
    if (isInternalUrl(url)) {
      _webViewCompleter.future.then((value) async {
        await value.loadUrl(urlRequest: URLRequest(url: url, headers: getHeaders()));
      });
    } else {
      redirectToExternalBrowser(url);
    }
  } else if (Constants.clickElement == action) {
    String id = actionData['id'];
    _webViewCompleter.future.then((value) async {
      var progress = await value.getProgress();
      if (!_isWebViewLoaded(context, progress)) {
        showSnackBar(context, Constants.labelBusyLoading);
      } else {
        await value.callAsyncJavaScript(functionBody: 'document.getElementById("$id").click()');
      }
    });
  } else if (Constants.showView == action) {
    _webViewCompleter.future.then((value) async {
      var progress = await value.getProgress();
      if (!_isWebViewLoaded(context, progress) && parent == Constants.top) {
        showSnackBar(context, Constants.labelBusyLoading);
      } else {
        Map<dynamic, dynamic> viewData = data['action']['view'];
        buildWidget(parent, viewData, context);
      }
    });
  } else if (Constants.goBack == action) {
    handleBack();
  } else if (Constants.reset == action) {
    _showCustomDialog(context);
  }
}

void _showCustomDialog(BuildContext context) {
  // Close any open dialog but HomeScreen
  Navigator.popUntil(context, ModalRoute.withName(HomeScreen.routeName));
  String title = 'Do you want to log out and reset the app?';

  Platform.isIOS
      ? showCupertinoModalPopup(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: Text(title),
              actions: _buildDialogActions(context),
            );
          },
          barrierDismissible: false,
        )
      : showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              actions: _buildDialogActions(context),
            );
          },
          barrierDismissible: false,
        );
}

List<Widget> _buildDialogActions(BuildContext context) {
  return [
    Platform.isIOS
        ? CupertinoDialogAction(
            onPressed: () => _logoutAction(context),
            child: const Text(
              'Log out',
              style: TextStyle(color: Colors.red),
            ),
          )
        : TextButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.red),
              padding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.fromLTRB(15.0, 2.0, 15.0, 2.0)),
            ),
            onPressed: () => _logoutAction(context),
            child: const Text(
              'Log out',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
    Platform.isIOS
        ? CupertinoDialogAction(
            child: const Text(
              'Cancel',
            ),
            onPressed: () => Navigator.pop(context),
          )
        : TextButton(
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.pop(context),
          ),
  ];
}

Future<void> _logoutAction(BuildContext context) async {
  final CookieManager cookieManager = locator<CookieManager>();
  final Subject subjectInstance = Subject.getInstance();

  await Future.wait([
    cookieManager.deleteAllCookies(),
    subjectInstance.clear(),
  ]);

  WebUri baseUrl = WebUri(Constants.baseUrl);
  _webViewCompleter.future.then((value) async {
    await value.loadUrl(urlRequest: URLRequest(url: baseUrl, headers: getHeaders()));
  });

  Navigator.pop(context);
}

bool _isWebViewLoaded(context, progress) {
  progress = progress ?? 0; // if null set 0
  return progress >= 100;
}

bool isImmediateReload() {
  return _isImmediateReload;
}

Future<void> reloadWebView() async {
  _isImmediateReload = true;
  _webViewCompleter.future.then((controller) async {
    if (Platform.isAndroid) {
      controller.reload();
    } else if (Platform.isIOS) {
      controller.loadUrl(urlRequest: URLRequest(url: await controller.getUrl(), headers: getHeaders()));
    }
  });
}
