class NotificationSeenModel{
 bool? dotStatus ;


  NotificationSeenModel({
    this.dotStatus
  });

  factory NotificationSeenModel.fromJson(Map<String,dynamic> json){
    return NotificationSeenModel(
      dotStatus: json['dot_status'],
    );
  }

}