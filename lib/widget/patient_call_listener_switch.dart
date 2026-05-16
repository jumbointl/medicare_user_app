// Switch "Escuchar mi turno" para la pantalla de detalle de appointment.
//
// Cuando el paciente lo habilita:
//   1. Persiste el flag (per-appointment) en SharedPreferences.
//   2. Subscribe al canal Pusher `clinic.{clinic_id}` y escucha
//      eventos `patient.called` / `patient.recalled` emitidos por
//      `realtime.service.ts` de medicare-node-api cuando el doctor
//      aprieta "Llamar próximo" (o "Llamar este") en la TV.
//   3. Si el payload llega y `appointment_id` matchea, dispara TTS:
//      "Llamando al turno X, doctor Y, sala Z".
//
// Cuando lo deshabilita: unlisten + flag false.
//
// Pre-requisitos backend (ya en prod):
//   - El canal `clinic.{id}` ya está marcado público (ver
//     `channel-ownership.ts`), cualquier auth'd Pusher client puede
//     subscribirse.
//   - `emitPatientCalled` hace fan-out a Pusher + Socket.IO (ver
//     `realtime.service.ts:emitToClinic`).

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/SocketService.dart';

class PatientCallListenerSwitch extends StatefulWidget {
  const PatientCallListenerSwitch({
    super.key,
    required this.appointmentId,
    required this.clinicId,
    this.label = 'Escuchar mi turno',
    this.helpText = 'Anuncia por audio cuando el doctor te llame desde el panel TV.',
  });

  final int appointmentId;
  final int clinicId;
  final String label;
  final String helpText;

  @override
  State<PatientCallListenerSwitch> createState() =>
      _PatientCallListenerSwitchState();
}

class _PatientCallListenerSwitchState extends State<PatientCallListenerSwitch> {
  static String _prefKey(int apptId) => 'patient_call_audio:$apptId';

  bool _enabled = false;
  bool _loading = true;
  final FlutterTts _tts = FlutterTts();
  bool _ttsConfigured = false;
  bool _listening = false;

  String get _channelName => 'clinic.${widget.clinicId}';

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final on = prefs.getBool(_prefKey(widget.appointmentId)) ?? false;
    if (!mounted) return;
    setState(() {
      _enabled = on;
      _loading = false;
    });
    if (on) await _attach();
  }

  Future<void> _configureTtsOnce() async {
    if (_ttsConfigured) return;
    await _tts.setLanguage('es-ES');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    _ttsConfigured = true;
  }

  Future<void> _attach() async {
    if (_listening) return;
    // Subscribe al canal de la clínica y registrar los handlers.
    await SocketService.instance.listen(
      channelName: _channelName,
      eventName: 'patient.called',
      onEvent: _onCallEvent,
    );
    await SocketService.instance.listen(
      channelName: _channelName,
      eventName: 'patient.recalled',
      onEvent: _onCallEvent,
    );
    _listening = true;
  }

  Future<void> _detach() async {
    if (!_listening) return;
    await SocketService.instance.unlisten(
      channelName: _channelName,
      eventName: 'patient.called',
    );
    await SocketService.instance.unlisten(
      channelName: _channelName,
      eventName: 'patient.recalled',
    );
    _listening = false;
  }

  void _onCallEvent(Map<String, dynamic> payload) {
    final apptId = payload['appointment_id'];
    if (apptId == null) return;
    if (int.tryParse(apptId.toString()) != widget.appointmentId) return;
    // Es MI turno — locutar.
    _speak(payload);
  }

  Future<void> _speak(Map<String, dynamic> payload) async {
    await _configureTtsOnce();
    final token = (payload['token'] ?? '').toString().trim();
    final doctor = (payload['doctor_name'] ?? '').toString().trim();
    final sala = (payload['consulting_room'] ?? '').toString().trim();
    final isRecall = (payload['status'] ?? '').toString() == 'recalled';

    final partes = <String>[];
    if (isRecall) {
      partes.add('Repito el llamado.');
    }
    if (token.isNotEmpty) {
      partes.add('Turno ${_spellToken(token)}.');
    }
    if (doctor.isNotEmpty) partes.add('Doctor $doctor.');
    if (sala.isNotEmpty) {
      // Si el nombre del consultorio ya empieza con "sala" o "consultorio"
      // (ej. "Sala 1", "Consultorio A"), no prependemos "Sala" otra vez
      // para evitar "sala sala 1". Pablo 2026-05-16.
      final salaLower = sala.toLowerCase();
      final yaTienePrefijo = salaLower.startsWith('sala') ||
          salaLower.startsWith('consultorio');
      partes.add(yaTienePrefijo ? '$sala.' : 'Sala $sala.');
    }
    final text = partes.join(' ').trim();
    if (text.isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // Silent — TTS fallido NO debe romper el flow.
    }
  }

  /// "047" → "cero cuatro siete" (más claro para audio que "cuarenta y siete").
  String _spellToken(String token) {
    const digitos = {
      '0': 'cero', '1': 'uno', '2': 'dos', '3': 'tres', '4': 'cuatro',
      '5': 'cinco', '6': 'seis', '7': 'siete', '8': 'ocho', '9': 'nueve',
    };
    final out = <String>[];
    for (final ch in token.split('')) {
      out.add(digitos[ch] ?? ch);
    }
    return out.join(' ');
  }

  Future<void> _onToggle(bool value) async {
    setState(() => _enabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey(widget.appointmentId), value);
    if (value) {
      await _attach();
      // Confirmación audible al activar (también es prueba de TTS).
      await _configureTtsOnce();
      try {
        await _tts.stop();
        await _tts.speak('Anuncio activado. Te avisaré cuando te llamen.');
      } catch (_) {}
    } else {
      await _detach();
      try {
        await _tts.stop();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 56);
    }
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: SwitchListTile(
        title: Text(widget.label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(widget.helpText, style: const TextStyle(fontSize: 12)),
        value: _enabled,
        onChanged: _onToggle,
        secondary: Icon(
          _enabled ? Icons.notifications_active : Icons.notifications_off,
          color: _enabled ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}
