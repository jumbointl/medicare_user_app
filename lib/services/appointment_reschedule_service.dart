import '../helpers/get_req_helper.dart';
import '../helpers/post_req_helper.dart';
import '../model/appointment_reschedule_req_model.dart';
import '../utilities/api_content.dart';

class AppointmentRescheduleService {
  /// Calls the user-facing reschedule endpoint.
  /// Backend decides whether to apply directly (mode=rescheduled) or
  /// create a pending request (mode=reschedule_request).
  static Future userReschedule({
    required String appointmentId,
    required String date,
    required String timeSlots,
    String? notes,
  }) async {
    final body = {
      'id': appointmentId,
      'date': date,
      'time_slots': timeSlots,
      if (notes != null) 'notes': notes,
    };
    return await PostService.postReq(
      ApiContents.userAppointmentRescheduleUrl,
      body,
    );
  }

  /// Explicitly create a reschedule request (used when frontend already
  /// knows the auto path is unavailable, e.g. after a Bancard redirect).
  static Future addRequest({
    required String appointmentId,
    required String requestedDate,
    required String requestedTimeSlots,
    String? notes,
  }) async {
    final body = {
      'appointment_id': appointmentId,
      'requested_date': requestedDate,
      'requested_time_slots': requestedTimeSlots,
      if (notes != null) 'notes': notes,
    };
    return await PostService.postReq(
      ApiContents.rescheduleRequestAddUrl,
      body,
    );
  }

  static Future deleteRequest({required String requestId}) async {
    final body = {'id': requestId};
    return await PostService.postReq(
      ApiContents.rescheduleRequestDeleteUrl,
      body,
    );
  }

  static Future<List<AppointmentRescheduleReqModel>?> getByAppointmentId({
    required String appointmentId,
  }) async {
    final res = await GetService.getReq(
      "${ApiContents.getRescheduleRequestsByAppIdUrl}/$appointmentId",
    );
    if (res == null) return null;
    return List<AppointmentRescheduleReqModel>.from(
      res.map((e) => AppointmentRescheduleReqModel.fromJson(e)),
    );
  }
}
