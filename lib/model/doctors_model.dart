class DoctorsModel{
  int? id;
  int? userId;
  String? fName;
  String? lName;
  int? exYear;
  String? specialization;
  String? image;
  String? desc;
  int? clinicAppointment;
  int? videoAppointment;
  int? emergencyAppointment;
  double? averageRating;
  int? numberOfReview;
  int? totalAppointmentDone;
  double? opdFee;
  double? videoFee;
  double? emgFee;
  // Per-clinic fees from user_clinics (exposed by view_clinic_doctors as
  // user_clinic_opd_fee / user_clinic_video_c_fee / user_clinic_emergency_fee).
  // Prefer these over the per-doctor opdFee/videoFee/emgFee when present —
  // a doctor can charge differently at each clinic.
  double? userClinicOpdFee;
  double? userClinicVideoFee;
  double? userClinicEmgFee;
  int? stopBooking;
  int? deptId;
  String? fbLink;
  String? instaLink;
  String? youtubeLink;
  String? twitterLink;
  String? deptName;
  String? clinicTitle;
  String? clinicAddress;
  List? clinicImage;
  int? clinicId;
  String? clinicThumbImage;
  int? clinicStopBooking;
  int? clinicCouponEnable;
  double? clinicTax;
  int? autoRescheduledAllowed;
  int? videoAutoRescheduledAllowed;
  int? autoRescheduledAllowedBeforeMinutes;
  int? videoAutoRescheduledAllowedBeforeMinutes;
  String? gender;

  DoctorsModel({
    this.id,
    this.fName,
    this.exYear,
    this.lName,
    this.specialization,
    this.image,
    this.desc,
    this.gender,
    this.clinicAppointment,
    this.emergencyAppointment,
    this.videoAppointment,
    this.averageRating,
    this.numberOfReview,
    this.totalAppointmentDone,
    this.emgFee,
    this.opdFee,
    this.videoFee,
    this.userClinicOpdFee,
    this.userClinicVideoFee,
    this.userClinicEmgFee,
    this.stopBooking,
    this.deptId,
    this.fbLink,
    this.instaLink,
    this.twitterLink,
    this.youtubeLink,
    this.deptName,
    this.clinicAddress,
    this.clinicTitle,
    this.clinicImage,
    this.clinicId,
    this.clinicThumbImage,
    this.clinicStopBooking,
    this.clinicCouponEnable,
    this.clinicTax,
    this.userId,
    this.autoRescheduledAllowed,
    this.videoAutoRescheduledAllowed,
    this.autoRescheduledAllowedBeforeMinutes,
    this.videoAutoRescheduledAllowedBeforeMinutes,
  });

  factory DoctorsModel.fromJson(Map<String,dynamic> json){
    // view_clinic_doctors prefixes most doctor columns with `doctor_` and
    // splits the user_clinic active/stop_booking out from the doctor's own
    // active/stop_booking. /get_doctor/{id} (v_doctors) keeps the unprefixed
    // names. Accept either — same model serves both endpoints.
    return DoctorsModel(
      fName: json['f_name'],
      id: json['id'] ?? json['doctor_id'],
      userId: json['user_id'] ?? json['doctor_user_id'],
      gender: (json['gender'] ?? json['doctor_gender'])?.toString(),
      exYear: _readInt(json['ex_year'] ?? json['doctor_ex_year']),
      lName: json['l_name'],
      specialization: json['specialization'] ?? json['doctor_specialization'],
      image: json['image'] ?? json['doctor_image'],
      desc: json['description'] ?? json['doctor_description'],
      clinicAppointment: json['clinic_appointment'],
      emergencyAppointment: json['emergency_appointment'],
      videoAppointment: json['video_appointment'],
      averageRating: json['average_rating'] != null
          ? double.tryParse(json['average_rating'].toString())
          : null,
      numberOfReview: _readInt(json['number_of_reviews']),
      totalAppointmentDone: _readInt(json['total_appointment_done']),
      // Per-doctor fees (doctors table). view_clinic_doctors also aliases
      // video_fee as video_c_fee and emg_fee as emergency_fee.
      emgFee: _readDouble(json['emg_fee'] ?? json['emergency_fee']),
      opdFee: _readDouble(json['opd_fee']),
      videoFee: _readDouble(json['video_fee'] ?? json['video_c_fee']),
      // Per-clinic fees (user_clinics table). Only populated when the row
      // comes from view_clinic_doctors (i.e. /get_clinic_doctors).
      userClinicOpdFee: _readDouble(json['user_clinic_opd_fee']),
      userClinicVideoFee: _readDouble(json['user_clinic_video_c_fee']),
      userClinicEmgFee: _readDouble(json['user_clinic_emergency_fee']),
      stopBooking: json['stop_booking'] ?? json['doctor_stop_booking'],
      deptId: json['department'] ?? json['department_id'],
      fbLink: json['fb_linik'],
      instaLink: json['insta_link'],
      twitterLink: json['twitter_link'],
      youtubeLink: json['you_tube_link'],
      deptName: json['department_name'] ?? json['department_title'],
      clinicAddress: json['clinic_address'] ?? json['clinics_address'],
      clinicTitle: json['clinic_title'],
      clinicImage: json['clinic_image'] ?? json['clinic_images'],
      clinicId: json['clinic_id'],
      clinicThumbImage: json['clinic_thumb_image'],
      clinicStopBooking: json['clinic_stop_booking'],
      clinicCouponEnable: json['clinic_coupon_enable'],
      clinicTax:json['clinic_tax']!=null?double.parse(json['clinic_tax'].toString()):null,
      autoRescheduledAllowed: json['auto_rescheduled_allowed'] is int
          ? json['auto_rescheduled_allowed']
          : (json['auto_rescheduled_allowed'] != null ? int.tryParse(json['auto_rescheduled_allowed'].toString()) : null),
      videoAutoRescheduledAllowed: json['video_auto_rescheduled_allowed'] is int
          ? json['video_auto_rescheduled_allowed']
          : (json['video_auto_rescheduled_allowed'] != null ? int.tryParse(json['video_auto_rescheduled_allowed'].toString()) : null),
      // Accept both the correct key and the legacy typo "befor_minutes" that
      // the v_doctors view currently aliases.
      autoRescheduledAllowedBeforeMinutes: _readInt(
        json['auto_rescheduled_allowed_before_minutes']
            ?? json['auto_rescheduled_allowed_befor_minutes'],
      ),
      videoAutoRescheduledAllowedBeforeMinutes: _readInt(
        json['video_auto_rescheduled_allowed_before_minutes']
            ?? json['video_auto_rescheduled_allowed_befor_minutes'],
      ),
    );
  }

  static int? _readInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static double? _readDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}