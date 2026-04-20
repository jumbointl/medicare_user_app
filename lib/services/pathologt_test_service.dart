

import '../model/pathology_test_model.dart';

import '../helpers/get_req_helper.dart';
import '../utilities/api_content.dart';


class PathologyTestService{

  static const  getUrl=   ApiContents.getPathologyTestUrl;

  static List<PathologyTestModel> dataFromJson (jsonDecodedData){

    return List<PathologyTestModel>.from(jsonDecodedData.map((item)=>PathologyTestModel.fromJson(item)));
  }


  static Future <List<PathologyTestModel>?> getData({String? start,String? end,String? cityId})async {
    final body = {
      "start":start,
      "end":end,
      "city_id":cityId,
      "active":1,

    };
    final res=await GetService.getReqWithBodY(getUrl,body);
    if(res==null) {
      return null; //check if any null value
    } else {
      List<PathologyTestModel> dataModelList = dataFromJson(res); // convert all list to model
      return dataModelList;  // return converted data list model
    }
  }
  static Future <PathologyTestModel?> getDataById({required String? testId})async {
    final res=await GetService.getReq("$getUrl/${testId??""}");
    if(res==null) {
      return null;
    } else {
      PathologyTestModel dataModel = PathologyTestModel.fromJson(res);
      return dataModel;
    }
  }
  static Future <List<PathologyTestModel>?> getDataByPathId({String? pathId})async {
    final body = {
      "active":1,
      "pathology_id":pathId,
      "with_subtest":true
    };
    final res=await GetService.getReqWithBodY(getUrl,body);
    if(res==null) {
      return null; //check if any null value
    } else {
      List<PathologyTestModel> dataModelList = dataFromJson(res); // convert all list to model
      return dataModelList;  // return converted data list model
    }
  }

}