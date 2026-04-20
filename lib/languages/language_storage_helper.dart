import 'dart:convert';
import 'package:medicare_user_app/utilities/sharedpreference_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/language_model.dart';
import 'package:flutter/material.dart';

class LocaleHelper {
  static Locale parse(String code) {
    if (code.contains('-')) {
      final parts = code.split('-');
      if (parts.length >= 2) {
        return Locale(parts[0], parts[1]);
      }
    }

    if (code.contains('_')) {
      final parts = code.split('_');
      if (parts.length >= 2) {
        return Locale(parts[0], parts[1]);
      }
    }

    return Locale(code);
  }
}

class LanguageStorage {
  static List<LanguageModel> _defaultLanguages() {
    return [
      LanguageModel(
        id: 1,
        title: "English",
        code: "en",
        isDefault: 0,
      ),
      LanguageModel(
        id: 2,
        title: "Español",
        code: "es",
        isDefault: 1,
      ),
      LanguageModel(
        id: 3,
        title: "Português",
        code: "pt",
        isDefault: 0,
      ),
      LanguageModel(
        id: 4,
        title: "中文",
        code: "zh",
        isDefault: 0,
      ),
      LanguageModel(
        id: 5,
        title: "繁體中文",
        code: "zh-TW",
        isDefault: 0,
      ),
    ];
  }

  static Future<void> saveLanguages(List<LanguageModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = list.map((e) => e.toJson()).toList();
    await prefs.setString(
      SharedPreferencesConstants.allLanguages,
      jsonEncode(jsonList),
    );
  }

  static Future<List<LanguageModel>> getLanguages() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(SharedPreferencesConstants.allLanguages);

    if (json == null || json.isEmpty) {
      final defaults = _defaultLanguages();
      await saveLanguages(defaults);
      return defaults;
    }

    try {
      final List data = jsonDecode(json);
      if (data.isEmpty) {
        final defaults = _defaultLanguages();
        await saveLanguages(defaults);
        return defaults;
      }

      return data.map((e) => LanguageModel.fromJson(e)).toList();
    } catch (_) {
      final defaults = _defaultLanguages();
      await saveLanguages(defaults);
      return defaults;
    }
  }

  static const String _languageCodeKey = 'language_code';

  static Future<void> saveLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, code);
  }

  static Future<String> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageCodeKey) ?? 'es';
  }
}