import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:video_conference/video_conference.dart';

import '../utilities/api_content.dart';

class UserVideoJoinDataSource implements VideoJoinDataSource {
  @override
  Future<VideoJoinData> fetchJoinData({
    required int appointmentId,
    required int userId,
  }) async {
    final uri = Uri.parse('${ApiContents.baseApiUrl}/agora/video/join-data');

    final response = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'x-api-key': 'solexpress_2026_api_key_x9LmP2Qa7vK81',
      },
      body: jsonEncode({
        'appointment_id': appointmentId,
        'user_id': userId,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Agora join-data request failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid join-data response format.');
    }

    if (decoded['status'] == false) {
      throw Exception(
        decoded['message']?.toString() ?? 'Join-data request failed.',
      );
    }

    final rawData = decoded['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Join-data payload is missing.');
    }

    final joinData = VideoJoinData(
      provider: (rawData['provider'] ?? 'agora').toString().toLowerCase(),
      meetingLink: rawData['meeting_link']?.toString(),
      meetingId: rawData['meeting_id']?.toString(),
      appId: rawData['appId']?.toString(),
      channelName: rawData['channelName']?.toString() ??
          rawData['channel_name']?.toString(),
      uid: _toInt(rawData['uid']),
      token: rawData['token']?.toString(),
      expiresAt: _toInt(rawData['expires_at']),
      joinClosesAt: _toInt(rawData['join_closes_at']),
    );

    if (!joinData.isAgora) {
      throw Exception(
        'UserVideoJoinDataSource expected agora provider, got: ${joinData.provider}',
      );
    }

    return joinData;
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}