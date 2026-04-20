class AppointmentModel {
  int? id;
  int? patientId;
  String? pFName;
  String? pLName;
  String? pGender;
  String? pPhone;
  String? pDob;
  int? userId;
  String? departmentTitle;
  String? status;
  String? date;
  String? timeSlot;
  int? doctorId;
  int? departmentId;
  String? type;
  String? meetingId;
  String? meetingLink;
  String? doctFName;
  String? doctLName;
  String? doctImage;
  String? doctSpecialization;
  String? currentCancelReqStatus;
  double? averageRating;
  int? numberOfReview;
  int? totalAppointmentDone;
  int? clinicId;
  int? patientMRN;

  // Payment fields
  String? paymentStatus;
  dynamic paymentMethod;
  String? paymentReference;
  String? paymentProvider;
  String? paymentConfirmedAt;
  dynamic totalAmount;
  dynamic fee;
  dynamic invoiceDescription;
  dynamic paymentTransactionId;
  int? idPayment;
  int? idPaymentType;

  // Video fields
  bool? isVideoConsult;
  bool? mustPayFirst;
  bool? canJoinVideo;
  int? videoJoinOpensAt;
  int? videoJoinSecondsRemaining;
  int? durationMinutes;
  String? videoProvider;
  int? doctorJoinedAt;
  int? patientJoinedAt;

  int? videoJoinClosesAt;
  AppointmentModel({
    this.id,
    this.patientId,
    this.pFName,
    this.pLName,
    this.pGender,
    this.pPhone,
    this.pDob,
    this.userId,
    this.departmentTitle,
    this.status,
    this.date,
    this.timeSlot,
    this.doctorId,
    this.departmentId,
    this.type,
    this.meetingId,
    this.meetingLink,
    this.doctFName,
    this.doctLName,
    this.doctImage,
    this.doctSpecialization,
    this.currentCancelReqStatus,
    this.averageRating,
    this.numberOfReview,
    this.totalAppointmentDone,
    this.clinicId,
    this.patientMRN,
    this.paymentStatus,
    this.paymentMethod,
    this.paymentReference,
    this.paymentProvider,
    this.paymentConfirmedAt,
    this.totalAmount,
    this.fee,
    this.invoiceDescription,
    this.paymentTransactionId,
    this.idPayment,
    this.idPaymentType,
    this.isVideoConsult,
    this.mustPayFirst,
    this.canJoinVideo,
    this.videoJoinOpensAt,
    this.videoJoinSecondsRemaining,
    this.durationMinutes,
    this.videoJoinClosesAt,
    this.videoProvider,
    this.doctorJoinedAt,
    this.patientJoinedAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: _readInt(json['id']),
      patientId: _readInt(json['patient_id']),
      pFName: json['patient_f_name']?.toString(),
      pLName: json['patient_l_name']?.toString(),
      pGender: json['patient_gender']?.toString(),
      pPhone: json['patient_phone']?.toString(),
      pDob: json['patient_dob']?.toString(),
      userId: _readInt(json['user_id']),
      departmentTitle: json['dept_title']?.toString(),
      status: json['status']?.toString(),
      date: json['date']?.toString(),
      timeSlot: json['time_slots']?.toString(),
      doctorId: _readInt(json['doct_id']),
      departmentId: _readInt(json['dept_id']),
      type: json['type']?.toString(),
      meetingId: json['meeting_id']?.toString(),
      meetingLink: json['meeting_link']?.toString(),
      doctFName: json['doct_f_name']?.toString(),
      doctLName: json['doct_l_name']?.toString(),
      doctImage: json['doct_image']?.toString(),
      doctSpecialization: json['doct_specialization']?.toString(),
      currentCancelReqStatus: json['current_cancel_req_status']?.toString(),
      averageRating: _readDouble(json['average_rating']),
      numberOfReview: _readInt(json['number_of_reviews']),
      totalAppointmentDone: _readInt(json['total_appointment_done']),
      clinicId: _readInt(json['clinic_id']),
      patientMRN: _readInt(json['patient_mrn']),

      // Payment
      paymentStatus: json['payment_status']?.toString(),
      paymentMethod: json['payment_method'],
      paymentReference: json['payment_reference']?.toString(),
      paymentProvider: json['payment_provider']?.toString(),
      paymentConfirmedAt: json['payment_confirmed_at']?.toString(),
      totalAmount: json['total_amount'],
      fee: json['fee'],
      invoiceDescription: json['invoice_description'],
      paymentTransactionId: json['payment_transaction_id'],
      idPayment: _readInt(json['id_payment']),
      idPaymentType: _readInt(json['id_payment_type']),

      // Video
      isVideoConsult: _readBool(json['is_video_consult']) ??
          (json['type']?.toString() == 'Video Consultant'),
      mustPayFirst: _readBool(json['must_pay_first']) ?? false,
      canJoinVideo: _readBool(json['can_join_video']) ?? false,
      videoJoinOpensAt: _readInt(json['video_join_opens_at']),
      videoJoinSecondsRemaining:
      _readInt(json['video_join_seconds_remaining']) ?? 0,
      durationMinutes: _readInt(json['duration_minutes']),
      videoJoinClosesAt: json['video_join_closes_at'] is int
          ? json['video_join_closes_at']
          : int.tryParse('${json['video_join_closes_at'] ?? ''}'),
      videoProvider: json['video_provider']?.toString(),
      doctorJoinedAt: _readInt(json['doctor_joined_at']),
      patientJoinedAt: _readInt(json['patient_joined_at']),
    );
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool? _readBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final text = value.toString().toLowerCase().trim();
    if (text == '1' || text == 'true') return true;
    if (text == '0' || text == 'false') return false;
    return null;
  }
}