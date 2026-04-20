import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class UserSubscribe{
  static toTopi({required String? topicName})async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(
          topicName ??
              ""); //scribe user to this all group so we can send message to multiple device
      if (kDebugMode) {
        print("===========user subscribe to $topicName=========");
      }
    }
    catch (e) {
      if (kDebugMode) {
        print("Error on subscribe topic");
        print(e);
      }
    }
  }

  static deleteToTopi({required String? topicName})async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(
          topicName ??
              ""); //scribe user to this all group so we can send message to multiple device
      if (kDebugMode) {
        print("===========user unsubscribe to $topicName=========");
      }
    }
    catch (e) {
      if (kDebugMode) {
        print("Error on subscribe topic");
        print(e);
      }
    }
  }
  }