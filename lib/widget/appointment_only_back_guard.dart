import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/notification_dot_controller.dart';
import '../controller/user_controller.dart';
import '../services/user_service.dart';
import '../utilities/clinic_config.dart';
import '../utilities/sharedpreference_constants.dart';
import 'drawer_widget.dart';

/// Wraps a page so the system back button asks the user to logout-and-exit
/// when the page is the bottom of the stack and the app is in
/// appointment-only mode. When there is a previous route, normal back works
/// as usual. When ClinicConfig.showAppointmentOnly is false, the wrapper is
/// transparent.
class AppointmentOnlyBackGuard extends StatelessWidget {
  final Widget child;

  const AppointmentOnlyBackGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!ClinicConfig.showAppointmentOnly) {
      return child;
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
          return;
        }

        final confirm = await _confirmExit(context);
        if (confirm == true) {
          await _logoutAndExit();
        }
      },
      child: child,
    );
  }

  Future<bool?> _confirmExit(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("logout".tr),
        content: const Text("¿Cerrar sesión y salir de la aplicación?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text("logout".tr),
          ),
        ],
      ),
    );
  }

  Future<void> _logoutAndExit() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(SharedPreferencesConstants.token);

    // Only call /logout when there is an active session. Appointment-only
    // mode often runs without login, and hitting /logout without a token
    // returns 500.
    if (token != null && token.isNotEmpty) {
      try {
        await UserService.logOutUser();
      } catch (_) {
        // Ignore network errors — we still want to clear local state and exit.
      }
    }

    await prefs.clear();
    await SystemNavigator.pop();
  }
}

/// Returns the standard side drawer (same one used by HomePage) when the app
/// is in appointment-only mode, or null otherwise. Pages that act as the root
/// of the appointment-only flow (DoctorsDetailsPage, ClinicPage,
/// ClinicListPage) attach this as their `drawer:` so users still have access
/// to profile / bookings / logout from the hamburger menu.
Widget? appointmentOnlyDrawer() {
  if (!ClinicConfig.showAppointmentOnly) {
    return null;
  }
  final userController = Get.find<UserController>(tag: "user");
  final notificationDotController =
      Get.find<NotificationDotController>(tag: "notification_dot");
  return IDrawerWidget().buildDrawerWidget(
    userController,
    notificationDotController,
    false,
  );
}
