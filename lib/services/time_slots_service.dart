import '../helpers/get_req_helper.dart';
import '../model/time_slots_model.dart';
import '../utilities/api_content.dart';

class TimeSlotsService{

  static const  getUrl=   ApiContents.getTimeSlotsUrl;
  static const  getVideoUrl=   ApiContents.getVideoTimeSlotsUrl;

  static List<TimeSlotsModel> dataFromJson (jsonDecodedData){

    return List<TimeSlotsModel>.from(jsonDecodedData.map((item)=>TimeSlotsModel.fromJson(item)));
  }

  static Future <List<TimeSlotsModel>?> getData({String? doctId,String? day,String? slotType})async {
    // fetch data
    final res=await GetService.getReq("${slotType=="1"?getUrl:slotType=="2"?getVideoUrl:""}/$doctId/$day");

    if(res==null) {
      return null; //check if any null value
    } else {
      List<TimeSlotsModel> dataModelList = dataFromJson(res); // convert all list to model
      return dataModelList;  // return converted data list model
    }
  }


}