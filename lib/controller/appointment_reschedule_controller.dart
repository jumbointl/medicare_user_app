import 'package:get/get.dart';
import '../model/appointment_reschedule_req_model.dart';
import '../services/appointment_reschedule_service.dart';

class AppointmentRescheduleResult {
  final bool success;
  final String mode; // 'rescheduled' | 'reschedule_request' | 'error'
  final String? message;
  final int? rescheduleRequestId;

  AppointmentRescheduleResult({
    required this.success,
    required this.mode,
    this.message,
    this.rescheduleRequestId,
  });
}

class AppointmentRescheduleController extends GetxController {
  var isSubmitting = false.obs;
  var requestList = <AppointmentRescheduleReqModel>[].obs;
  var isLoading = false.obs;

  Future<AppointmentRescheduleResult> submitReschedule({
    required String appointmentId,
    required String date,
    required String timeSlots,
    String? notes,
  }) async {
    isSubmitting(true);
    try {
      final res = await AppointmentRescheduleService.userReschedule(
        appointmentId: appointmentId,
        date: date,
        timeSlots: timeSlots,
        notes: notes,
      );
      if (res == null) {
        return AppointmentRescheduleResult(
          success: false,
          mode: 'error',
          message: 'No response',
        );
      }
      final mode = res['mode']?.toString() ?? 'error';
      final success = res['success'] == true;
      return AppointmentRescheduleResult(
        success: success,
        mode: mode,
        message: res['message']?.toString() ?? res['reason']?.toString(),
        rescheduleRequestId: res['reschedule_request_id'] is int
            ? res['reschedule_request_id']
            : (res['reschedule_request_id'] != null
                ? int.tryParse(res['reschedule_request_id'].toString())
                : null),
      );
    } catch (e) {
      return AppointmentRescheduleResult(
        success: false,
        mode: 'error',
        message: e.toString(),
      );
    } finally {
      isSubmitting(false);
    }
  }

  Future<bool> deleteRequest({required String requestId}) async {
    try {
      final res = await AppointmentRescheduleService.deleteRequest(
        requestId: requestId,
      );
      return res != null && res['response'] == 200;
    } catch (_) {
      return false;
    }
  }

  void getRequestsByAppointmentId({required String appointmentId}) async {
    isLoading(true);
    try {
      final list = await AppointmentRescheduleService.getByAppointmentId(
        appointmentId: appointmentId,
      );
      requestList.value = list ?? [];
    } catch (_) {
      requestList.value = [];
    } finally {
      isLoading(false);
    }
  }
}
