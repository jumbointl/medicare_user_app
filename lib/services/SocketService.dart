import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../utilities/api_content.dart';
import '../utilities/sharedpreference_constants.dart';

typedef SocketEventCallback = void Function(Map<String, dynamic> payload);

/// Socket.IO singleton para canales públicos del backend medicare-node-api.
///
/// Canales actualmente usados desde la user-app:
///   - `clinic.{clinicId}` → patient.called / patient.recalled / patient.attended
///     (panel TV — switch "Escuchar mi turno").
///
/// Auth: JWT del paciente leído de SharedPreferences. El socket reusa el mismo
/// token que las llamadas HTTP. Conexión lazy: la primera `listen(...)` dispara
/// el connect; los demás siguen con la misma conexión.
class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  io.Socket? _socket;
  bool _connecting = false;

  final Map<String, SocketEventCallback> _listeners = {};
  final Set<String> _subscribedChannels = {};

  String _key(String channel, String event) => '$channel::$event';

  Future<void> _ensureConnected() async {
    if (_socket != null && _socket!.connected) return;
    if (_connecting) {
      while (_connecting) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return;
    }
    _connecting = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(SharedPreferencesConstants.token) ?? '';
      if (token.isEmpty) {
        debugPrint('SocketService: no JWT token in prefs, skipping connect');
        return;
      }

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

      _socket!
        ..onConnect((_) {
          debugPrint('Socket connected');
          // Re-join channels que estaban suscritos antes (o son los iniciales).
          for (final ch in _subscribedChannels) {
            _socket!.emit('join', ch);
          }
        })
        ..onDisconnect((_) => debugPrint('Socket disconnected'))
        ..onConnectError((err) => debugPrint('Socket connect_error: $err'))
        ..on('joined', (data) => debugPrint('Socket joined: $data'))
        ..on('join-error', (data) {
          debugPrint('Socket join-error: $data');
        })
        ..onAny((event, data) {
          // Dispatch a los listeners registrados. La key se busca como
          // `<channel>::<event>` por TODOS los canales suscritos — el server
          // garantiza que solo emite a salas en las que estamos.
          for (final ch in _subscribedChannels) {
            final cb = _listeners[_key(ch, event)];
            if (cb == null) continue;
            try {
              if (data is Map) {
                cb(Map<String, dynamic>.from(data));
              } else if (data == null) {
                cb(<String, dynamic>{});
              }
            } catch (e) {
              debugPrint('Socket dispatch error ($event): $e');
            }
          }
        });

      final completer = Completer<void>();
      _socket!.onConnect((_) {
        if (!completer.isCompleted) completer.complete();
      });
      _socket!.connect();
      await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('Socket connect timeout');
        },
      );
    } finally {
      _connecting = false;
    }
  }

  Future<void> disconnect() async {
    try {
      _subscribedChannels.clear();
      _listeners.clear();
      _socket?.dispose();
    } catch (e) {
      debugPrint('Socket disconnect error: $e');
    } finally {
      _socket = null;
    }
  }

  Future<void> subscribeToPublicChannel({required String channelName}) async {
    if (_subscribedChannels.contains(channelName)) return;
    _subscribedChannels.add(channelName);
    await _ensureConnected();
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join', channelName);
    }
  }

  Future<void> unsubscribeFromPublicChannel({required String channelName}) async {
    try {
      if (_socket != null && _socket!.connected) {
        _socket!.emit('leave', channelName);
      }
    } catch (e) {
      debugPrint('Socket leave error: $e');
    } finally {
      _subscribedChannels.remove(channelName);
      _listeners.removeWhere((key, _) => key.startsWith('$channelName::'));
    }
  }

  Future<void> listen({
    required String channelName,
    required String eventName,
    required SocketEventCallback onEvent,
  }) async {
    await subscribeToPublicChannel(channelName: channelName);
    _listeners[_key(channelName, eventName)] = onEvent;
  }

  Future<void> unlisten({
    required String channelName,
    required String eventName,
  }) async {
    _listeners.remove(_key(channelName, eventName));
  }
}
