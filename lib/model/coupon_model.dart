class CouponModel{
  int? id;
  String? title;
  String? description;
  double? value;

  CouponModel({
    this.id,
    this.value,
    this.title,
    this.description
  });

  factory CouponModel.fromJson(Map<String,dynamic> json){
    return CouponModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      value:  json['value']!=null?double.parse(json['value'].toString()):null,

    );
  }

}