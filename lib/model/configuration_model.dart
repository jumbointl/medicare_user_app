class ConfigurationModel{
  int? id;
  String? value;
  String? idName;
  ConfigurationModel({
    this.id,
    this.value,
    this.idName
  });

  factory ConfigurationModel.fromJson(Map<String,dynamic> json){
    return ConfigurationModel(
      id: json['id'],
      value: json['value'],
      idName: json['id_name']

    );
  }

}