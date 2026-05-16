import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../utilities/api_content.dart';
import '../utilities/sharedpreference_constants.dart';

/// Suscribe al canal `appointment-video.{appointmentId}` del backend
/// medicare-node-api y escucha el evento `doctor.joined` (payload: appointment_id,
/// meeting_id, meeting_link, video_provider, doctor_joined_at).
///
/// Migrado desde pusher_channels_flutter el 2026-05-16. El backend ya hacía
/// dual fan-out (Pusher + Socket.IO); ahora la app consume Socket.IO
/// directamente.
class AppointmentSocketService {
  final int appointmentId;
  final void Function(String current, String previous)? onConnectionStateChange;
  final FutureOr<void> Function(Map<String, dynamic> payload)? onEvent;
  final void Function(String message, dynamic code, dynamic exception)? onError;

  io.Socket? _socket;
  String? _channelName;

  AppointmentSocketService({
    required this.appointmentId,
    this.onConnectionStateChange,
    this.onEvent,
    this.onError,
  });

  /// Conecta el socket. `apiKey`/`cluster` quedaron en la firma para no
  /// romper call-sites legacy (eran de Pusher); se ignoran.
  Future<void> connect({
    String? apiKey,
    String? cluster,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(SharedPreferencesConstants.token) ?? '';
    if (token.isEmpty) {
      debugPrint('AppointmentSocket: no JWT in prefs, skipping connect');
      onError?.call('no auth token', null, null);
      return;
    }

    _channelName = 'appointment-video.$appointmentId';

    _socket?.dispose();
    _socket = io.io(
      ApiContents.webApiUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionDelay(1500)
          .setReconnectionDelayMax(8000)
          .build(),
    );

    String prevState = 'DISCONNECTED';
    void notifyState(String current) {
      debugPrint('AppointmentSocket state: $prevState -> $current');
      onConnectionStateChange?.call(current, prevState);
      prevState = current;
    }

    _socket!
      ..onConnect((_) {
        notifyState('CONNECTED');
        _socket!.emit('join', _channelName);
      })
      ..onDisconnect((_) => notifyState('DISCONNECTED'))
      ..onConnectError((err) {
        debugPrint('AppointmentSocket connect_error: $err');
        onError?.call('connect_error', null, err);
      })
      ..on('joined', (data) {
        debugPrint('AppointmentSocket joined: $data');
      })
      ..on('join-error', (data) {
        debugPrint('AppointmentSocket join-error: $data');
        onError?.call('join-error', null, data);
      })
      ..on('doctor.joined', (data) async {
        try {
          debugPrint('AppointmentSocket doctor.joined: $data');
          Map<String, dynamic> payload = <String, dynamic>{};
          if (data is Map) {
            payload = Map<String, dynamic>.from(data);
          }
          if (onEvent != null) {
            await onEvent!(payload);
          }
        } catch (e) {
          debugPrint('AppointmentSocket event parse error: $e');
          onError?.call('event parse error', null, e);
        }
      });

    _socket!.connect();
  }

  Future<void> disconnect() async {
    try {
      if (_socket != null && _channelName != null && _socket!.connected) {
        _socket!.emit('leave', _channelName);
      }
    } catch (_) {}

    try {
      _socket?.dispose();
    } catch (_) {}

    _socket = null;
    _channelName = null;
  }
}
