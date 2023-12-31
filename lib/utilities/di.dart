import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get_it/get_it.dart';

GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => Completer<InAppWebViewController>());
  locator.registerLazySingleton(() => FirebaseMessaging.instance);
  locator.registerLazySingleton(() => CookieManager.instance());
}
