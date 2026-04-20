import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../utilities/app_constans.dart';

class GetService {
  static Future getReq(url) async {
    var dio = Dio(
      BaseOptions(
        headers: {
          'x-api-key': AppConstants.apiKey,
          'Accept': 'application/json',
        },
      ),
    );

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
      return null;
    }
  }

  static Future getReqWithBodY(url, Map<String, dynamic>? body) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'x-api-key': AppConstants.apiKey,
          'Accept': 'application/json',
        },
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
      return null;
    }
  }
}