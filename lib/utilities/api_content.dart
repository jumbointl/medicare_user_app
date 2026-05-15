// 2026-05-11: user-app pega TODO contra medicare-node-api (Node).
// Los endpoints faltantes (ver medicare-node-api/docs/endpoints-missing-in-node.md)
// devuelven 404 hasta que se porten build — el cliente debe manejar el error en
// cada service en lugar de fallback a Laravel.
//
// Pusher sigue siendo un servicio externo (Pusher.com), no medicare-api.
import 'package:flutter/widgets.dart';

class ApiContents {
  static const webApiUrl = "https://medicare.solexpresspy.com";
  static const baseApiUrl = "$webApiUrl/api/v1";

  static const String pusherApiKey = '4f102f4f63dd5f65ed18';
  static const String pusherCluster = 'sa1';

  // Bancard gateway todavía se hostea junto al backend Node.
  static const String bancardBaseUrl = webApiUrl;
  // Storage de imágenes — usuarios/clínicas/doctores/etc. Sigue siendo
  // assets servidos por el host de la API (Node delega a Laravel storage
  // mientras no exista CDN propio).
  static const imageUrl = "$webApiUrl/storage";

  // Asset placeholder usado cuando un campo de imagen viene null/empty.
  // Declarado en pubspec.yaml. NO removerlo sin actualizar safeImage().
  static const noAvailableAsset = 'assets/icons/no-available.png';

  static bool _isFalsy(String? f) {
    if (f == null) return true;
    final t = f.trim();
    return t.isEmpty || t == 'null' || t == 'undefined';
  }

  /// URL completa hacia el storage backend, o cadena vacía si el campo es
  /// null/empty/literal "null"/"undefined". Usar para call sites que pasan
  /// el resultado a ImageBoxFillWidget (que detecta vacío y muestra placeholder).
  static String imgUrl(String? field) {
    if (_isFalsy(field)) return '';
    return '$imageUrl/${field!.trim()}';
  }

  /// ImageProvider listo para `DecorationImage(image: ...)`,
  /// `CircleAvatar(backgroundImage: ...)` o cualquier consumo de ImageProvider.
  /// Devuelve AssetImage local cuando el campo es null/empty/falsy.
  static ImageProvider safeImage(String? field) {
    if (_isFalsy(field)) return const AssetImage(noAvailableAsset);
    return NetworkImage('$imageUrl/${field!.trim()}');
  }

  // PDF generators (invoice + prescription) — endpoints en Node.
  static const prescriptionUrl = "$baseApiUrl/prescription/generatePDF";
  static const labInvoiceUrl = "$baseApiUrl/invoice/generatePDFLab";
  static const invoiceUrl = "$baseApiUrl/invoice/generatePDF";

  // --- Auth ---
  static const loginPhoneUrl = "$baseApiUrl/login_phone";
  static const reLoginPhoneUrl = "$baseApiUrl/re_login_phone";
  static const loginWithGoogleUrl = "$baseApiUrl/login_google";
  // Login para desarrollo + impersonate opcional por email. Solo accesible
  // cuando AppConfig.isProductionMode == true (gate UI).
  static const loginDevUrl = "$baseApiUrl/login/dev";
  static const loginOutUrl = "$baseApiUrl/logout";
  static const refreshDynamicKeyUrl = "$baseApiUrl/refresh-dynamic-key";
  // Refresh-token Fase 2 (Pablo 2026-05-12). El interceptor 401 llama acá
  // con `refresh_token` cuando el session-JWT (12h) expira.
  static const refreshSessionUrl = "$baseApiUrl/refresh";

  // --- User ---
  static const getUserUrl = "$baseApiUrl/get_user";
  static const addUserUrl = "$baseApiUrl/add_user";
  static const updateUserUrl = "$baseApiUrl/update_user";
  static const useSoftDeleteUrl = "$baseApiUrl/user_soft_delete";

  // --- Doctors ---
  static const getDoctorsUrl = "$baseApiUrl/get_doctor";
  static const getClinicDoctorsUrl = "$baseApiUrl/get_clinic_doctors";
  static const addDoctorsReviewUrl = "$baseApiUrl/add_doctor_review";
  static const getDoctorReviewUrl = "$baseApiUrl/get_all_doctor_review";

  // --- Time Slots ---
  static const getBookedTimeSlotsUrl = "$baseApiUrl/get_booked_time_slots";

  // --- Patients ---
  static const getPatientsUrl = "$baseApiUrl/get_patients";
  static const addPatientsUrl = "$baseApiUrl/add_patient";

  // --- Appointment ---
  static const addAppUrl = "$baseApiUrl/add_appointment";
  static const addFirstAppUrl = "$baseApiUrl/add_first_appointment";
  static const getAppByUIDUrl = "$baseApiUrl/get_appointments";
  static const getAppByIDUrl = "$baseApiUrl/get_appointment";

  // --- Appointment Cancellation ---
  static const appointmentCancellationUrl = "$baseApiUrl/appointment_cancellation";
  static const deleteAppointmentCancellationUrl = "$baseApiUrl/delete_appointment_cancellation";
  static const getAppointmentCancellationUrlByAppId = "$baseApiUrl/get_appointment_cancel_req/appointment";

  // --- Appointment Reschedule ---
  static const userAppointmentRescheduleUrl = "$baseApiUrl/user_appointment_reschedule";
  static const rescheduleRequestAddUrl = "$baseApiUrl/appointment_reschedule_request";
  static const rescheduleRequestDeleteUrl = "$baseApiUrl/delete_appointment_reschedule_request";
  static const getRescheduleRequestsByAppIdUrl = "$baseApiUrl/get_appointment_reschedule_requests";

  // --- Invoice ---
  static const getInvoiceUrl = "$baseApiUrl/get_invoice";
  static const getInvoiceByLabAppIdUrl = "$baseApiUrl/get_invoice/lab_appointment";

  // --- Department ---
  static const getDepartmentUrl = "$baseApiUrl/get_department_active";

  // --- Transaction / Wallet ---
  static const getWalletByUidUrl = "$baseApiUrl/get_all_transaction";
  static const addWalletMoneyUrl = "$baseApiUrl/add_wallet_money";

  // --- Prescription ---
  static const getPrescription = "$baseApiUrl/get_prescription";

  // --- Family Members ---
  static const getFamilyMembersByUIDUrl = "$baseApiUrl/get_family_members/user";
  static const addFamilyMemberUrl = "$baseApiUrl/add_family_member";
  static const deleteFamilyMemberUrl = "$baseApiUrl/delete_family_member";
  static const updateFamilyMemberUrl = "$baseApiUrl/update_family_member";

  // --- Login screen / Web pages / Config / Social ---
  static const getLoginImageUrl = "$baseApiUrl/get_login_screen_images";
  static const getWebApiUrl = "$baseApiUrl/get_web_page/page";
  static const getTestimonialApiUrl = "$baseApiUrl/get_testimonial";
  static const getConfigByIdNameApiUrl = "$baseApiUrl/get_configurations/id_name";
  static const getConfigByGroupNameApiUrl = "$baseApiUrl/get_configurations/group_name";
  static const getConfigUrl = "$baseApiUrl/get_configurations";
  static const getSocialMediaApiUrl = "$baseApiUrl/get_social_media";

  // --- Notification ---
  static const getNotifyByDateUrl = "$baseApiUrl/get_user_notification/date";
  static const getUserNotificationUrl = "$baseApiUrl/get_user_notification";
  static const usersNotificationSeenStatusUrl = "$baseApiUrl/users_notification_seen_status";

  // --- Vitals ---
  static const getVitalsByFamilyID = "$baseApiUrl/get_vitals_family_member_id_type";
  static const addVitalsId = "$baseApiUrl/add_vitals";
  static const deleteVitalsUrl = "$baseApiUrl/delete_vitals";
  static const updateVitalsUrl = "$baseApiUrl/update_vitals";

  // --- Coupon ---
  static const getValidateUrl = "$baseApiUrl/get_validate";
  static const getValidateLabUrl = "$baseApiUrl/get_validate_lab";

  // --- Checkin ---
  static const getAppointmentCheckInUserUrl = "$baseApiUrl/get_appointment_check_in";

  // --- Payment Gateway ---
  static const getPaymentGatewayActiveUrl = "$baseApiUrl/get_payment_gateway_active";

  // --- Files ---
  static const getPatientFileUrl = "$baseApiUrl/get_patient_file";

  // --- Clinic ---
  static const getClinicUrl = "$baseApiUrl/get_clinic_page";
  static const getClinicByIdUrl = "$baseApiUrl/get_clinic";

  // --- City / Location ---
  static const getCityUrl = "$baseApiUrl/get_city";
  static const getLocationUrl = "$baseApiUrl/get_current_city";

  // --- Banner ---
  static const getBannerUrl = "$baseApiUrl/get_banner";

  // --- Pathology ---
  static const getPathologistUrl = "$baseApiUrl/get_pathologist";
  static const getPathologyTestUrl = "$baseApiUrl/get_path_test";

  // --- Lab cart ---
  static const labAddToCartUrl = "$baseApiUrl/add_lab_cart";
  static const labGetToCartUrl = "$baseApiUrl/get_lab_cart";
  static const labDeleteCartUrl = "$baseApiUrl/delete_lab_cart";
  static const labDeleteAndAddCartUrl = "$baseApiUrl/delete_and_add_lab_test";

  // --- Blog ---
  static const blogPostUrl = "$baseApiUrl/get_blog_post";

  // --- Lab Booking ---
  static const labBookingGetUrl = "$baseApiUrl/get_lab_booking";
  static const labBooingUrl = "$baseApiUrl/add_lab_booking";

  // --- PreOrder / Reviews ---
  static const preOrderUrl = "$baseApiUrl/add_pre_order";
  static const addLabReviewUrl = "$baseApiUrl/add_lab_review";

  // --- Lab Cancellation ---
  static const labBookingCancellationUrl = "$baseApiUrl/lab_booking_cancellation";
  static const deleteLabBookingCancellationUrl = "$baseApiUrl/delete_lab_booking_cancellation";
  static const getLabBookingCancellationUrl = "$baseApiUrl/get_lab_booking_cancel_req";

  // --- Payments adicionales ---
  static const updatePaymentUrl = "$baseApiUrl/update_payment";
  static const initPaymentUrl = "$baseApiUrl/payment_initiate";

  // --- AI Chat ---
  static const aiChatUrl = "$baseApiUrl/ai_chat";

  // --- Compatibilidad legacy: services antiguos referenciaban nodeBaseApiUrl ---
  // Mantenemos alias para no romper imports antiguos; ambos apuntan al
  // mismo backend (Node).
  static const nodeWebApiUrl = webApiUrl;
  static const nodeBaseApiUrl = baseApiUrl;
}
