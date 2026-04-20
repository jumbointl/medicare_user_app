class PatientModel{
  int? id;
  String? fName;
  String? lName;
  String? phone;


  PatientModel({
    this.id,
    this.fName,
    this.lName,
    this.phone
  });

  factory PatientModel.fromJson(Map<String,dynamic> json){
    return PatientModel(
      fName: json['f_name'],
      id: json['id'],
      phone: json['phone'],
      lName: json['l_name'],
    );
  }

}