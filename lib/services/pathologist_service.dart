
import '../helpers/post_req_helper.dart';
import '../model/pathologist_model.dart';
import '../helpers/get_req_helper.dart';
import '../utilities/api_content.dart';

class PathologistService{

  static const  getUrl=   ApiContents.getPathologistUrl;
  static const  addLabReviewUrl=   ApiContents.addLabReviewUrl;


  static List<PathologistModel> dataFromJson (jsonDecodedData){

    return List<PathologistModel>.from(jsonDecodedData.map((item)=>PathologistModel.fromJson(item)));
  }


  static Future <List<PathologistModel>?> getData({String? start,String? end,String? cityId})async
  {
    final body = {
      "start":start,
      "end":end,
      "city_id":cityId,
      "active":1
    };
    final res=await GetService.getReqWithBodY(getUrl,body);
    if(res==null) {
      return null; //check if any null value
    } else {

      List<PathologistModel> dataModelList = dataFromJson(res); // convert all list to model
      return dataModelList;  // return converted data list model
    }
  }

  static Future <PathologistModel?> getDataById({required String? pathId})async {
    final res=await GetService.getReq("$getUrl/${pathId??""}");
    if(res==null) {
      return null;
    } else {
      PathologistModel dataModel = PathologistModel.fromJson(res);
      return dataModel;
    }
  }
  static Future addPathReView(
      {
        required String labBookingId,
        required String points,
        required String description,

      }
      )async{

    Map body={
      'lab_booking_id': labBookingId,
      'points': points,
      'description': description,

    };
    final res=await PostService.postReq(addLabReviewUrl, body);
    return res;
  }
}