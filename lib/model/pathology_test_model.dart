class PathologyTestModel {
  int? id;
  String? image;
  int? pathologyId;
  String? title;
  String? subTitle;
  String? description;
  String? reportDay;
  String? categoryId;
  double? amount;
  List? subtests;


  PathologyTestModel({
    this.id,
    this.image,
    this.pathologyId,
    this.title,
    this.subTitle,
    this.description,
    this.reportDay,
    this.categoryId,
    this.amount,
    this.subtests

  });

  factory PathologyTestModel.fromJson(Map<String, dynamic> json) {
    return PathologyTestModel(
      id: json['id'],
      image: json['image'],
      pathologyId: json['pathology_id'],
      title: json['title'],
      subTitle: json['sub_title'],
      description: json['description'],
      reportDay: json['report_day']?.toString(),
      categoryId: json['category_id']?.toString(),
      amount: (json['amount'] != null) ? double.tryParse(json['amount'].toString()) : null,
      subtests: json['pathology_subtest']
    );
  }


}
