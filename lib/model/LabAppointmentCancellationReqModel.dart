class Labappointmentcancellationreqmodel{
  int? id;
  int? labBookingId;
  String? createdAt;
  String? status;
  String? notes;
  Labappointmentcancellationreqmodel({
    this.id,
    this.labBookingId,
    this.createdAt,
    this.status,
    this.notes
  });

  factory Labappointmentcancellationreqmodel.fromJson(Map<String,dynamic> json){
    return Labappointmentcancellationreqmodel(
        labBookingId: json['lab_booking_id'],
        createdAt: json['created_at'],
        id: json['id'],
        status: json['status'],
        notes: json['notes']
    );
  }

}