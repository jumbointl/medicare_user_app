class AllowPinCodeModel{
  int? id;
  int? pinCode;


  AllowPinCodeModel({
    this.id,
    this.pinCode,
  });

  factory AllowPinCodeModel.fromJson(Map<String,dynamic> json){
    return AllowPinCodeModel(
        id: json['id'],
      pinCode: json['pin_code'],

    );
  }

}