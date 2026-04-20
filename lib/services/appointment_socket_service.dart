import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class AppointmentSocketService {
  final int appointmentId;
  final void Function(String current, String previous)? onConnectionStateChange;
  final FutureOr<void> Function(Map<String, dynamic> payload)? onEvent;
  final void Function(String message, dynamic code, dynamic exception)? onError;

  PusherChannelsFlutter? _pusher;
  String? _channelName;

  AppointmentSocketService({
    required this.appointmentId,
    this.onConnectionStateChange,
    this.onEvent,
    this.onError,
  });

  Future<void> connect({
    required String apiKey,
    required String cluster,
  }) async {
    _pusher = PusherChannelsFlutter.getInstance();
    _channelName = 'appointment-video.$appointmentId';

    await _pusher!.init(
      apiKey: apiKey,
      cluster: cluster,
      onConnectionStateChange: (currentState, previousState) {
        debugPrint('Socket state: $previousState -> $currentState');
        onConnectionStateChange?.call(
          currentState.toString(),
          previousState.toString(),
        );
      },
      onError: (message, code, exception) {
        debugPrint('Socket error: $message, code=$code, exception=$exception');
        onError?.call(message, code, exception);
      },
      onSubscriptionSucceeded: (channelName, data) {
        debugPrint('Socket subscribed: $channelName');
      },
      onEvent: (event) async {
        try {
          debugPrint(
            'Socket event: channel=${event.channelName} event=${event.eventName} data=${event.data}',
          );

          if (event.channelName != _channelName) {
            return;
          }

          if (event.eventName != 'doctor.joined') {
            return;
          }

          Map<String, dynamic> payload = <String, dynamic>{};

          final rawData = event.data;

          if (rawData is String && rawData.isNotEmpty) {
            final decoded = jsonDecode(rawData);
            if (decoded is Map<String, dynamic>) {
              payload = decoded;
            }
          } else if (rawData is Map) {
            payload = Map<String, dynamic>.from(rawData);
          }

          if (onEvent != null) {
            await onEvent!(payload);
          }
        } catch (e) {
          debugPrint('Socket event parse error: $e');
          onError?.call('Socket event parse error', null, e);
        }
      },
    );

    await _pusher!.subscribe(channelName: _channelName!);
    await _pusher!.connect();
  }

  Future<void> disconnect() async {
    try {
      if (_pusher != null && _channelName != null) {
        await _pusher!.unsubscribe(channelName: _channelName!);
      }
    } catch (_) {}

    try {
      await _pusher?.disconnect();
    } catch (_) {}

    _channelName = null;
  }
}