// "Global escuchar mi turno" — singleton que mantiene una conexión socket
// activa y SUSCRIBE DINÁMICAMENTE a `clinic.{id}` cada vez que el dueño
// (o algún familiar) hace check-in en una cita.
//
// Flujo (Pablo 2026-05-16):
//   1. User activa el switch global (AppBar icon o Drawer).
//   2. Service.start() → conecta socket → joinea `user.{myUserId}`.
//   3. Bootstrap REST: GET /v1/get_appointment_check_in?user_id=X → seed
//      del set `_trackedAppointments` (todos los appts con check-in HOY).
//   4. Por cada clinic_id único en `_trackedAppointments` → emite `join`
//      a `clinic.{clinic_id}` (set `_subscribedClinics`).
//   5. Listeners socket:
//      - `checkin.done` → agrega appointment, ensure clinic suscrito.
//      - `appointment.finished` → remueve appointment, leave clinic si
//        no quedan otros appts trackeados para esa clinic.
//      - `patient.called` / `patient.recalled` → si event.appointment_id
//        ∈ _trackedAppointments → TTS.
//   6. Timer 60s: check end_at, remueve expirados, auto-stop si vacío.
//
// Battery: solo activo mientras `enabled=true`. Background no soportado
// — al closeApp el OS suspende el isolate y el socket muere. Re-conecta
// en próximo open de la app.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../helpers/get_req_helper.dart';
import '../utilities/api_content.dart';
import '../utilities/sharedpreference_constants.dart';

class _TrackedAppointment {
  final int appointmentId;
  final int clinicId;
  /// UNIX seconds; null cuando viene del bootstrap REST y aún no sabemos
  /// el fin (vamos a usar default = today 23:59).
  final int? endAt;
  const _TrackedAppointment({
    required this.appointmentId,
    required this.clinicId,
    this.endAt,
  });
}

class GlobalCallListenerService {
  GlobalCallListenerService._();
  static final GlobalCallListenerService instance =
      GlobalCallListenerService._();

  static const String _prefKey = 'global_listen_my_turn';

  /// El nombre exacto del prefKey por si quieren reusar fuera del service.
  static String get prefKey => _prefKey;

  io.Socket? _socket;
  Timer? _expiryTimer;
  final FlutterTts _tts = FlutterTts();
  bool _ttsConfigured = false;

  /// Last-known on/off — espejo del SharedPreferences. Se actualiza en
  /// `loadEnabled()` y `setEnabled()`. La UI puede leerlo síncrono.
  bool _enabled = false;
  bool get enabled => _enabled;

  /// Notificación pública para que las pantallas se re-renderizen.
  final ValueNotifier<bool> enabledNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int> trackedCountNotifier = ValueNotifier<int>(0);

  final Map<int, _TrackedAppointment> _tracked = {};
  final Set<int> _subscribedClinics = {};
  int? _myUserId;

  // ============================================================
  // Public API
  // ============================================================

  Future<void> loadEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefKey) ?? false;
    enabledNotifier.value = _enabled;
    if (_enabled) {
      // Auto-start si el user ya lo había prendido en la sesión anterior.
      await start();
    }
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    _enabled = value;
    enabledNotifier.value = value;
    if (value) {
      await start();
    } else {
      await stop();
    }
  }

  Future<void> start() async {
    if (_socket != null && _socket!.connected) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(SharedPreferencesConstants.token) ?? '';
    final myIdStr = prefs.getString(SharedPreferencesConstants.uid) ?? '';
    final myUserId = int.tryParse(myIdStr);
    if (token.isEmpty || myUserId == null || myUserId <= 0) {
      debugPrint('[GlobalCallListener] no auth, skipping start');
      return;
    }
    _myUserId = myUserId;

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
      ..onConnect((_) async {
        debugPrint('[GlobalCallListener] socket connected');
        _socket!.emit('join', 'user.$myUserId');
        // Re-suscribir las clínicas trackeadas (en caso de reconnect).
        for (final clinicId in _subscribedClinics) {
          _socket!.emit('join', 'clinic.$clinicId');
        }
      })
      ..onDisconnect((_) {
        debugPrint('[GlobalCallListener] socket disconnected');
      })
      ..on('checkin.done', (data) {
        _handleCheckinDone(data);
      })
      ..on('appointment.finished', (data) {
        _handleAppointmentFinished(data);
      })
      ..on('patient.called', (data) {
        _handlePatientCallEvent(data, recalled: false);
      })
      ..on('patient.recalled', (data) {
        _handlePatientCallEvent(data, recalled: true);
      });

    _socket!.connect();

    // Bootstrap REST: levantar todos los check-ins de HOY.
    await _bootstrapTrackedFromRest();

    // Timer de auto-stop: cada 60s revisa end_at.
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _pruneExpired();
    });
  }

  Future<void> stop() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _socket?.dispose();
    _socket = null;
    _tracked.clear();
    _subscribedClinics.clear();
    trackedCountNotifier.value = 0;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  // ============================================================
  // Internals
  // ============================================================

  Future<void> _bootstrapTrackedFromRest() async {
    if (_myUserId == null) return;
    try {
      // Endpoint existente: /v1/get_appointment_check_in?user_id=X&date=today.
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final url =
          '${ApiContents.baseApiUrl}/get_appointment_check_in?user_id=$_myUserId&date=$today';
      final res = await GetService.getReq(url);
      if (res is! List) return;
      for (final raw in res) {
        if (raw is! Map) continue;
        final apptId = (raw['appointment_id'] as num?)?.toInt();
        final clinicId = (raw['clinic_id'] as num?)?.toInt();
        if (apptId == null || clinicId == null) continue;
        _tracked[apptId] = _TrackedAppointment(
          appointmentId: apptId,
          clinicId: clinicId,
        );
        _ensureClinicSubscribed(clinicId);
      }
      trackedCountNotifier.value = _tracked.length;
      debugPrint(
        '[GlobalCallListener] bootstrap: ${_tracked.length} tracked appts',
      );
    } catch (e) {
      debugPrint('[GlobalCallListener] bootstrap failed: $e');
    }
  }

  void _ensureClinicSubscribed(int clinicId) {
    if (_subscribedClinics.contains(clinicId)) return;
    _subscribedClinics.add(clinicId);
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join', 'clinic.$clinicId');
    }
  }

  void _maybeLeaveClinic(int clinicId) {
    final stillUsed = _tracked.values.any((t) => t.clinicId == clinicId);
    if (stillUsed) return;
    _subscribedClinics.remove(clinicId);
    try {
      _socket?.emit('leave', 'clinic.$clinicId');
    } catch (_) {}
  }

  void _handleCheckinDone(dynamic data) {
    if (data is! Map) return;
    final apptId = (data['appointment_id'] as num?)?.toInt();
    final clinicId = (data['clinic_id'] as num?)?.toInt();
    final endAt = (data['end_at'] as num?)?.toInt();
    if (apptId == null || clinicId == null) return;
    _tracked[apptId] = _TrackedAppointment(
      appointmentId: apptId,
      clinicId: clinicId,
      endAt: endAt,
    );
    _ensureClinicSubscribed(clinicId);
    trackedCountNotifier.value = _tracked.length;
    debugPrint(
      '[GlobalCallListener] checkin.done: $apptId @ clinic.$clinicId (end=$endAt)',
    );
  }

  void _handleAppointmentFinished(dynamic data) {
    if (data is! Map) return;
    final apptId = (data['appointment_id'] as num?)?.toInt();
    if (apptId == null) return;
    final removed = _tracked.remove(apptId);
    if (removed != null) {
      _maybeLeaveClinic(removed.clinicId);
    }
    trackedCountNotifier.value = _tracked.length;
    debugPrint('[GlobalCallListener] appointment.finished: $apptId');
    if (_tracked.isEmpty) {
      debugPrint('[GlobalCallListener] no more tracked appts — pausing TTS');
    }
  }

  void _handlePatientCallEvent(dynamic data, {required bool recalled}) {
    if (data is! Map) return;
    final apptId = (data['appointment_id'] as num?)?.toInt();
    if (apptId == null) return;
    // Filtro: solo TTS si es una cita de nuestra familia con check-in.
    if (!_tracked.containsKey(apptId)) return;
    _speak(data, recalled: recalled);
  }

  Future<void> _configureTtsOnce() async {
    if (_ttsConfigured) return;
    await _tts.setLanguage('es-ES');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    _ttsConfigured = true;
  }

  Future<void> _speak(Map data, {required bool recalled}) async {
    final token = (data['token'] ?? '').toString().trim();
    final doctor = (data['doctor_name'] ?? '').toString().trim();
    final sala = (data['consulting_room'] ?? '').toString().trim();

    final partes = <String>[];
    if (recalled) partes.add('Repito el llamado.');
    if (token.isNotEmpty) partes.add('Turno ${_spellToken(token)}.');
    if (doctor.isNotEmpty) partes.add('Doctor $doctor.');
    if (sala.isNotEmpty) {
      final lower = sala.toLowerCase();
      final yaTienePrefijo =
          lower.startsWith('sala') || lower.startsWith('consultorio');
      partes.add(yaTienePrefijo ? '$sala.' : 'Sala $sala.');
    }
    final text = partes.join(' ').trim();
    if (text.isEmpty) return;
    try {
      await _configureTtsOnce();
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  String _spellToken(String token) {
    const digitos = {
      '0': 'cero', '1': 'uno', '2': 'dos', '3': 'tres', '4': 'cuatro',
      '5': 'cinco', '6': 'seis', '7': 'siete', '8': 'ocho', '9': 'nueve',
    };
    return token.split('').map((ch) => digitos[ch] ?? ch).join(' ');
  }

  void _pruneExpired() {
    final nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final toRemove = <int>[];
    for (final t in _tracked.values) {
      if (t.endAt != null && nowSecs > t.endAt!) {
        toRemove.add(t.appointmentId);
      }
    }
    for (final id in toRemove) {
      final removed = _tracked.remove(id);
      if (removed != null) _maybeLeaveClinic(removed.clinicId);
    }
    if (toRemove.isNotEmpty) {
      trackedCountNotifier.value = _tracked.length;
      debugPrint(
        '[GlobalCallListener] pruned ${toRemove.length} expired appts',
      );
    }
    // Auto-stop si quedó vacío y el último prune borró algo.
    if (_tracked.isEmpty && toRemove.isNotEmpty) {
      debugPrint('[GlobalCallListener] idle (no more tracked appts)');
    }
  }
}
