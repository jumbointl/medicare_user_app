import 'package:shared_preferences/shared_preferences.dart';
import '../model/lab_cart_model.dart';
import '../helpers/get_req_helper.dart';
import '../helpers/post_req_helper.dart';

import '../utilities/api_content.dart';
import '../utilities/sharedpreference_constants.dart';

class LabCartService{

  static const  labDeleteCartUrl=   ApiContents.labDeleteCartUrl;
  static const  addAppUrl=   ApiContents.labAddToCartUrl;
  static const  labGetToCartUrl=   ApiContents.labGetToCartUrl;
  static const  labDeleteAndAddCartUrl=   ApiContents.labDeleteAndAddCartUrl;
  static List<LabCartModel> dataFromJson (jsonDecodedData){
    return List<LabCartModel>.from(jsonDecodedData.map((item)=>LabCartModel.fromJson(item)));
  }
  static Future addData(
      {
        required String labTestId,
        required String qty,
      }
      )async{
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"-1";
    Map body={
      "user_id":uid,
      'lab_test_id': labTestId,
      "qty":qty
    };
    final res=await PostService.postReq(addAppUrl, body);
    return res;
  }
  //
  static Future deleteAndAddData(
      {
        required String idsList
      }
      )async{
    SharedPreferences sharedPreferences=await SharedPreferences.getInstance();
    final uid= sharedPreferences.getString(SharedPreferencesConstants.uid)??"-1";

    Map body={'user_id': uid,
    'lab_test_ids': idsList};
    final res=await PostService.postReq(labDeleteAndAddCartUrl, body);
    return res;
  }
  static Future deleteData(
      {
        required String id
      }
      )async{
    Map body={'id': id};
    final res=await PostService.postReq(labDeleteCartUrl, body);
    return res;
  }


  static Future <List<LabCartModel>?> getData(String pathId)async {
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"-1";
    final body={
      "user_id":uid,
      'path_id': pathId,
      "with_subtest":"1"
    };
    final res=await GetService.getReqWithBodY(labGetToCartUrl,body);
    if(res==null) {
      return null;
    } else {
      List<LabCartModel> dataModelList = dataFromJson(res);
      return dataModelList;
    }
  }
  // static Future <AppointmentModel?> getDataById({required String? appId})async {
  //   final res=await GetService.getReq("$getAppByIDUrl/${appId??""}");
  //   if(res==null) {
  //     return null;
  //   } else {
  //     AppointmentModel dataModel = AppointmentModel.fromJson(res);
  //     return dataModel;
  //   }
  // }

}