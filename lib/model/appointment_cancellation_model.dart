class AppointmentCancellationRedModel{
  int? id;
  int? appointmentId;
  String? createdAt;
  String? status;
  String? notes;
  AppointmentCancellationRedModel({
    this.id,
    this.appointmentId,
    this.createdAt,
    this.status,
    this.notes
  });

  factory AppointmentCancellationRedModel.fromJson(Map<String,dynamic> json){
    return AppointmentCancellationRedModel(
      appointmentId: json['appointment_id'],
      createdAt: json['created_at'],
        id: json['id'],
      status: json['status'],
      notes: json['notes']
    );
  }

}