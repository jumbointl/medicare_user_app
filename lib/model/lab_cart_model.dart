
class LabCartModel{
  int? id;
  int? labTestId ;
  int? userId ;
  int? qty;
  String? title;
  String? subTitle;
  double? amount;
  String?  pathologistTitle;
  String? image;
  List? subtests;

  LabCartModel({
    this.id,
    this.qty,
    this.labTestId,
    this.userId,
    this.subTitle,
    this.amount,
    this.title,
    this.pathologistTitle,
    this.image,
    this.subtests

  });
  factory LabCartModel.fromJson(Map<String,dynamic> json){
    return LabCartModel(
        id: json['id'],
        labTestId:  json['lab_test_id'],
      userId:  json['user_id'],
        qty:  json['qty'],
      subTitle: json['sub_title'],
      title: json['title'],
      pathologistTitle: json['pathologist_title'],
      amount: (json['amount'] != null) ? double.tryParse(json['amount'].toString()) : null,
      image: json['image'],
        subtests: json['pathology_subtest']
    );
  }
}