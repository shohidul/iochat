import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:iochat/utilities/app_uni_link.dart';
import 'package:iochat/utilities/di.dart';
import 'package:iochat/utilities/navigation_service.dart';
import 'package:iochat/utilities/subject.dart';
import 'package:iochat/utilities/useragent.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import './screen/home_screen.dart';
import 'utilities/constants.dart';
import 'utilities/common_util.dart';
import 'utilities/local_notification_service.dart';
import 'package:flutter_config/flutter_config.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Handling a background message: ${message.messageId}');
}

void main() async {
  // marc disabled this to make status bar translucent on Android:
  // bug: does not work with iOS
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    //   statusBarBrightness: Brightness.dark,
    //   systemNavigationBarDividerColor: Colors.white,
    //   statusBarColor: Colors.white,
    //   statusBarIconBrightness: Brightness.dark, // status bar icon color
    systemNavigationBarColor: Colors.white, // navigation bar color
    systemNavigationBarIconBrightness: Brightness.dark, // color of navigation controls
  ));

  WidgetsFlutterBinding.ensureInitialized();
  await FlutterConfig.loadEnvVariables();

  if (getDeviceType() == Constants.typeDevicePhone) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }
  setupLocator();
  getLocale();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  LocalNotificationService.initialize();
  await FlutterDownloader.initialize(
      debug: false, // optional: set to false to disable printing logs to console (default: true)
      ignoreSsl: false // option: set to false to disable working with http links (default: false)
      );

  if (Platform.isAndroid) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  await Permission.camera.request();
  await Permission.microphone.request();
  await Permission.notification.request();

  await Subject.getInstance().load();
  await UserAgent.getInstance().create();

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => AppUniLink(),
          ),
        ],
        child: MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          title: Constants.appTitle,
          theme: ThemeData(
              pageTransitionsTheme: const PageTransitionsTheme(builders: {
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          })),
          debugShowCheckedModeBanner: false,
          initialRoute: HomeScreen.routeName,
          routes: {HomeScreen.routeName: (ctx) => HomeScreen()},
        ));
  }
}
