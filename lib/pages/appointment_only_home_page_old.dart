import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../helpers/get_req_helper.dart';
import '../helpers/route_helper.dart';
import '../utilities/api_content.dart';
import '../utilities/clinic_config.dart';
import 'home_page.dart';

/// Initial-route wrapper that implements the "appointment-only" UX:
///   - 1 clinic + 1 doctor  -> DoctorsDetailsPage
///   - 1 clinic + N doctors -> ClinicPage
///   - >1 clinic            -> ClinicListPage
/// When ClinicConfig.showAppointmentOnly is false, falls back to HomePage so
/// the existing home (hero, blog, etc.) keeps working unchanged.
class AppointmentOnlyHomePage extends StatefulWidget {
  const AppointmentOnlyHomePage({super.key});

  @override
  State<AppointmentOnlyHomePage> createState() =>
      _AppointmentOnlyHomePageState();
}

class _AppointmentOnlyHomePageState extends State<AppointmentOnlyHomePage> {
  @override
  void initState() {
    super.initState();
    if (ClinicConfig.showAppointmentOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _decideRoute();
      });
    }
  }

  int? _resolveSingleClinicId() {
    if (ClinicConfig.defaultClinicId != null) {
      return ClinicConfig.defaultClinicId;
    }
    if (ClinicConfig.allowedClinicIds.length == 1) {
      return ClinicConfig.allowedClinicIds.first;
    }
    return null;
  }

  Future<List?> _fetchClinicDoctors(int clinicId) async {
    final url =
        '${ApiContents.getClinicDoctorsUrl}?clinic_id=$clinicId';
    final res = await GetService.getReq(url);
    if (res == null) return null;
    if (res is List) return res;
    if (res is Map && res['data'] is List) return res['data'] as List;
    return null;
  }

  Future<void> _decideRoute() async {
    final clinicId = _resolveSingleClinicId();

    if (clinicId == null) {
      Get.offAllNamed(RouteHelper.getClinicListPageRoute());
      return;
    }

    final doctors = await _fetchClinicDoctors(clinicId);

    if (!mounted) return;

    if (doctors == null || doctors.isEmpty) {
      Get.offAllNamed(
        RouteHelper.getClinicPageRoute(clinicId: clinicId.toString()),
      );
      return;
    }

    if (doctors.length == 1) {
      final first = doctors.first;
      final doctorIdRaw = first is Map ? first['doctor_id'] : null;
      final doctorId = doctorIdRaw?.toString() ?? '';

      if (doctorId.isNotEmpty && doctorId != 'null') {
        // Replace the wrapper with ClinicPage as the back-destination, then
        // push DoctorsDetailsPage on top. Stack becomes:
        //   [ClinicPage(clinicId), DoctorsDetailsPage(doctorId)]
        // so back from the doctor goes to its clinic; back from there exits.
        Get.offAllNamed(
          RouteHelper.getClinicPageRoute(clinicId: clinicId.toString()),
        );
        Get.toNamed(
          RouteHelper.getDoctorsDetailsPageRoute(doctId: doctorId),
        );
        return;
      }
    }

    Get.offAllNamed(
      RouteHelper.getClinicPageRoute(clinicId: clinicId.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ClinicConfig.showAppointmentOnly) {
      return const HomePage();
    }

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
