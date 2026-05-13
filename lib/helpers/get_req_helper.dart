import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utilities/app_constans.dart';
import '../utilities/sharedpreference_constants.dart';
import 'refresh_session.dart';

class GetService {
  // Lee Bearer JWT + dynamic-key de SharedPreferences y los pone como
  // headers — espejo de lo que ya hace PostService. Sin estos headers
  // medicare-node-api responde 401 y todos los GET caen en silencio.
  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(SharedPreferencesConstants.token) ?? "";
    final dynamicKey =
        prefs.getString(SharedPreferencesConstants.dynamicKey) ?? "";
    final h = <String, String>{
      'x-api-key': AppConstants.apiKey,
      'Accept': 'application/json',
    };
    if (token.isNotEmpty) h['authorization'] = "Bearer $token";
    if (dynamicKey.isNotEmpty) h['x-dynamic-key'] = dynamicKey;
    return h;
  }

  // Refresh-token Fase 2 (Pablo 2026-05-12). Detecta el 401 desde
  // DioException (validateStatus default) o desde response directo, y
  // pide a tryRefreshSession() renovar el JWT. Anti-bucle vía isRetry.
  static bool _is401(Object e) {
    if (e is DioException) {
      return e.response?.statusCode == 401;
    }
    return false;
  }

  static Future getReq(url, {bool isRetry = false}) async {
    final headers = await _authHeaders();
    var dio = Dio(BaseOptions(headers: headers));

    try {
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint("==================URL==============");
          debugPrint(url.toString());
          debugPrint("==================Response==============");
          debugPrint(response.toString());
        }

        final jsonData = json.decode(response.toString());
        if (jsonData['response'] == 200) {
          return jsonData['data'];
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("==================URL==============");
        debugPrint(url.toString());
        debugPrint("==================Response Error==============");
        debugPrint(e.toString());
      }
      if (!isRetry && _is401(e)) {
        final ok = await tryRefreshSession();
        if (ok) return getReq(url, isRetry: true);
      }
      return null;
    }
  }

  static Future getReqWithBodY(url, Map<String, dynamic>? body,
      {bool isRetry = false}) async {
    final headers = await _authHeaders();
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 15),
        headers: headers,
      ),
    );

    try {
      final uri = Uri.parse(url).replace(
        queryParameters: body?.map(
              (key, value) => MapEntry(key, value?.toString() ?? ''),
        ),
      );

      if (kDebugMode) {
        debugPrint("==================FINAL URL==============");
        debugPrint(uri.toString());
        debugPrint("==================QUERY PARAMS==============");
        debugPrint(body.toString());
      }

      final response = await dio.get(
        url,
        queryParameters: body,
      );

      if (kDebugMode) {
        debugPrint("==================Response==============");
        debugPrint(response.toString());
      }

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.toString());
        if (jsonData['response'] == 200) {
          return jsonData['data'];
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("==================FINAL URL==============");
        final uri = Uri.parse(url).replace(
          queryParameters: body?.map(
                (key, value) => MapEntry(key, value?.toString() ?? ''),
          ),
        );
        debugPrint(uri.toString());
        debugPrint("==================Response Error==============");
        debugPrint(e.toString());
      }
      if (!isRetry && _is401(e)) {
        final ok = await tryRefreshSession();
        if (ok) return getReqWithBodY(url, body, isRetry: true);
      }
      return null;
    }
  }
}
