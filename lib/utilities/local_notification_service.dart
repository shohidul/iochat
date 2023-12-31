import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:iochat/utilities/di.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';

import 'common_util.dart';

class LocalNotificationService {
  static final Completer<InAppWebViewController> _controller = locator<Completer<InAppWebViewController>>();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = locator<FirebaseMessaging>();

  static Future<void> clearAllNotifications() async {
    _notificationsPlugin.cancelAll();
  }

  static Future<void> initialize() async {
    // IOS Notification Initialization
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );
    // initializationSettings for Andoird & IOS
    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: initializationSettingsIOS,
    );

    // IOS Local Notification Initialize
    if (Platform.isIOS) {
      _firebaseMessaging.requestPermission();
      _firebaseMessaging.getNotificationSettings();
    }

    // 1. This method only call when App is terminated(closed)
    _firebaseMessaging.getInitialMessage().then(
      (message) {
        if (message != null) {
          if (message.data['url'] != null) {
            String url = message.data['url'];
            _controller.future.then((value) async {
              await value.loadUrl(urlRequest: URLRequest(url: WebUri(url), headers: getHeaders()));
            });
          }
        }
      },
    );

    // 2. This method only call when App in forground it mean app must be opened
    FirebaseMessaging.onMessage.listen(
      (message) {
        if (message.notification != null) {
          LocalNotificationService.createAndDisplayNotification(message);
        }
      },
    );

    // 3. This method only call when App in background and not terminated(not closed)
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        if (message.data['url'] != null) {
          String url = message.data['url'];
          _controller.future.then((value) async {
            await value.loadUrl(urlRequest: URLRequest(url: WebUri(url), headers: getHeaders()));
          });
        }
      },
    );

    _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        String? payload = response.payload;
        if (payload != null) {
          Map<String, dynamic> jsonData = jsonDecode(payload);
          String? url = jsonData['url'];
          String? filePath = jsonData['filePath'];

          if (filePath != null) {
            OpenFilex.open(filePath);
          } else if (url != null) {
            _controller.future.then((value) async {
              await value.loadUrl(urlRequest: URLRequest(url: WebUri(url), headers: getHeaders()));
            });
          }
        }
      },
    );
  }

  static void createAndDisplayNotification(RemoteMessage message) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'iochat',
          'iochatpushnotificationappchannel',
          importance: Importance.max,
          priority: Priority.high,
          color: Colors.white,
        ),
      );

      await _notificationsPlugin.show(
        id,
        message.notification!.title,
        message.notification!.body,
        notificationDetails,
        payload: jsonEncode(message.data),
      );
    } on Exception catch (e) {
      log(e.toString());
    }
  }

  static void onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) {}

  static Future<NotificationDetails> _notificationDetails() async {
    AndroidNotificationDetails androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'iochat',
      'iochatpushnotificationappchannel',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.white,
    );
    DarwinNotificationDetails iosNotificationDetails =
        const DarwinNotificationDetails(threadIdentifier: 'iochat', attachments: <DarwinNotificationAttachment>[]);

    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics, iOS: iosNotificationDetails);

    return platformChannelSpecifics;
  }

  // show local custom notification
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final platformChannelSpecifics = await _notificationDetails();
    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload ?? '',
    );
  }
}
