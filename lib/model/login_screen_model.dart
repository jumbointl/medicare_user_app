class LoginScreenModel{
  String? image;

  LoginScreenModel({
    this.image,
  });

  factory LoginScreenModel.fromJson(Map<String,dynamic> json){
    return LoginScreenModel(
      image: json['image'],
    );
  }

}