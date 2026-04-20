import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:udemy_core/udemy_core.dart';

import '../utilities/api_content.dart';
import '../utilities/app_constans.dart';

class MedicarePaymentsProvider {
  static final String _bancardBaseUrl = ApiContents.bancardBaseUrl;

  Future<Map<String, dynamic>?> findCurrentByAppointmentId(
      int appointmentId,
      ) async {
    final uri = Uri.parse(
        '$_bancardBaseUrl/api/v1/bancard/card/appointment/current/$appointmentId'
    );

    debugPrint(
      '[MedicarePaymentsProvider.findCurrentByAppointmentId] route: $uri',
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'x-api-key': AppConstants.apiKey,
      },
    );

    debugPrint(
      '[MedicarePaymentsProvider.findCurrentByAppointmentId] statusCode: ${response.statusCode}',
    );
    debugPrint(
      '[MedicarePaymentsProvider.findCurrentByAppointmentId] body: ${response.body}',
    );

    if (response.statusCode != 200 || response.body.isEmpty) {
      return null;
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      final dynamic data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return decoded;
    }

    if (decoded is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(decoded);
      final dynamic data = map['data'];
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return map;
    }

    return null;
  }

  Future<ResponseApi> confirmAppointmentPayment({
    required int paymentId,
  }) async {
    final uri = Uri.parse(
        '$_bancardBaseUrl/api/v1/bancard/card/appointment/confirm',
    );

    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'x-api-key': AppConstants.apiKey,
      },
      body: jsonEncode({
        'payment_id': paymentId,
      }),
    );

    debugPrint(
      '[MedicarePaymentsProvider.confirmAppointmentPayment] statusCode: ${response.statusCode}',
    );
    debugPrint(
      '[MedicarePaymentsProvider.confirmAppointmentPayment] body: ${response.body}',
    );

    if (response.body.isEmpty) {
      return ResponseApi(
        success: false,
        message: 'Sin respuesta',
        data: null,
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return ResponseApi(
        success: decoded['success'] == true || decoded['status'] == true,
        message: decoded['message']?.toString() ?? '',
        data: decoded,
      );
    }

    if (decoded is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(decoded);
      return ResponseApi(
        success: map['success'] == true || map['status'] == true,
        message: map['message']?.toString() ?? '',
        data: map,
      );
    }

    return ResponseApi(
      success: false,
      message: 'Respuesta inválida',
      data: null,
    );
  }

  Future<ResponseApi> cancelAndRollbackAppointmentPayment({
    required int paymentId,
  }) async {
    final uri = Uri.parse(
        '$_bancardBaseUrl/api/v1/bancard/card/appointment/cancel-and-rollback'
    );

    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'x-api-key': AppConstants.apiKey,
      },
      body: jsonEncode({
        'payment_id': paymentId,
      }),
    );

    debugPrint(
      '[MedicarePaymentsProvider.cancelAndRollbackAppointmentPayment] statusCode: ${response.statusCode}',
    );
    debugPrint(
      '[MedicarePaymentsProvider.cancelAndRollbackAppointmentPayment] body: ${response.body}',
    );

    if (response.body.isEmpty) {
      return ResponseApi(
        success: false,
        message: 'Sin respuesta',
        data: null,
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return ResponseApi(
        success: decoded['success'] == true || decoded['status'] == true,
        message: decoded['message']?.toString() ?? '',
        data: decoded,
      );
    }

    if (decoded is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(decoded);
      return ResponseApi(
        success: map['success'] == true || map['status'] == true,
        message: map['message']?.toString() ?? '',
        data: map,
      );
    }

    return ResponseApi(
      success: false,
      message: 'Respuesta inválida',
      data: null,
    );
  }
}