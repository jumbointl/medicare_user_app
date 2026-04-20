import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utilities/api_content.dart';
import '../utilities/app_constans.dart';
import '../utilities/sharedpreference_constants.dart';

class BancardAppointmentPaymentProvider {
  Future<Map<String, dynamic>?> startAppointmentPayment({
    required int appointmentId,
    required int userId,
    required int paymentTypeId,
    required double amount,
    String currency = 'PYG',
    String? description,
    String? identification,
    String? additionalData,
    String? promotionCode,
  }) async {
    const String route =
        '${ApiContents.bancardBaseUrl}/api/v1/bancard/card/appointment/start';

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String token =
        prefs.getString(SharedPreferencesConstants.token) ?? '';

    final Map<String, dynamic> body = {
      'appointment_id': appointmentId,
      'id_user': userId,
      'id_payment_type': paymentTypeId,
      'amount': amount,
      'currency': currency,
      'description': description,
      'identification': identification,
      'additional_data': additionalData,
      'promotion_code': promotionCode,
    };

    final response = await http.post(
      Uri.parse(route),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'x-api-key': AppConstants.apiKey, // Set it here
      },
      body: jsonEncode(body),
    );


    if (response.body.isEmpty) {
      return null;
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return null;
  }
}