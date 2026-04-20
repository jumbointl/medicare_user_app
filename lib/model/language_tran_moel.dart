
class LanguageTranModel{
  Map? jsonData;
  String? code;
  String? direction;
  String? title;

  LanguageTranModel({
    this.title,
    this.code,
    this.direction,
    this.jsonData

  });

  factory LanguageTranModel.fromJson(Map<String,dynamic> json){
    return LanguageTranModel(
      title: json['language_title'],
      code: json['code'],
      direction: json['direction'],
      jsonData: json['json_data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "code": code,
      "direction": direction,
      "json_data":jsonData,

    };
  }

}