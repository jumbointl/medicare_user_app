class LabBookingModel {
  int? id;
  String? pFName;
  String? pLName;
  String? status;
  String? paymentStatus;
  double? totalAmount;
  String? date;
  String? title;
  String? subTitle;
  String? pathologyTitle;
  String? currentCancelReqStatus;
  int? patientId;
  int? pathId;
  String? pathName;
  String? pathAddress;
  String? pathThumbImage;
  String? latitude;
  String? longitude;
  String? whatsapp;
  String? email;
  String? phone;
  int? isShowContactBox;
  List? labTests;
  double? averageRating;
  int? numberOfReview;
  int? totalBookingDone;
  int? patientMRN;

  LabBookingModel({
    this.id,
    this.pathologyTitle,
    this.subTitle,
    this.title,
    this.pLName,
    this.date,
    this.status,
    this.paymentStatus,
    this.totalAmount,
    this.pFName,
    this.currentCancelReqStatus,
    this.patientId,
    this.pathAddress,
    this.pathName,
    this.pathThumbImage,
    this.email,
    this.phone,
    this.whatsapp,
    this.longitude,
    this.latitude,
    this.isShowContactBox,
    this.labTests,
    this.averageRating,
    this.numberOfReview,
    this.totalBookingDone,
    this.pathId,
    this.patientMRN,
  });

  factory LabBookingModel.fromJson(Map<String, dynamic> json) {
    return LabBookingModel(
      id: json['id'],
      date: json['date'],
      pFName: json['patient_f_name'],
      pLName: json['patient_l_name'],
      status: json['status'],
      paymentStatus: json['payment_status']?.toString(),
      totalAmount: json['total_amount'] != null
          ? double.tryParse(json['total_amount'].toString())
          : null,
      title: json['title'],
      pathologyTitle: json['pathology_title'],
      subTitle: json['sub_title'],
      currentCancelReqStatus: json['current_cancel_req_status'],
      patientId: json['lab_patient_id'],
      pathAddress: json['pathology_address'],
      pathName: json['pathology_title'],
      pathThumbImage: json['pathology_thumb_image'],
      email: json['pathology_email'],
      phone: json['pathology_phone'],
      latitude: json['pathology_latitude'],
      longitude: json['pathology_longitude'],
      whatsapp: json['pathology_whatsapp'],
      isShowContactBox: json['is_show_contact_box'],
      labTests: json['lab_test_items'],
      averageRating: json['average_rating'] != null
          ? double.tryParse(json['average_rating'].toString())
          : null,
      numberOfReview: json['number_of_reviews'],
      totalBookingDone: json['total_booking_done'],
      pathId: json['pathology_id'],
      patientMRN: json['patient_mrn'],
    );
  }
}