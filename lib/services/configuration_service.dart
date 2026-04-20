import '../helpers/get_req_helper.dart';
import '../model/configuration_model.dart';
import '../utilities/api_content.dart';

class ConfigurationService{

  static const  getConfigByIdNameApiUrl=   ApiContents.getConfigByIdNameApiUrl;
  static const  getConfigByGroupNameApiUrl=   ApiContents.getConfigByGroupNameApiUrl;
  static const  getConfigUrl=   ApiContents.getConfigUrl;

  static List<ConfigurationModel> dataFromJson (jsonDecodedData){

    return List<ConfigurationModel>.from(jsonDecodedData.map((item)=>ConfigurationModel.fromJson(item)));
  }

  static ConfigurationModel dataFromJsonById(data) {
    return ConfigurationModel.fromJson(data);
  }
  static Future <ConfigurationModel?> getDataById({required String? idName})async {

    final res=await GetService.getReq("$getConfigByIdNameApiUrl/${idName??""}");
    if(res==null) {
      return null;
    } else {
      ConfigurationModel dataModel = dataFromJsonById(res);
      return dataModel;
    }
  }

  static Future <List<ConfigurationModel>?> getDataByGroupName(String groupName)async {
    final res=await GetService.getReq("$getConfigByGroupNameApiUrl/$groupName");
    if(res==null) {
      return null;
    } else {
      List<ConfigurationModel> dataModelList = dataFromJson(res);
      return dataModelList;
    }
  }
  static Future <List<ConfigurationModel>?> getData()async {
    final res=await GetService.getReq(getConfigUrl);
    if(res==null) {
      return null;
    } else {
      List<ConfigurationModel> dataModelList = dataFromJson(res);
      return dataModelList;
    }
  }


}