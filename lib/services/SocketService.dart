import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

typedef SocketEventCallback = void Function(Map<String, dynamic> payload);

class SocketService {
  SocketService._();
  static final SocketService instance = SocketService._();

  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();

  bool _initialized = false;
  bool _connected = false;

  final Map<String, SocketEventCallback> _listeners = {};
  final Set<String> _subscribedChannels = {};

  String _key(String channel, String event) => '$channel::$event';

  Future<void> connect({
    required String apiKey,
    required String cluster,
    bool useTLS = true,
    void Function(String message)? onError,
  }) async {
    if (_initialized) {
      if (!_connected) {
        await _pusher.connect();
      }
      return;
    }

    await _pusher.init(
      apiKey: apiKey,
      cluster: cluster,
      useTLS: useTLS,
      onConnectionStateChange: (currentState, previousState) {
        debugPrint('Socket state: $previousState -> $currentState');
        _connected = currentState.toUpperCase() == 'CONNECTED';
      },
      onError: (message, code, exception) {
        debugPrint('Socket error: $message, code=$code, exception=$exception');
        if (onError != null) {
          onError(message);
        }
      },
      onSubscriptionSucceeded: (channelName, data) {
        debugPrint('Socket subscribed: $channelName');
      },
      onEvent: (event) {
        final channelName = event.channelName;
        final eventName = event.eventName;

        if (channelName == null || eventName == null) {
          return;
        }

        final callback = _listeners[_key(channelName, eventName)];
        if (callback == null) {
          return;
        }

        try {
          final rawData = event.data;

          if (rawData == null) {
            callback({});
            return;
          }

          if (rawData is Map<String, dynamic>) {
            callback(rawData);
            return;
          }

          if (rawData is String) {
            final decoded = jsonDecode(rawData);
            if (decoded is Map<String, dynamic>) {
              callback(decoded);
              return;
            }
          }

          callback({});
        } catch (e) {
          debugPrint('Socket parse event error: $e');
          callback({});
        }
      },
    );

    _initialized = true;
    await _pusher.connect();
  }

  Future<void> disconnect() async {
    try {
      for (final channel in _subscribedChannels) {
        await _pusher.unsubscribe(channelName: channel);
      }
      _subscribedChannels.clear();
      _listeners.clear();

      if (_initialized) {
        await _pusher.disconnect();
      }
    } catch (e) {
      debugPrint('Socket disconnect error: $e');
    } finally {
      _connected = false;
      _initialized = false;
    }
  }

  Future<void> subscribeToPublicChannel({
    required String channelName,
  }) async {
    if (_subscribedChannels.contains(channelName)) {
      return;
    }

    await _pusher.subscribe(channelName: channelName);
    _subscribedChannels.add(channelName);
  }

  Future<void> unsubscribeFromPublicChannel({
    required String channelName,
  }) async {
    try {
      await _pusher.unsubscribe(channelName: channelName);
    } catch (e) {
      debugPrint('Socket unsubscribe error: $e');
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