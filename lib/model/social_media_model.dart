class SocialMediaModel{
  int? id;
  String? title;
  String? image;
  String? url;

  SocialMediaModel({
    this.id,
    this.url,
    this.title,
    this.image

  });

  factory SocialMediaModel.fromJson(Map<String,dynamic> json){
    return SocialMediaModel(
        id: json['id'],
      title:  json['title'],
      image:  json['image'],
      url:  json['url']
    );
  }

}