import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../pages/notification_page.dart';
import 'handle_local_notification.dart';

class HandleFirebaseNotification {
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    if (kDebugMode) {
      print('Handling a background message ${message.messageId}');
    }
  }

  static handleNotifications() async {

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        badge: true,
        alert: true,
        sound: true); //presentation options for Apple notifications when received in the foreground.

    FirebaseMessaging.onMessage.listen((message) async {

      if (kDebugMode) {
        print('Got a message whilst in the FOREGROUND!');
      }

      return;
    }).onData((data) async{

      if(data.data["imageUrl"]==""||data.data["imageUrl"]==null){
        HandleLocalNotification.showWithOutImageNotification(
            data.data["title"]??"", data.data["body"]??"");

      }else {
        HandleLocalNotification.showNotification(
            data.data["title"]??"", data.data["body"]??"",
            data.data["imageUrl"]);
      }

      if (kDebugMode) {
        print('Got a DATA message whilst in the FOREGROUND!');
        print('data from  onMessage stream: ${data.data}');
      }


    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      if (kDebugMode) {
        print('NOTIFICATION MESSAGE TAPPEDx');
      }
      return;
    }).onData((data) async{
      if (kDebugMode) {
        print('NOTIFICATION MESSAGE TAPPEDy');
        print('data from onMessageOpenedApp stream: ${data.data}');
        Get.to(()=>const NotificationPage());

      }

      Get.to(()=>const NotificationPage());
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.instance.getInitialMessage().then(

        (value) => value != null ? _firebaseMessagingBackgroundHandler : false);
    return;
  }


}
