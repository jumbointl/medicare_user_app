import '../helpers/get_req_helper.dart';
import '../model/login_screen_model.dart';
import '../utilities/api_content.dart';

class LoginScreenService{

  static const  getUrl=   ApiContents.getLoginImageUrl;

  static List<LoginScreenModel> dataFromJson (jsonDecodedData){

    return List<LoginScreenModel>.from(jsonDecodedData.map((item)=>LoginScreenModel.fromJson(item)));
  }

  static Future <List<LoginScreenModel>?> getData()async {

    // fetch data
    final res=await GetService.getReq(getUrl);

    if(res==null) {
      return null; //check if any null value
    } else {
      List<LoginScreenModel> dataModelList = dataFromJson(res); // convert all list to model
      return dataModelList;  // return converted data list model
    }
  }


}