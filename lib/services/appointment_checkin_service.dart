import '../helpers/get_req_helper.dart';
import '../helpers/post_req_helper.dart';
import '../model/appointment_check_in_model.dart';
import '../utilities/api_content.dart';

class QrCheckinTicket {
  final int appointmentId;
  final int checkinId;
  final String token; // "001"
  final String date;
  final String time;
  final int clinicId;
  final String doctorName;
  final String patientName;

  const QrCheckinTicket({
    required this.appointmentId,
    required this.checkinId,
    required this.token,
    required this.date,
    required this.time,
    required this.clinicId,
    required this.doctorName,
    required this.patientName,
  });

  factory QrCheckinTicket.fromJson(Map<String, dynamic> j) => QrCheckinTicket(
        appointmentId: (j['appointment_id'] as num).toInt(),
        checkinId: (j['checkin_id'] as num).toInt(),
        token: j['token'] as String,
        date: j['date'] as String,
        time: j['time'] as String,
        clinicId: (j['clinic_id'] as num).toInt(),
        doctorName: j['doctor_name'] as String? ?? '',
        patientName: j['patient_name'] as String? ?? '',
      );
}

class QrCheckinResult {
  final bool ok;
  /// Mensaje del backend — útil para diferenciar:
  /// "Invalid QR token" / "QR token expired" / "QR token already used"
  /// "Appointment payment is pending" / "Appointment does not belong to this user"
  /// "Check-in only available on the appointment day" / "Already checked in"
  /// "Successfully checked in" en happy.
  final String message;
  final QrCheckinTicket? ticket;

  const QrCheckinResult({
    required this.ok,
    required this.message,
    this.ticket,
  });
}

class AppointmentCheckinService {
  static const getAppointmentCheckInUserUrl =
      ApiContents.getAppointmentCheckInUserUrl;
  static const qrAppointmentCheckinUrl = ApiContents.qrAppointmentCheckinUrl;

  static List<AppointmentCheckInModel> dataFromJson(jsonDecodedData) {
    return List<AppointmentCheckInModel>.from(
      jsonDecodedData.map((item) => AppointmentCheckInModel.fromJson(item)),
    );
  }

  static Future<List<AppointmentCheckInModel>?> getData({
    required String doctId,
    required String date,
  }) async {
    final body = {
      "doctor_id": doctId,
      "date": date,
    };

    final res =
        await GetService.getReqWithBodY(getAppointmentCheckInUserUrl, body);
    if (res == null) {
      return null;
    } else {
      List<AppointmentCheckInModel> dataModelList = dataFromJson(res);
      return dataModelList;
    }
  }

  /// POST /v1/qr_appointment_checkin
  /// Body: `{appointment_id, kiosk_token}`. Auth: JWT del paciente.
  /// Response envelope: `{response, status, message, ticket?}`.
  static Future<QrCheckinResult> qrCheckin({
    required int appointmentId,
    required String kioskToken,
  }) async {
    final body = {
      "appointment_id": appointmentId,
      "kiosk_token": kioskToken,
    };
    final res = await PostService.postReq(qrAppointmentCheckinUrl, body);
    if (res == null) {
      return const QrCheckinResult(
        ok: false,
        message: "Sin respuesta del servidor",
      );
    }
    final ok = res['status'] == true;
    final message = (res['message'] as String?) ?? "";
    QrCheckinTicket? ticket;
    final ticketJson = res['ticket'];
    if (ticketJson is Map) {
      try {
        ticket = QrCheckinTicket.fromJson(Map<String, dynamic>.from(ticketJson));
      } catch (_) {/* defensivo */}
    }
    return QrCheckinResult(ok: ok, message: message, ticket: ticket);
  }
}
