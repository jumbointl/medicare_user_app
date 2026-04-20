class DepartmentModel{
  String? title;
  String? description;
  String? image;
  int? id;

  DepartmentModel({
    this.title,
    this.id,
    this.image,
    this.description
  });

  factory DepartmentModel.fromJson(Map<String,dynamic> json){
    return DepartmentModel(
      title: json['title'],
      id:json['id'],
      description: json['description'],
      image:json['image'],

    );
  }

}