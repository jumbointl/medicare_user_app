import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:video_conference/video_conference.dart';

import '../utilities/api_content.dart';

class PatientVideoJoinCheckService {
  Future<VideoJoinCheckResult> check({
    required int appointmentId,
  }) async {
    final uri = Uri.parse(
      '${ApiContents.baseApiUrl}/appointments/$appointmentId/video/join-data',
    );

    final response = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'x-api-key': 'solexpress_2026_api_key_x9LmP2Qa7vK81',
      },
      body: jsonEncode({}),
    );

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid join-data response format.');
    }

    final rawData = decoded['data'] is Map<String, dynamic>
        ? decoded['data'] as Map<String, dynamic>
        : null;

    return VideoJoinCheckResult(
      status: decoded['status'] == true,
      waitingForDoctor: decoded['waiting_for_doctor'] == true,
      doctorJoined: decoded['doctor_joined'] == true,
      provider: rawData?['provider']?.toString(),
      meetingLink: rawData?['meeting_link']?.toString(),
      meetingId: rawData?['meeting_id']?.toString(),
      message: decoded['message']?.toString(),
      rawData: rawData,
    );
  }
}

DateTime? parseAppointmentDateTime({
    required String? date,
    required String? time,
  }) {
    final d = (date ?? '').trim();
    final t = (time ?? '').trim();

    if (d.isEmpty || t.isEmpty) return null;

    final normalizedTime = t.length == 5 ? '$t:00' : t;

    return DateTime.tryParse('$d $normalizedTime');
  }

  bool shouldStartPolling({
    required DateTime now,
    required DateTime? appointmentAt,
  }) {
    if (appointmentAt == null) return false;
    final opensAt = appointmentAt.subtract(const Duration(minutes: 5));
    return !now.isBefore(opensAt);
}