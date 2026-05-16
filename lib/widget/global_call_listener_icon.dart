// Reusable icon-button para el "Global escuchar mi turno". Pensado para
// ir como `actions:` de cualquier AppBar de la app (MyBookingPage,
// AppointmentDetailsPage, etc.). Reusa la misma lógica de colores del
// header de HomePage:
//   blanco70 → off
//   amber    → on, sin canales suscriptos (idle)
//   green    → on, 1+ canales escuchando
//
// Pablo 2026-05-16: el icon original solo aparecía en HomePage
// (`_buildProfileSection`). Necesita estar accesible en cada AppBar.

import 'package:flutter/material.dart';

import '../services/global_call_listener_service.dart';

class GlobalCallListenerIconButton extends StatelessWidget {
  const GlobalCallListenerIconButton({
    super.key,
    this.size = 24,
    this.tooltip = 'Escuchar mi turno',
  });

  final double size;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final svc = GlobalCallListenerService.instance;
    return AnimatedBuilder(
      animation: Listenable.merge([
        svc.enabledNotifier,
        svc.trackedCountNotifier,
      ]),
      builder: (_, __) {
        final enabled = svc.enabledNotifier.value;
        final hasChannels = svc.trackedCountNotifier.value > 0;
        final Color iconColor = !enabled
            ? Colors.white70
            : (hasChannels ? Colors.greenAccent : Colors.amberAccent);
        final IconData iconData = enabled
            ? Icons.notifications_active
            : Icons.notifications_off;
        return IconButton(
          tooltip: tooltip,
          icon: Icon(iconData, color: iconColor, size: size),
          onPressed: () async {
            await svc.setEnabled(!enabled);
          },
        );
      },
    );
  }
}
