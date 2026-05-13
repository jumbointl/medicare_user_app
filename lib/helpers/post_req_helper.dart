import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/route_helper.dart';
import '../controller/notification_dot_controller.dart';
import '../controller/user_controller.dart';
import '../services/user_subscription.dart';
import '../utilities/api_content.dart';
import '../utilities/app_constans.dart';
import '../utilities/sharedpreference_constants.dart';
import '../pages/auth/login_page.dart';
import '../widget/toast_message.dart';
import 'refresh_session.dart';
import 'package:get/get.dart';

class PostService {
  // Llama POST /v1/refresh-dynamic-key con el JWT actual y devuelve el
  // nuevo dynamic_key. Devuelve null si falla (server unreachable, JWT
  // expirado, etc.) — el caller decide qué hacer.
  static Future<String?> _tryRefreshDynamicKey(String token) async {
    try {
      final dio = Dio(
        BaseOptions(
          headers: {
            'x-api-key': AppConstants.apiKey,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'authorization': 'Bearer $token',
          },
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final res = await dio.post(ApiContents.refreshDynamicKeyUrl);
      if (res.statusCode == 200 && res.data is Map) {
        final dynKey = res.data['dynamic_key']?.toString();
        if (dynKey != null && dynKey.isNotEmpty) {
          return dynKey;
        }
      }
    } catch (e) {
      if (kDebugMode) print('refreshDynamicKey error: $e');
    }
    return null;
  }

  static Future<dynamic> postReq(String url, dynamic body, {bool isRetry = false}) async {
    if (kDebugMode) {
      print("======Url==========");
      print(url);
      print("======Send Data==========");
      print(body);
    }

    SharedPreferences preferences = await SharedPreferences.getInstance();
    final token =
        preferences.getString(SharedPreferencesConstants.token) ?? "";
    final dynamicKey =
        preferences.getString(SharedPreferencesConstants.dynamicKey) ?? "";

    try {
      final dio = Dio(
        BaseOptions(
          headers: {
            'x-api-key': AppConstants.apiKey,
            'Content-Type': 'application/json',
            // Without Accept: application/json, Laravel auth middleware
            // serves an HTML redirect to /login on auth failure instead of
            // a 401 JSON, which would then break json.decode() here.
            'Accept': 'application/json',
          },
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

      dio.options.headers["authorization"] = "Bearer $token";
      // Solo cuando lo tenemos: el backend Node lo emite desde 2026-05-08;
      // versiones anteriores no lo guardan y el header se omite (server en
      // soft-rollout deja pasar igual).
      if (dynamicKey.isNotEmpty) {
        dio.options.headers["x-dynamic-key"] = dynamicKey;
      }
      dio.options.validateStatus = (status) => status != null && status < 500;

      final response = await dio.post(url, data: body);

      if (kDebugMode) {
        print("==========URL Response==========");
        print(response);
      }

      if (response.statusCode == 401) {
        // 401 con header X-Auth-Reason: dynamic-key → server rechazó el
        // dynamic_key (caducó, fuera de ventana key1+key2). Aplicar la
        // regla del login_provider:
        //   google   → refresh-dynamic-key + retry una vez (anti-bucle).
        //   password → logOut.
        final reason = response.headers.value('x-auth-reason') ??
            response.headers.value('X-Auth-Reason');
        if (!isRetry && reason == 'dynamic-key' && token.isNotEmpty) {
          final provider = preferences
                  .getString(SharedPreferencesConstants.loginProvider) ??
              '';
          if (provider == 'google') {
            final newKey = await _tryRefreshDynamicKey(token);
            if (newKey != null) {
              await preferences.setString(
                SharedPreferencesConstants.dynamicKey,
                newKey,
              );
              return await postReq(url, body, isRetry: true);
            }
          }
          IToastMsg.showMessage("Session expired. Please log in again.");
          logOut();
          return null;
        }

        // 401 from a login endpoint is a credential rejection (e.g. invalid
        // Google token, email mismatch), not a session expiry. Only force a
        // logout when the user already had an active session and the call
        // was NOT to /login*. Otherwise return the body so the caller can
        // surface the backend's actual error message.
        final isLoginEndpoint = url.contains('/login');
        final isRefreshEndpoint =
            url.contains('/refresh') || url.contains('/refresh-dynamic-key');
        final hadSession = token.isNotEmpty;

        if (!isLoginEndpoint && hadSession) {
          // Refresh-token Fase 2 (Pablo 2026-05-12). Antes de forzar
          // logout intentamos renovar session-JWT con el refresh_token.
          // Si funciona reintentamos la request una sola vez (isRetry
          // anti-bucle). Si no funciona, recién ahí logOut.
          if (!isRetry && !isRefreshEndpoint) {
            final ok = await tryRefreshSession();
            if (ok) {
              return await postReq(url, body, isRetry: true);
            }
          }
          IToastMsg.showMessage("Session expired. Please log in again.");
          logOut();
          return null;
        }

        final jsonData = response.data is Map<String, dynamic>
            ? response.data
            : null;
        return jsonData;
      }

      if (response.statusCode == 200) {
        final jsonData = response.data is Map<String, dynamic>
            ? response.data
            : json.decode(response.toString());

        if (kDebugMode) {
          print("==========Response==========");
          print(jsonData);
        }

        // Legacy APIs
        if (jsonData is Map<String, dynamic> &&
            jsonData['response'] == 201) {
          if (jsonData['message'] == "error") {
            IToastMsg.showMessage("Something went wrong");
          } else {
            IToastMsg.showMessage(jsonData['message']?.toString() ?? "Something went wrong");
          }
          return null;
        }

        // Return any valid JSON map for modern APIs too
        return jsonData;
      }

      IToastMsg.showMessage("Something went wrong");
      return null;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      IToastMsg.showMessage("Something went wrong $e");
      return null;
    }
  }

  static logOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    IToastMsg.showMessage("Logout");
    final NotificationDotController notificationDotController =
    Get.find(tag: "notification_dot");
    final UserController userController0 = Get.find(tag: "user");
    userController0.getData();
    notificationDotController.setDotStatus(false);
    UserSubscribe.deleteToTopi(topicName: "PATIENT_APP");
    Get.offAll(() => LoginPage(
      onSuccessLogin: () => Get.offAllNamed(RouteHelper.getHomePageRoute()),
    ));
  }
}
