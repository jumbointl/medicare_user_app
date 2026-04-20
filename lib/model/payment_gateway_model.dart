class PaymentGatewayModel{

  String? key;
  String? secret;
  String? title;


  PaymentGatewayModel({
    this.secret,
    this.key,
    this.title
  });

  factory PaymentGatewayModel.fromJson(Map<String,dynamic> json){
    return PaymentGatewayModel(
        title: json['title'],
      key: json['key'],
      secret: json['secret']
    );
  }

}