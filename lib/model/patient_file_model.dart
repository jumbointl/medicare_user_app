class PatientFileModel{
  int? id;
  String? fileName;
  String? fileUrl;
  int? patientId;
  String? pFName;
  String? pLName;
  String? createdAt;
  PatientFileModel({
    this.id,
    this.fileName,
    this.pFName,
    this.pLName,
    this.patientId,
    this.createdAt,
    this.fileUrl
  });

  factory PatientFileModel.fromJson(Map<String,dynamic> json){
    return PatientFileModel(
      patientId: json['patient_id'],
      id: json['id'],
      fileName: json['file_name'],
      pFName:  json['f_name'],
      pLName:  json['l_name'],
      createdAt: json['created_at'],
      fileUrl: json['file']
    );
  }

}