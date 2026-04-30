class AppointmentRescheduleReqModel {
  int? id;
  int? appointmentId;
  String? status;
  String? requestedDate;
  String? requestedTimeSlots;
  String? notes;
  int? reviewedByUserId;
  String? reviewedAt;
  String? createdAt;
  String? updatedAt;

  AppointmentRescheduleReqModel({
    this.id,
    this.appointmentId,
    this.status,
    this.requestedDate,
    this.requestedTimeSlots,
    this.notes,
    this.reviewedByUserId,
    this.reviewedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory AppointmentRescheduleReqModel.fromJson(Map<String, dynamic> json) {
    return AppointmentRescheduleReqModel(
      id: json['id'],
      appointmentId: json['appointment_id'],
      status: json['status'],
      requestedDate: json['requested_date']?.toString(),
      requestedTimeSlots: json['requested_time_slots'],
      notes: json['notes'],
      reviewedByUserId: json['reviewed_by_user_id'],
      reviewedAt: json['reviewed_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}
