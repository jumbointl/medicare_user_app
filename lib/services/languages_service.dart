import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class LanguagesService {
  static Future<Map<String, String>> loadLocalTranslations({
    String code = 'es',
    String scope = 'user_app',
  }) async {
    final String raw =
    await rootBundle.loadString('assets/lang/$scope/$code.json');

    final decoded = jsonDecode(raw) as Map<String, dynamic>;

    return decoded.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }
}