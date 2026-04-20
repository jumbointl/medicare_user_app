import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../controller/notification_dot_controller.dart';
import '../pages/notification_page.dart';
import 'package:http/http.dart' as http;

class HandleLocalNotification{
  static initializeFlutterNotification() {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid =
    const AndroidInitializationSettings("ic_stat");
    final DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      // onDidReceiveLocalNotification:
      //     (int id, String? title, String? body, String? payload) async {
      // },
      // notificationCategories: darwinNotificationCategories,
    );
    var initSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS:initializationSettingsDarwin );
    flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }
  static onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    final String? payload = notificationResponse.payload;
    if (notificationResponse.payload != null) {
      debugPrint('notification payload: $payload');
    }
    Get.to(()=>const NotificationPage());

  }
  static Future<void> showNotification(String title,String body,String imageUrl) async {
    Future<String> downloadAndSaveFile(String url, String fileName) async {
      final Directory directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/$fileName';
      final http.Response response = await http.get(Uri.parse(url));
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    }
    if (kDebugMode) {
      print("===================show notification==============");
    }
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
    final String bigPicturePath = await downloadAndSaveFile(
        imageUrl, 'bigPicture');
    final BigPictureStyleInformation bigPictureStyleInformation =
    BigPictureStyleInformation(
        FilePathAndroidBitmap(bigPicturePath),
        // largeIcon: FilePathAndroidBitmap(largeIconPath),
        contentTitle: title,
        htmlFormatContentTitle: true,
        summaryText: body,
        htmlFormatSummaryText: true);
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
        'your channel id',
        'your channel name',
        styleInformation: bigPictureStyleInformation,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
         largeIcon: const DrawableResourceAndroidBitmap('notification_icon'),

    );

    final NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, title, body, platformChannelSpecifics,
        payload: 'item x');
    final NotificationDotController notificationDotController=Get.find(tag: "notification_dot");
    notificationDotController.setDotStatus(true);

  }
  static Future<void> showWithOutImageNotification(String title,String body) async {

    if (kDebugMode) {
      print("===================show notification==============");
    }
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
     AndroidNotificationDetails androidPlatformChannelSpecifics =
    const AndroidNotificationDetails(
        "Channel",
        "Channel",
        channelDescription: "Notification",
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      largeIcon:  DrawableResourceAndroidBitmap('notification_icon'),
    );
    // print("===================show notification chanel id $channelId==============");
     NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, title, body, platformChannelSpecifics,
        payload: 'item x');

    final NotificationDotController notificationDotController=Get.find(tag: "notification_dot");
    notificationDotController.setDotStatus(true);

  }


}