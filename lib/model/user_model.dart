class UserModel{
  int? id;
  String? fName;
  String? lName;
  String? phone;
  String? email;
  String? fcmId;
  String? imageUrl;
  String? gender;
  String? dob;
  double? walletAmount;
  String? createdAt;
  String? isdcode;
  UserModel({
    this.id,
    this.email,
    this.fcmId,
    this.imageUrl,
    this.phone,
    this.fName,
    this.lName,
    this.gender,
    this.dob,
    this.walletAmount,
    this.createdAt,
    this.isdcode
  });

  factory UserModel.fromJson(Map<String,dynamic> json){
    return UserModel(
        email:json['email'],
        fcmId:json['fcm'],
        imageUrl:json['image'],
        phone:json['phone'],
        lName:json['l_name'],
        id: json['id'],
      fName: json['f_name'],
      gender: json['gender'],
      dob: json['dob'],
      createdAt: json['created_at'],
      walletAmount: json['wallet_amount']!=null?double.parse(json['wallet_amount'].toString()):null,
      isdcode: json['isd_code'],
    );
  }
}