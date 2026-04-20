class PrescriptionModel{
  int? id;
  String? doctorFName;
  String? doctorLName;
  String? patientFName;
  String? patientLName;
  String? createdAt;
  String? pdfFileUrl;
  PrescriptionModel({
    this.id,
    this.createdAt,
    this.patientLName,
    this.patientFName,
    this.doctorFName,
    this.doctorLName,
    this.pdfFileUrl
  });

  factory PrescriptionModel.fromJson(Map<String,dynamic> json){
    return PrescriptionModel(
        id: json['id'],
        patientLName: json['patient_l_name'],
        patientFName: json['patient_f_name'],
        createdAt: json['created_at'],
        doctorFName: json['doctor_f_name'],
        doctorLName: json['doctor_l_name'],
        pdfFileUrl: json['pdf_file']
    );
  }

}