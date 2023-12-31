import 'dart:convert';
import 'package:iochat/utilities/common_util.dart';
import 'package:iochat/utilities/di.dart';
import 'package:iochat/utilities/useragent.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'subject.dart';

FirebaseMessaging _firebaseMessaging = locator<FirebaseMessaging>();
Subject _subject = Subject.getInstance();

void listenFCMDeviceToken(String uri, String cookieString) {
  if (cookieString.isNotEmpty && _subject.isChanged(uri, cookieString)) {
    _firebaseMessaging.getToken().then((token) {
      if (token != null) sendDeviceToken(token, cookieString);
    });
  }
  _firebaseMessaging.onTokenRefresh.listen((token) {
    if (cookieString.isNotEmpty) {
      sendDeviceToken(token, cookieString);
    }
  });
}

void sendDeviceToken(String token, String sessionId) async {
  // String userAgent = await getUserAgent();
  final url = Uri.parse('${_subject.getDomainUrl()}/api/v1/iochat/tokens');

  Map<String, String> headers = getHeaders();
  headers.addAll({
    'Content-Type': 'application/x-www-form-urlencoded',
    'Authorization': 'Session $sessionId',
    'User-Agent': UserAgent.getInstance().get()
  });

  try {
    await http.post(
      url,
      headers: headers,
      body: {'secret': token},
      encoding: Encoding.getByName('utf-8'),
    );
  } catch (e) {
    debugPrint(e.toString());
  }
}
