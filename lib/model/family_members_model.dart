class FamilyMembersModel{
  int? id;
  String? fName;
  String? lName;
  String? phone;
  String? gender;
  String? dob;
  String? isdCode;

  FamilyMembersModel({
    this.id,
    this.fName,
    this.lName,
    this.phone,
    this.dob,
    this.gender,
    this.isdCode
  });

  factory FamilyMembersModel.fromJson(Map<String,dynamic> json){
    return FamilyMembersModel(
      fName: json['f_name'],
      lName: json['l_name'],
      id: json['id'],
      phone: json['phone'],
      dob: json['dob'],
      gender: json['gender'],
      isdCode: json['isd_code'],


    );
  }

}