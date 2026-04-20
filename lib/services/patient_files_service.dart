import 'package:shared_preferences/shared_preferences.dart';
import '../model/patient_file_model.dart';
import '../utilities/sharedpreference_constants.dart';

import '../helpers/get_req_helper.dart';

import '../utilities/api_content.dart';

class PatientFilesService{

  static const  getUrl=   ApiContents.getPatientFileUrl;
  static const  getPatientFileByIdrl=   ApiContents.getPatientFileUrl;
  static const  getPatientFileByPatientIUrl=   ApiContents.getPatientFileUrl;


  static List<PatientFileModel> dataFromJson (jsonDecodedData){

    return List<PatientFileModel>.from(jsonDecodedData.map((item)=>PatientFileModel.fromJson(item)));
  }

  static Future <List<PatientFileModel>?> getData(String searchQ)async {
    SharedPreferences preferences=await SharedPreferences.getInstance();
    final uid=preferences.getString(SharedPreferencesConstants.uid);

    final body={
      "user_id":uid,
      "search":searchQ
    };

    // fetch data
    final res=await GetService.getReqWithBodY(
        getUrl,body);

    if(res==null) {
      return null; //check if any null value
    } else {
      List<PatientFileModel> dataModelList = dataFromJson(res); // convert all list to model
      return dataModelList;  // return converted data list model
    }
  }

  static Future <PatientFileModel?> getDataById({required String? id})async {
    final res=await GetService.getReq("$getPatientFileByIdrl/${id??""}");
    if(res==null) {
      return null;
    } else {
      PatientFileModel dataModel = PatientFileModel.fromJson(res);
      return dataModel;
    }
  }

  static Future <List<PatientFileModel>?> getDataByPatientId(String id)async {
    final body={
      "patient_id":id
    };
    // fetch data
    final res = await GetService.getReqWithBodY(getPatientFileByPatientIUrl,body);

    if (res == null) {
      return null; //check if any null value
    } else {
      List<PatientFileModel> dataModelList = dataFromJson(
          res); // convert all list to model
      return dataModelList; // return converted data list model
    }
  }




}