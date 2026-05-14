import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'language_storage_helper.dart';

class LanguageController extends GetxController {
  final RxString currentCode = 'es'.obs;
  final RxBool isChangingLanguage = false.obs;

  Locale get currentLocale => LocaleHelper.parse(currentCode.value);

  Future<void> loadSavedLanguage() async {
    String code = await LanguageStorage.getLanguageCode();

    if (code.isEmpty) {
      code = 'es';
      await LanguageStorage.saveLanguageCode(code);
    }

    currentCode.value = code;
    Get.updateLocale(LocaleHelper.parse(code));
  }

  Future<void> changeLanguage(String code) async {
    if (isChangingLanguage.value) return;
    if (currentCode.value == code) return;

    isChangingLanguage.value = true;

    try {
      await LanguageStorage.saveLanguageCode(code);
      currentCode.value = code;
      Get.updateLocale(LocaleHelper.parse(code));
    } catch (e) {
      debugPrint('changeLanguage error: $e');
    } finally {
      isChangingLanguage.value = false;
    }
  }
}