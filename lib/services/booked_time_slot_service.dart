import '../helpers/get_req_helper.dart';
import '../model/booked_time_slot_mdel.dart';
import '../utilities/api_content.dart';

class BookedTimeSlotsService{

  static const  getUrl=   ApiContents.getBookedTimeSlotsUrl;

  static List<BookedTimeSlotsModel> dataFromJson (jsonDecodedData){

    return List<BookedTimeSlotsModel>.from(jsonDecodedData.map((item)=>BookedTimeSlotsModel.fromJson(item)));
  }

  static Future <List<BookedTimeSlotsModel>?> getData({String? doctId, String? date,String? type})async {

    // fetch data
    final res=await GetService.getReq("$getUrl?doct_id=$doctId&date=$date&type=$type");

    if(res==null) {
      return null; //check if any null value
    } else {
      List<BookedTimeSlotsModel> dataModelList = dataFromJson(res); // convert all list to model
      return dataModelList;  // return converted data list model
    }
  }


}