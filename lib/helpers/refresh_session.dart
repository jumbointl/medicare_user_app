import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utilities/api_content.dart';
import '../utilities/app_constans.dart';
import '../utilities/sharedpreference_constants.dart';

// Refresh-token Fase 2 (Pablo 2026-05-12). Llamado desde GetService /
// PostService cuando un endpoint autenticado responde 401 y el motivo NO
// es dynamic-key. Si el `refresh_token` persistido sigue vigente, el
// backend Node emite un nuevo session-JWT (12h) + nuevo refresh_token
// (rota single-active) + opcional dynamic_key. Persistimos todo y el
// caller reintenta la request original una sola vez.
//
// Single-flight: si dos requests caen 401 simultáneamente, solo se hace
// un POST /v1/refresh; el segundo espera el mismo Future. Sin esto la
// rotación single-active del backend invalidaría el refresh_token entre
// la primera y la segunda llamada.

Completer<bool>? _inFlight;

Future<bool> tryRefreshSession() async {
  if (_inFlight != null) return _inFlight!.future;
  final completer = Completer<bool>();
  _inFlight = completer;

  try {
    final ok = await _doRefresh();
    completer.complete(ok);
    return ok;
  } catch (e) {
    if (kDebugMode) print('tryRefreshSession error: $e');
    completer.complete(false);
    return false;
  } finally {
    _inFlight = null;
  }
}

Future<bool> _doRefresh() async {
  final prefs = await SharedPreferences.getInstance();
  final refreshToken =
      prefs.getString(SharedPreferencesConstants.refreshToken) ?? '';
  if (refreshToken.isEmpty) return false;

  final dio = Dio(
    BaseOptions(
      headers: {
        'x-api-key': AppConstants.apiKey,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  final res = await dio.post(
    ApiContents.refreshSessionUrl,
    data: {'refresh_token': refreshToken},
  );

  if (res.statusCode != 200 || res.data is! Map) return false;
  final body = res.data as Map;

  final newToken = body['token']?.toString() ?? '';
  if (newToken.isEmpty) return false;

  await prefs.setString(SharedPreferencesConstants.token, newToken);

  final newRefresh = body['refresh_token']?.toString();
  if (newRefresh != null && newRefresh.isNotEmpty) {
    await prefs.setString(SharedPreferencesConstants.refreshToken, newRefresh);
    await prefs.setString(
      SharedPreferencesConstants.refreshTokenCreatedAt,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  await prefs.setString(
    SharedPreferencesConstants.sessionTokenCreatedAt,
    DateTime.now().toUtc().toIso8601String(),
  );

  final newDynKey = body['dynamic_key']?.toString();
  if (newDynKey != null && newDynKey.isNotEmpty) {
    await prefs.setString(SharedPreferencesConstants.dynamicKey, newDynKey);
  }

  return true;
}
