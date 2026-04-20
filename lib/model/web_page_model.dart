class WebPageModel{
  String? body;

  WebPageModel({
      this.body

  });

  factory WebPageModel.fromJson(Map<String,dynamic> json){
    return WebPageModel(
        body  : json['body'],
    );
  }

}