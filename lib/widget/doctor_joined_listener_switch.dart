// Switch "Anunciar cuando el doctor entre" para AppointmentDetailsPage.
// Conceptualmente espejo de [[patient_call_listener_switch]] pero para el
// evento `doctor.joined` del canal `appointment-video.{id}`. NO hace su
// propia suscripción Socket.IO — la página ya tiene un
// `AppointmentSocketService` activo; este widget solo expone el switch +
// el method `announce()` que la página llama desde su onEvent.
//
// El switch persiste el flag en SharedPreferences (per-appointment).
// Default OFF — el user debe activarlo explícitamente.

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoctorJoinedAnnouncerController {
  final int appointmentId;
  final FlutterTts _tts = FlutterTts();
  bool _ttsConfigured = false;
  bool enabled = false;

  DoctorJoinedAnnouncerController({required this.appointmentId});

  static String _prefKey(int apptId) => 'doctor_joined_audio:$apptId';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool(_prefKey(appointmentId)) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey(appointmentId), value);
  }

  Future<void> _configureTtsOnce() async {
    if (_ttsConfigured) return;
    await _tts.setLanguage('es-ES');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    _ttsConfigured = true;
  }

  /// Anuncia con TTS que el doctor entró. La página llama esto desde su
  /// handler de `doctor.joined`. Si el switch está OFF, es no-op.
  Future<void> announce({String? doctorName}) async {
    if (!enabled) return;
    final name = (doctorName ?? '').trim();
    final text = name.isEmpty
        ? 'El doctor entró a la consulta.'
        : 'El doctor $name entró a la consulta.';
    try {
      await _configureTtsOnce();
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // Silent — TTS fail no debe romper UI.
    }
  }

  /// Habla un texto arbitrario (sin formatear). Usado para mensajes de
  /// confirmación del switch — distintos del anuncio de "doctor entró".
  Future<void> speakRaw(String text) async {
    try {
      await _configureTtsOnce();
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

class DoctorJoinedListenerSwitch extends StatefulWidget {
  const DoctorJoinedListenerSwitch({
    super.key,
    required this.controller,
    this.label = 'Anunciar cuando el doctor entre',
    this.helpText = 'Anuncia por audio cuando el doctor se une a la videollamada.',
  });

  final DoctorJoinedAnnouncerController controller;
  final String label;
  final String helpText;

  @override
  State<DoctorJoinedListenerSwitch> createState() =>
      _DoctorJoinedListenerSwitchState();
}

class _DoctorJoinedListenerSwitchState
    extends State<DoctorJoinedListenerSwitch> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await widget.controller.load();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _onToggle(bool value) async {
    await widget.controller.setEnabled(value);
    if (!mounted) return;
    setState(() {});
    if (value) {
      // Confirmación audible al activar el switch. NO usamos
      // `announce()` porque ese habla "el doctor entró" y daría una
      // falsa señal (Pablo 2026-05-16). Hablamos un mensaje distinto.
      await widget.controller.speakRaw(
        'Anuncio activado. Te avisaré cuando el doctor entre.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 56);
    }
    final enabled = widget.controller.enabled;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: SwitchListTile(
        title: Text(widget.label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(widget.helpText, style: const TextStyle(fontSize: 12)),
        value: enabled,
        onChanged: _onToggle,
        secondary: Icon(
          enabled ? Icons.record_voice_over : Icons.voice_over_off,
          color: enabled ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}
