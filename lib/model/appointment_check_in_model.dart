class AppointmentCheckInModel{
  int? id;
  int? appointmentId;
  String? doctFName;
  String? doctLName;
  String? pFName;
  String? pLName;
  String? type;
  String? departmentTitle;
  String? date;


  AppointmentCheckInModel({
    this.id,
   this.date,
    this.type,
    this.appointmentId,
    this.departmentTitle,
    this.doctFName,
    this.doctLName,
    this.pFName,
    this.pLName
  });

  factory AppointmentCheckInModel.fromJson(Map<String,dynamic> json){
    return AppointmentCheckInModel(
      id: json['id'],
      pFName: json['patient_f_name'],
      pLName: json['patient_l_name'],
      doctFName: json['doct_f_name'],
      doctLName: json['doct_l_name'],
      date: json['date'],
      appointmentId: json['appointment_id'],
      departmentTitle: json['dept_title'],
      type: json['type']

    );
  }

}