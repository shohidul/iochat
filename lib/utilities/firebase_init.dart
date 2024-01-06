import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iochat/utilities/di.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'subject.dart';

FirebaseMessaging _firebaseMessaging = locator<FirebaseMessaging>();
Subject _subject = Subject.getInstance();

void listenFCMDeviceToken(String uid) {
    _firebaseMessaging.getToken().then((token) {
      print('token $token');
      if (token != null) sendDeviceToken(token, uid);
    });
  _firebaseMessaging.onTokenRefresh.listen((token) {
      sendDeviceToken(token, uid);
  });
}

void sendDeviceToken(String token, String uid) async {

  try {
      CollectionReference tokensCollection = FirebaseFirestore.instance.collection('tokens');

      // Check if the token already exists for the user
      QuerySnapshot querySnapshot = await tokensCollection
          .where('token', isEqualTo: token)
          .where('uid', isEqualTo: uid)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Token doesn't exist for the user, add it to Firestore
        await tokensCollection.add({
          'uid': uid,
          'token': token,
          'platform': Platform.operatingSystem,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Token already exists for the user, handle accordingly (optional)
        print('Token already exists for the user: $token');
      }
  } catch (e) {
    debugPrint(e.toString());
  }
}
