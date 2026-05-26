import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'languages/language_controller.dart';
import 'controller/theme_controller.dart';
import 'helpers/get_di.dart' as di;
import 'helpers/route_helper.dart';
import 'languages/translation.dart';
import 'theme/dark_theme.dart';
import 'theme/light_theme.dart';
import 'utilities/app_constans.dart';
import 'utilities/clinic_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await di.init();

  final languageController = Get.find<LanguageController>();
  await languageController.loadSavedLanguage();

  await ClinicConfig.loadFromPrefs();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return GetBuilder<ThemeController>(
      init: Get.find<ThemeController>(),
      builder: (themeController) {
        return Obx(() {
          final languageController = Get.find<LanguageController>();

          return GetMaterialApp(
            locale: languageController.currentLocale,
            fallbackLocale: const Locale('es'),
            translations: Translation(),
            title: AppConstants.appName,
            initialRoute: RouteHelper.getHomePageRoute(),
            debugShowCheckedModeBanner: false,
            theme: themeController.darkTheme ? dark : light,
            getPages: RouteHelper.routes,
            // Android 15 (API 35+) habilita edge-to-edge por default y el
            // contenido se solapa con la barra de gestos del sistema. Wrap
            // global en SafeArea(bottom:true) evita que se corten controles
            // sin tener que tocar cada page. top:false porque la AppBar
            // ya respeta el status bar inset.
            builder: (context, child) => SafeArea(
              top: false,
              bottom: true,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        });
      },
    );
  }
}