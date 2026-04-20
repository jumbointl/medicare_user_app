class AddressModel{
  int? id;
  String? name;
  String? phone;
  String? flatNo;
  String? apartmentName;
  String? area;
  String? landmark;
  String? city;
  int? pincode;


  AddressModel({
    this.id,
    this.phone,
    this.name,
    this.apartmentName,
    this.area,
    this.city,
    this.landmark,
    this.flatNo,
    this.pincode
  });

  factory AddressModel.fromJson(Map<String,dynamic> json){
    return AddressModel(
      pincode: json['pincode'],
        apartmentName: json['apartment_name'],
        area: json['area'],
        city: json['city'],
        flatNo: json['flat_no'],
        landmark: json['landmark'],
        name: json['name'],
        phone: json['s_phone'],
        id: json['id'],

    );
  }

}