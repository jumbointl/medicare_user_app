class VitalModel{
  int? id;
  int? userId;
  int? familyMemberId;
  double? bpSystolic;
  double? bpDiastolic;
  double? weight;
  double? spo2;
  double? temperature;
  double? sugar;
  double? type;
  String? date;
  String? time;
  String? createdAt;
  double? sugarFasting;
  double? sugarRandom;
  VitalModel({
    this.id,
    this.temperature,
    this.time,
    this.createdAt,
    this.date,
    this.type,
    this.bpDiastolic,
    this.bpSystolic,
    this.familyMemberId,
    this.spo2,
    this.sugar,
    this.userId,
    this.weight,
    this.sugarFasting,
    this.sugarRandom

  });

  factory VitalModel.fromJson(Map<String,dynamic> json){
    return VitalModel(
      id: json['id'],
      userId: json['user_id'],
      date: json['date'],
      time: json['time'],
      familyMemberId: json['family_member_id'],
      createdAt: json['created_at'],
      weight: json['weight']!=null?double.parse(json['weight'].toString()):null,
      spo2: json['spo2']!=null?double.parse(json['spo2'].toString()):null,
      temperature: json['temperature']!=null?double.parse(json['temperature'].toString()):null,
      sugarRandom: json['sugar_random']!=null?double.parse(json['sugar_random'].toString()):null,
      sugarFasting: json['sugar_fasting']!=null?double.parse(json['sugar_fasting'].toString()):null,
      bpSystolic: json['bp_systolic']!=null?double.parse(json['bp_systolic'].toString()):null,
      bpDiastolic: json['bp_diastolic']!=null?double.parse(json['bp_diastolic'].toString()):null,

    );
  }
}