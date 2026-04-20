class DoctorsModel{
  int? id;
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

  DoctorsModel({
    this.id,
    this.fName,
    this.exYear,
    this.lName,
    this.specialization,
    this.image,
    this.desc,
    this.clinicAppointment,
    this.emergencyAppointment,
    this.videoAppointment,
    this.averageRating,
    this.numberOfReview,
    this.totalAppointmentDone,
    this.emgFee,
    this.opdFee,
    this.videoFee,
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
    this.clinicTax
  });

  factory DoctorsModel.fromJson(Map<String,dynamic> json){
    return DoctorsModel(
      fName: json['f_name'],
      id: json['user_id'],
      exYear: json['ex_year'],
      lName: json['l_name'],
      specialization: json['specialization'],
      image: json['image'],
      desc: json['description'],
      clinicAppointment: json['clinic_appointment'],
      emergencyAppointment: json['emergency_appointment'],
      videoAppointment: json['video_appointment'],
        averageRating:  json['average_rating']!=null?double.parse(json['average_rating'].toString()):null,
      numberOfReview:json['number_of_reviews'],
        totalAppointmentDone:json['total_appointment_done'],
      emgFee:json['emg_fee']!=null?double.parse(json['emg_fee'].toString()):null,
      opdFee: json['opd_fee']!=null?double.parse(json['opd_fee'].toString()):null,
      videoFee: json['video_fee']!=null?double.parse(json['video_fee'].toString()):null,
      stopBooking: json['stop_booking'],
      deptId: json['department'],
      fbLink: json['fb_linik'],
      instaLink: json['insta_link'],
      twitterLink: json['twitter_link'],
      youtubeLink: json['you_tube_link'],
      deptName: json['department_name'],
      clinicAddress:json['clinics_address'],
      clinicTitle: json['clinic_title'],
      clinicImage: json['clinic_images'],
      clinicId: json['clinic_id'],
      clinicThumbImage: json['clinic_thumb_image'],
      clinicStopBooking: json['clinic_stop_booking'],
      clinicCouponEnable: json['clinic_coupon_enable'],
      clinicTax:json['clinic_tax']!=null?double.parse(json['clinic_tax'].toString()):null,

    );
  }

}