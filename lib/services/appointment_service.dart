import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/get_req_helper.dart';
import '../helpers/post_req_helper.dart';
import '../model/appointment_model.dart';
import '../utilities/api_content.dart';
import '../utilities/clinic_config.dart';
import '../utilities/sharedpreference_constants.dart';

class AppointmentService{

   static const  getAppByUIDUrl=   ApiContents.getAppByUIDUrl;
   static const  getAppByIDUrl=   ApiContents.getAppByIDUrl;
  static const  addAppUrl=   ApiContents.addAppUrl;
  static const  addFirstAppUrl=   ApiContents.addFirstAppUrl;

  static List<AppointmentModel> dataFromJson (jsonDecodedData){
    return List<AppointmentModel>.from(jsonDecodedData.map((item)=>AppointmentModel.fromJson(item)));
  }
  static Future addAppointment(
      {
        required String patientId,
        required String status,
        required String date,
        required String timeSlots,
        required String doctId,
        required String clinicId,
        required String deptId,
        required String type,
        required String meetingId,
        required String meetingLink,
        required String paymentStatus,
        required String fee,
        // required String serviceCharge,
        required String totalAmount,
        required String invoiceDescription,
        required String paymentMethod,
        required String paymentTransactionId,
        required String isWalletTxn,
        required String familyMemberId,
        required String couponId,
        required String couponValue,
        required String couponTitle,
        required String couponOffAmount,
        // required String tax,
        // required String unitTaxAmount,
        required String unitTotalAmount, required String durationMinutes,
        required int idPaymentType,
}
      )async{
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"-1";

    // Last-resort fallback: if the caller could not resolve a clinic_id
    // (doctor row from /get_doctor/{id} returns a `clinics[]` array but no
    // top-level clinic_id), try the runtime override saved by ClinicConfig
    // when the user tapped a clinic card. Mirrors what services like
    // appointment listing already do via ClinicConfig.applyTo().
    String resolvedClinicId = clinicId;
    if (resolvedClinicId.trim().isEmpty) {
      final fallback = ClinicConfig.defaultClinicId;
      if (fallback != null) resolvedClinicId = fallback.toString();
    }

    final body = <String, dynamic>{
      "family_member_id": familyMemberId,
      'patient_id': patientId,
      'status': status,
      'date': date,
      // Backend's slot existence check reads $request->time, while the
      // validator accepts either `time` or `time_slots`. Send both — same
      // value — to mirror medicare-user-web and avoid a 422 "slot not
      // available" on the last booking step.
      'time': timeSlots,
      'time_slots': timeSlots,
      "duration_minutes": durationMinutes,
      'doct_id': doctId,
      'clinic_id': resolvedClinicId,
      'dept_id': deptId,
      'type': type,
      'appointment_type': type,
      'meeting_id': meetingId,
      'meeting_link': meetingLink,
      'payment_status': paymentStatus,
      'fee': fee,
      'total_amount': totalAmount,
      'invoice_description': invoiceDescription,
      'payment_method': paymentMethod,
      'user_id': uid,
      'payment_transaction_id': paymentTransactionId,
      "is_wallet_txn": isWalletTxn,
      "coupon_id": couponId,
      "coupon_title": couponTitle,
      "coupon_value": couponValue,
      "coupon_off_amount": couponOffAmount,
      "unit_total_amount": unitTotalAmount,
      "source": Platform.isAndroid ? "Android App" : Platform.isIOS ? "Ios App" : "",
      "id_payment_type": idPaymentType,
      "payment_type_id": idPaymentType,
    };

    // Drop optional fields that are empty/null. Laravel's
    // ConvertEmptyStringsToNull middleware turns "" into null on the
    // server, and some validators on this endpoint reject null values
    // (e.g. patient_id), so it is safer to omit the key entirely. Required
    // fields (clinic_id, doct_id, dept_id, date, type, time*) stay as-is
    // and any missing one becomes a clear 422.
    const optional = {
      'patient_id',
      'meeting_id',
      'meeting_link',
      'payment_transaction_id',
      'coupon_id',
      'coupon_title',
      'coupon_value',
      'family_member_id',
    };
    body.removeWhere((k, v) {
      if (!optional.contains(k)) return false;
      if (v == null) return true;
      if (v is String && v.trim().isEmpty) return true;
      return false;
    });

    // Route to /add_first_appointment when there is no known patient_id —
    // the user might be booking for the first time, so the backend must
    // resolve (or create) a patients row from the user_id before saving.
    // /add_appointment also has this fallback, but routing explicitly keeps
    // the two flows separated and matches the backend contract.
    final url = body.containsKey('patient_id') ? addAppUrl : addFirstAppUrl;
    final res = await PostService.postReq(url, body);
    return res;
  }
  static Future <List<AppointmentModel>?> getData()async {
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"-1";
    final body=<String, dynamic>{
      "user_id":uid
    };
    // Append clinic_id / clinic_ids when configured via dart-define
    // (VITE_CLINIC_ID / VITE_CLINIC_IDS). clinic_ids takes precedence.
    ClinicConfig.applyTo(body);
    final res=await GetService.getReqWithBodY(getAppByUIDUrl,body);
    if(res==null) {
      return null;
    } else {
      List<AppointmentModel> dataModelList = dataFromJson(res);
      return dataModelList;
    }
  }
   static Future <AppointmentModel?> getDataById({required String? appId})async {
     final res=await GetService.getReq("$getAppByIDUrl/${appId??""}");
     if(res==null) {
       return null;
     } else {
       AppointmentModel dataModel = AppointmentModel.fromJson(res);
       return dataModel;
     }
   }
   static Future<dynamic> getVideoJoinData({
     required int appointmentId,
   }) async {
     final res = await PostService.postReq(
       '${ApiContents.baseApiUrl}/appointments/$appointmentId/video/join-data',
       {},
     );
     return res;
   }
}