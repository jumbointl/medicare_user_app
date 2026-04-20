import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:udemy_core/udemy_core.dart';

import '../utilities/api_content.dart';
import '../utilities/app_constans.dart';

class BancardLabBookingPaymentProvider {
  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'x-api-key': AppConstants.apiKey,
  };

  Future<Map<String, dynamic>?> startLabBookingPayment({
    required int labBookingId,
    required int userId,
    required int paymentTypeId,
    required double amount,
    String currency = 'PYG',
    String? description,
    String? identification,
    String? additionalData,
    String? promotionCode,
    String source = 'android',
  }) async {
    final String route =
        '${ApiContents.bancardBaseUrl}/api/v1/bancard/card/lab-booking/start';

    final Map<String, dynamic> body = {
      'lab_booking_id': labBookingId,
      'id_user': userId,
      'id_payment_type': paymentTypeId,
      'amount': amount,
      'currency': currency,
      'description': description ?? 'Lab booking #$labBookingId',
      'identification': identification,
      'additional_data': additionalData,
      'promotion_code': promotionCode,
      'source': source,
    };

    final response = await http.post(
      Uri.parse(route),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.body.isEmpty) return null;

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);

    return null;
  }

  Future<Map<String, dynamic>?> findCurrentByLabBookingId({
    required int labBookingId,
  }) async {
    final String route =
        '${ApiContents.bancardBaseUrl}/api/v1/bancard/card/lab-booking/current/$labBookingId';

    final response = await http.get(
      Uri.parse(route),
      headers: _headers,
    );

    if (response.statusCode != 200 || response.body.isEmpty) return null;

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      final dynamic data = decoded['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return decoded;
    }

    if (decoded is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(decoded);
      final dynamic data = map['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return map;
    }

    return null;
  }

  Future<ResponseApi> confirmLabBookingPayment({
    required int paymentId,
  }) async {
    final String route =
        '${ApiContents.bancardBaseUrl}/api/v1/bancard/card/lab-booking/confirm';

    final response = await http.post(
      Uri.parse(route),
      headers: _headers,
      body: jsonEncode({
        'payment_id': paymentId,
      }),
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

  Future<ResponseApi> cancelAndRollbackLabBookingPayment({
    required int paymentId,
  }) async {
    final String route =
        '${ApiContents.bancardBaseUrl}/api/v1/bancard/card/lab-booking/cancel-and-rollback';

    final response = await http.post(
      Uri.parse(route),
      headers: _headers,
      body: jsonEncode({
        'payment_id': paymentId,
      }),
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