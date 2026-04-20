class TimeSlotsModel{
  String? timeStart;
  String? timeEnd;

  TimeSlotsModel({
  this.timeEnd,
    this.timeStart
  });

  factory TimeSlotsModel.fromJson(Map<String,dynamic> json){
    return TimeSlotsModel(
      timeEnd: json['time_end'],
      timeStart: json['time_start']
    );
  }

}