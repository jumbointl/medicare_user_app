import '../model/banner_model.dart';
import '../helpers/get_req_helper.dart';
import '../utilities/api_content.dart';

class BannerService{

  static const  getUrl=   ApiContents.getBannerUrl;

  static List<BannerModel> dataFromJson (jsonDecodedData){

    return List<BannerModel>.from(jsonDecodedData.map((item)=>BannerModel.fromJson(item)));
  }

  static Future <List<BannerModel>?> getData()async {
    final body={"type":"Mobile"};
    // fetch data
    final res=await GetService.getReqWithBodY(getUrl,body);

    if(res==null) {
      return null; //check if any null value
    } else {
      List<BannerModel> dataModelList = dataFromJson(res); // convert all list to model
      return dataModelList;  // return converted data list model
    }
  }


}