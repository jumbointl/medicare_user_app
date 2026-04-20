class TestimonialModel{
  int? id;
  String? title;
  String? subTitle;
  int? ratting;
  String? desc;
  String? createdAt;
  String? image;
  TestimonialModel({
    this.id,
    this.title,
    this.subTitle,
    this.createdAt,
    this.desc,
    this.ratting,
    this.image

  });

  factory TestimonialModel.fromJson(Map<String,dynamic> json){
    return TestimonialModel(
      ratting:json['rating'],
      desc:json['description'],
      subTitle:json['sub_title'],
      title:json['title'],
      id: json['id'],
      createdAt: json['created_at'],
      image: json['image']
    );
  }
}