class ApiContents{
 // static const webApiUr="http://192.168.1.38:8000" for localhost;
  static const webApiUrl = "https://pay.solexpresspy.com";
  static const String pusherApiKey ='4f102f4f63dd5f65ed18' ;
  static const String pusherCluster ='sa1' ;
  //API_BASE_URL
  static const baseApiUrl="$webApiUrl/api/v1";
  static const String bancardBaseUrl = webApiUrl;
  static const imageUrl="$webApiUrl/public/storage";
  static const prescriptionUrl="$baseApiUrl/prescription/generatePDF";
  static const labInvoiceUrl="$baseApiUrl/invoice/generatePDFLab";
  static const invoiceUrl="$baseApiUrl/invoice/generatePDF";
  static const loginWithGoogleUrl="$baseApiUrl/login_google";
  //Doctors
  static const getDoctorsUrl="$baseApiUrl/get_doctor";

  //Review
  static const addDoctorsReviewUrl="$baseApiUrl/add_doctor_review";
  static const getDoctorReviewUrl="$baseApiUrl/get_all_doctor_review";

  //Time Slots
  static const getTimeSlotsUrl="$baseApiUrl/get_doctor_time_interval";
  static const getVideoTimeSlotsUrl="$baseApiUrl/get_doctor_video_time_interval";
  static const getBookedTimeSlotsUrl="$baseApiUrl/get_booked_time_slots";


  //Patients
  static const getPatientsUrl="$baseApiUrl/get_patients";
  static const addPatientsUrl="$baseApiUrl/add_patient";



  //Appointment
  static const addAppUrl="$baseApiUrl/add_appointment";
  static const getAppByUIDUrl="$baseApiUrl/get_appointments";
  static const getAppByIDUrl="$baseApiUrl/get_appointment";


  //Appointment Cancellation
  static const appointmentCancellationUrl="$baseApiUrl/appointment_cancellation";
  static const deleteAppointmentCancellationUrl="$baseApiUrl/delete_appointment_cancellation";
  static const getAppointmentCancellationUrlByAppId="$baseApiUrl/get_appointment_cancel_req/appointment";

  //Invoice
  static const getInvoiceUrl="$baseApiUrl/get_invoice";
  static const getInvoiceByLabAppIdUrl="$baseApiUrl/get_invoice/lab_appointment";


  //Department
  static const getDepartmentUrl="$baseApiUrl/get_department_active";


  //Transaction
  static const getWalletByUidUrl="$baseApiUrl/get_all_transaction";
  static const addWalletMoneyUrl="$baseApiUrl/add_wallet_money";


  //Prescription
  static const getPrescription="$baseApiUrl/get_prescription";


  //Family Member
  static const getFamilyMembersByUIDUrl="$baseApiUrl/get_family_members/user";
  static const addFamilyMemberUrl="$baseApiUrl/add_family_member";
  static const deleteFamilyMemberUrl="$baseApiUrl/delete_family_member";
  static const updateFamilyMemberUrl="$baseApiUrl/update_family_member";

  //Loginscreen
  static const getLoginImageUrl="$baseApiUrl/get_login_screen_images";

  //User
  static const getUserUrl="$baseApiUrl/get_user";
  static const addUserUrl="$baseApiUrl/add_user";
  static const updateUserUrl="$baseApiUrl/update_user";
  static const useSoftDeleteUrl="$baseApiUrl/user_soft_delete";

  //Login
  static const loginPhoneUrl="$baseApiUrl/login_phone";
  static const loginOutUrl="$baseApiUrl/logout";

  //WebPage
  static const getWebApiUrl="$baseApiUrl/get_web_page/page";

  //Testimonial
  static const getTestimonialApiUrl="$baseApiUrl/get_testimonial";

  //configurations
  static const getConfigByIdNameApiUrl="$baseApiUrl/get_configurations/id_name";
  static const getConfigByGroupNameApiUrl="$baseApiUrl/get_configurations/group_name";
  static const getConfigUrl="$baseApiUrl/get_configurations";
  //SocialMedia
  static const getSocialMediaApiUrl="$baseApiUrl/get_social_media";

  //Notification
  static const getNotifyByDateUrl="$baseApiUrl/get_user_notification/date";
  static const getUserNotificationUrl="$baseApiUrl/get_user_notification";

  //Notification Seen
  static const usersNotificationSeenStatusUrl="$baseApiUrl/users_notification_seen_status";

  //Vitals
  static const getVitalsByFamilyID="$baseApiUrl/get_vitals_family_member_id_type";
  static const addVitalsId="$baseApiUrl/add_vitals";
  static const deleteVitalsUrl="$baseApiUrl/delete_vitals";
  static const updateVitalsUrl="$baseApiUrl/update_vitals";

  //Coupon
  static const getValidateUrl="$baseApiUrl/get_validate";
  static const getValidateLabUrl="$baseApiUrl/get_validate_lab";

  //Checkin
  static const getAppointmentCheckInUserUrl="$baseApiUrl/get_appointment_check_in";



  //Payment Getaway
  static const getPaymentGatewayActiveUrl="$baseApiUrl/get_payment_gateway_active";


  //Files
  static const getPatientFileUrl="$baseApiUrl/get_patient_file";

  //Clinic
  static const getClinicUrl="$baseApiUrl/get_clinic_page";
  static const getClinicByIdUrl="$baseApiUrl/get_clinic";


  //City
  static const getCityUrl="$baseApiUrl/get_city";
  static const getLocationUrl="$baseApiUrl/get_current_city";

  //Banner
  static const getBannerUrl="$baseApiUrl/get_banner";


  //Pathology
  static const getPathologistUrl="$baseApiUrl/get_pathologist";
  static const getPathologyTestUrl="$baseApiUrl/get_path_test";

  //cart
  static const labAddToCartUrl="$baseApiUrl/add_lab_cart";
  static const labGetToCartUrl="$baseApiUrl/get_lab_cart";
  static const labDeleteCartUrl="$baseApiUrl/delete_lab_cart";
  static const labDeleteAndAddCartUrl="$baseApiUrl/delete_and_add_lab_test";
  //Blog
  static const blogPostUrl="$baseApiUrl/get_blog_post";

  static const labBookingGetUrl="$baseApiUrl/get_lab_booking";

  //lab Booking
  static const labBooingUrl="$baseApiUrl/add_lab_booking";

  //PreOrder
  static const preOrderUrl="$baseApiUrl/add_pre_order";

  static const addLabReviewUrl="$baseApiUrl/add_lab_review";

  //Lab Cancellation
  static const labBookingCancellationUrl="$baseApiUrl/lab_booking_cancellation";
  static const deleteLabBookingCancellationUrl="$baseApiUrl/delete_lab_booking_cancellation";
  static const getLabBookingCancellationUrl="$baseApiUrl/get_lab_booking_cancel_req";

  //Language
  //static const getLngTransUrl="$baseApiUrl/get_language_translations";
  //static const getLngUrl="$baseApiUrl/get_language";

  //update payment
  static const updatePaymentUrl="$baseApiUrl/update_payment";

  static const initPaymentUrl="$baseApiUrl/payment_initiate";

  static const aiChatUrl="$baseApiUrl/ai_chat";


}

// static const createPayStackOrder="$baseApiUrl/paystack/create-order";
// //Stripe
// static const createStripeIntentUrl="$baseApiUrl/create_intent";
// //Razorpay
// static const createRzOrderUrl="$baseApiUrl/create_rz_order";