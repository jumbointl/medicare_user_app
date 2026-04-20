class PathologistModel{
  int? id;
  int? cityId;
  int? userId;
  String? title;
  String? address;
  double? latitude;
  double? longitude;
  int? active;
  String? description;
  String? image;
  String? email;
  String? phone;
  String? phoneSecond;
  int? stopBooking;
  int? couponEnable;
  double? tax;
  String? openingHours;
  String? whatsapp;
  String? createdAt;
  String? updatedAt;
  String? cityTitle;
  String? stateTitle;
  List? pathologyImage;
  double? averageRating;
  int? numberOfReview;
  int? totalBookingDone;
  int? isShowContactBox;
  PathologistModel({
    this.id,
    this.cityId,
    this.userId,
    this.title,
    this.address,
    this.latitude,
    this.longitude,
    this.active,
    this.description,
    this.image,
    this.email,
    this.phone,
    this.phoneSecond,
    this.stopBooking,
    this.couponEnable,
    this.tax,
    this.openingHours,
    this.whatsapp,
    this.createdAt,
    this.updatedAt,
    this.cityTitle,
    this.stateTitle,
    this.pathologyImage,
    this.averageRating,
    this.numberOfReview,
    this.totalBookingDone,
    this.isShowContactBox
  });

  factory PathologistModel.fromJson(Map<String,dynamic> json){
    return PathologistModel(
        id: json['id'] as int?,
        cityId: json['city_id'] as int?,
        userId: json['user_id'] as int?,
        title: json['title'] as String?,
        address: json['address'] as String?,
        latitude: json['latitude']!=null?double.parse(json['latitude'].toString()):null,
        longitude:json['longitude']!=null?double.parse(json['longitude'].toString()):null,
        active: json['active'] as int?,
        description: json['description'] as String?,
        image: json['image'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        phoneSecond: json['phone_second'] as String?,
        stopBooking: json['stop_booking'] as int?,
        couponEnable: json['coupon_enable'] as int?,
        tax: json['tax'] != null ? (json['tax'] as num).toDouble() : null,
        openingHours: json['opening_hours'],
        whatsapp: json['whatsapp'] as String?,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
        cityTitle: json['city_title'] as String?,
        stateTitle: json['state_title'] as String?,
        pathologyImage: json['pathology_image'],
      averageRating:  json['average_rating']!=null?double.parse(json['average_rating'].toString()):null,
      numberOfReview:json['number_of_reviews'],
      totalBookingDone:json['total_booking_done'],
      isShowContactBox: json['is_show_contact_box']
    );
  }

}