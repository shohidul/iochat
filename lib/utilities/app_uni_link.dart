import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:uni_links/uni_links.dart';

import 'common_util.dart';

bool initialUriIsHandled = false;

class AppUniLink extends ChangeNotifier {
  Uri? initialUri;
  Uri? latestUri;
  Object? err;
  late InAppWebViewController controller;
  late String test;

  StreamSubscription? sub;

  initialize() {
    handleIncomingLinks();
    handleInitialUri();
  }

  @override
  void dispose() {
    super.dispose();
    initialUri = null;
    latestUri = null;
    sub?.cancel();
  }

  set webcon(InAppWebViewController con) {
    controller = con;
    notifyListeners();
  }

  void handleIncomingLinks() {
    if (!kIsWeb) {
      sub = uriLinkStream.listen((Uri? uri) async {
        // log('got uri: $uri');
        await controller.loadUrl(urlRequest: URLRequest(url: WebUri(uri.toString()), headers: getHeaders()));
      }, onError: (Object err) {
        log('got err: $err');
        latestUri = null;
        if (err is FormatException) {
          err = err;
        } else {
          err = Object();
        }
      });
    }
  }

  Future<void> handleInitialUri() async {
    if (!initialUriIsHandled) {
      initialUriIsHandled = true;
      try {
        final uri = await getInitialUri();
        if (uri == null) {
          // log('no initial uri');
        } else {
          // log('got initial uri: $uri');
          await controller.loadUrl(urlRequest: URLRequest(url: WebUri(uri.toString()), headers: getHeaders()));
        }
      } on PlatformException {
        log('falied to get initial uri');
      } on FormatException catch (e) {
        log('malformed initial uri');
        err = e;
      }
    }
  }
}
