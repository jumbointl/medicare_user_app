import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_conference/video_conference.dart';

import '../services/patient_video_join_check_service.dart';
import '../video/user_video_join_data_source.dart';

class PatientVideoWaitingController {
  final int appointmentId;
  final DateTime? appointmentAt;
  final PatientVideoJoinCheckService checkService;
  final VideoConferenceService conferenceService;

  Timer? _pollTimer;
  bool _opening = false;

  PatientVideoWaitingController({
    required this.appointmentId,
    required this.appointmentAt,
    required this.checkService,
    required this.conferenceService,
  });

  void start({
    required VoidCallback onStateChanged,
    required Future<void> Function(VideoJoinCheckResult result) onResult,
  }) {
    final now = DateTime.now();

    if (!shouldStartPolling(now: now, appointmentAt: appointmentAt)) {
      final secondsUntilStart = appointmentAt == null
          ? 60
          : appointmentAt!
          .subtract(const Duration(minutes: 5))
          .difference(now)
          .inSeconds;

      final delay = Duration(
        seconds: secondsUntilStart > 0 ? secondsUntilStart : 1,
      );

      Timer(delay, () {
        start(
          onStateChanged: onStateChanged,
          onResult: onResult,
        );
      });

      return;
    }

    _runCheck(onResult: onResult);

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _runCheck(onResult: onResult);
      onStateChanged();
    });
  }

  Future<void> _runCheck({
    required Future<void> Function(VideoJoinCheckResult result) onResult,
  }) async {
    if (_opening) return;

    final result = await checkService.check(appointmentId: appointmentId);

    await onResult(result);
  }

  Future<void> openGoogleMeetIfPossible(VideoJoinCheckResult result) async {
    final link = (result.meetingLink ?? '').trim();
    if (!result.isGoogle || link.isEmpty || _opening) return;

    _opening = true;
    _pollTimer?.cancel();

    final uri = Uri.tryParse(link);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> openAgoraIfPossible({
    required BuildContext context,
    required int userId,
    required VideoJoinCheckResult result,
  }) async {
    if (!result.isAgora || _opening) return;

    _opening = true;
    _pollTimer?.cancel();

    await conferenceService.openForAppointment(
      context: context,
      appointmentId: appointmentId,
      userId: userId,
      isDoctor: false,
      title: 'Video consultation',
    );
  }

  void onDoctorJoinedSocket({
    required VoidCallback onStateChanged,
    required Future<void> Function(VideoJoinCheckResult result) onResult,
  }) {
    _runCheck(onResult: onResult);
    onStateChanged();
  }

  void dispose() {
    _pollTimer?.cancel();
  }
}