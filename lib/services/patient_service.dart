import '../helpers/get_req_helper.dart';
import '../helpers/post_req_helper.dart';
import '../model/patient_model.dart';
import '../utilities/api_content.dart';
import '../utilities/sharedpreference_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PatientsService{

  static const  getByUIDUrl=   ApiContents.getPatientsUrl;
  static const  addUrl=   ApiContents.addPatientsUrl;

  static List<PatientModel> dataFromJson (jsonDecodedData){

    return List<PatientModel>.from(jsonDecodedData.map((item)=>PatientModel.fromJson(item)));
  }

  static Future <List<PatientModel>?> getDataByUID()async {
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"";
    // fetch data
    final body={
      "user_id":uid
    };
    final res=await GetService.getReqWithBodY(getByUIDUrl,body);

    if(res==null) {
      return null; //check if any null value
    } else {
      List<PatientModel> dataModelList = dataFromJson(res); // convert all list to model
      return dataModelList;  // return converted data list model
    }
  }

  static Future addPatient({
    required String fName,
    required String lName,
    required String isdCode,
    required String phone,

})async{
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"";
    Map body={
      "f_name":fName,
      "l_name":lName,
      "isd_code":isdCode,
      "phone":phone,
      "user_id":uid
    };
    final res=await PostService.postReq(addUrl, body);
    return res;
  }

}