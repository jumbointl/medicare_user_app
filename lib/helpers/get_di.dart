import 'package:get/get.dart';
import 'package:medicare_user_app/controller/lab_cart_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../languages/language_controller.dart';
import '../controller/notification_dot_controller.dart';
import '../controller/theme_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import '../controller/user_controller.dart';
import '../services/handle_firebase_notification.dart';
import '../services/handle_local_notification.dart';

init() async {
  await Firebase.initializeApp();
  await HandleFirebaseNotification.handleNotifications();
  await HandleLocalNotification.initializeFlutterNotification();

  final sharedPreferences = await SharedPreferences.getInstance();

  Get.put(UserController(), tag: "user", permanent: true);
  Get.put(LabCartController(), tag: "lab_cart", permanent: true);
  Get.put(NotificationDotController(), tag: "notification_dot", permanent: true);
  Get.put(LanguageController(), permanent: true);

  Get.lazyPut(() => sharedPreferences);
  Get.lazyPut(() => ThemeController(sharedPreferences: Get.find()));
}