/*
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:video_conference/video_conference.dart';

import '../utilities/api_content.dart';

class AgoraJoinResult {
  final bool success;
  final String message;
  final AgoraJoinData? data;
  final int? secondsRemaining;

  AgoraJoinResult({
    required this.success,
    required this.message,
    this.data,
    this.secondsRemaining,
  });
}

class AgoraVideoService {

  static Future<AgoraJoinResult> getJoinData({
    required int appointmentId,
    required int userId,
  }) async {
    final uri = Uri.parse('${ApiContents.baseApiUrl}/agora/video/join-data');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': 'solexpress_2026_api_key_x9LmP2Qa7vK81',
      },
      body: jsonEncode({
        'appointment_id': appointmentId,
        'user_id': userId,
      }),
    );

    Map<String, dynamic> json = {};
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return AgoraJoinResult(
        success: false,
        message: 'Respuesta inválida del servidor',
      );
    }

    final bool ok = json['status'] == true;
    final String message = json['message']?.toString() ?? 'Error';
    final Map<String, dynamic>? dataMap =
    json['data'] is Map<String, dynamic> ? json['data'] : null;

    return AgoraJoinResult(
      success: ok,
      message: message,
      data: ok && dataMap != null ? AgoraJoinData.fromJson(dataMap) : null,
      secondsRemaining: dataMap?['seconds_remaining'] is int
          ? dataMap!['seconds_remaining'] as int
          : int.tryParse('${dataMap?['seconds_remaining'] ?? ''}'),
    );
  }
}*/
