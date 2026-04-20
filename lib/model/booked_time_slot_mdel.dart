class BookedTimeSlotsModel{
  String? timeSlots;
  String? type;
  String? date;
  int? appointmentId;

  BookedTimeSlotsModel({
  this.type,
    this.date,
    this.appointmentId,
    this.timeSlots
  });

  factory BookedTimeSlotsModel.fromJson(Map<String,dynamic> json){
    return BookedTimeSlotsModel(
      appointmentId: json['appointment_id'],
        date: json['date'],
        timeSlots: json['time_slots'],
        type: json['type'],
    );
  }

}