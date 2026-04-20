class DoctorsReviewModel{
  int? points;
  String? description;
  String? fName;
  String? lName;


  DoctorsReviewModel({
    this.points,
    this.description,
    this.fName,
    this.lName,
  });

  factory DoctorsReviewModel.fromJson(Map<String,dynamic> json){
    return DoctorsReviewModel(
      fName: json['f_name'],
      lName: json['l_name'],
      description: json['description'],
      points: json['points'],

    );
  }

}