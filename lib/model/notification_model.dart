class NotificationModel{
  int? id;
  String? title;
  String? body;
  int? appointmentId;
  int? labBookingId;
  int? txnId;
  int? fileId;
  int? prescriptionId;
  int? userId;
  String? createdAt;
  String? image;

  NotificationModel({
    this.id,
    this.body,
    this.title,
    this.createdAt,
    this.image,
    this.appointmentId,
    this.fileId,
    this.prescriptionId,
    this.txnId,
    this.userId,
    this.labBookingId


  });

  factory NotificationModel.fromJson(Map<String,dynamic> json){
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body:  json['body'],
      createdAt: json['created_at'],
      image: json['image'],
      appointmentId:  json['appointment_id'],
      fileId:  json['file_id'],
      prescriptionId:  json['prescription_id'],
      txnId:  json['txn_id'],
      userId:  json['user_id'],
      labBookingId: json['lab_booking_id']

    );
  }

}