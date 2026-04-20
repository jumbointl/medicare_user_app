import 'package:shared_preferences/shared_preferences.dart';
import '../model/vital_model.dart';
import '../helpers/get_req_helper.dart';
import '../helpers/post_req_helper.dart';
import '../utilities/api_content.dart';
import '../utilities/sharedpreference_constants.dart';

class VitalsService {

  static const getVitalsByFamilyID = ApiContents.getVitalsByFamilyID;
  static const addUrl = ApiContents.addVitalsId;
  static const deleteUrl = ApiContents.deleteVitalsUrl;
  static const updateVitalsUrl = ApiContents.updateVitalsUrl;


  static List<VitalModel> dataFromJson(jsonDecodedData) {
    return List<VitalModel>.from(
        jsonDecodedData.map((item) => VitalModel.fromJson(item)));
  }

  static Future <List<VitalModel>?> getData(String familyMemberId,String type,String startDate,String endDate) async {
    final body={
      "family_member_id":familyMemberId,
      "type":type,
      "start_date":startDate,
      "end_date":endDate
    };
    final res = await GetService.getReqWithBodY(getVitalsByFamilyID,body);
    if (res == null) {
      return null;
    } else {
      List<VitalModel> dataModelList = dataFromJson(res);
      return dataModelList;
    }
  }

  static Future addData(
      {String? systolic,
      String? diastolic,
      String? familyMemberId,
      String? type,
        String? spo2,
        String? temperature,
        String? sugarRandom,
        String? sugarFasting,
        String? weight,
        String? date,
        String? time,
      })async{
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"";
    Map body={
      "user_id":uid,
      "bp_systolic":systolic??"",
      "bp_diastolic":diastolic??"",
      "family_member_id":familyMemberId??"",
      "type":type??"",
      "weight":weight,
      "spo2":spo2,
      "temperature":temperature,
      "sugar_random":sugarRandom,
      "sugar_fasting":sugarFasting,
      "date":date,
      "time":time
    };
    final res=await PostService.postReq(addUrl, body);
    return res;
  }
  static Future updateData(
      {
        String? id,
        String? systolic,
        String? diastolic,
        String? familyMemberId,
        String? type,
        String? spo2,
        String? temperature,
        String? sugarRandom,
        String? sugarFasting,
        String? weight,
        String? date,
        String? time,
      })async{
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"";
    Map body={
      "id":id,
      "user_id":uid,
      "bp_systolic":systolic??"",
      "bp_diastolic":diastolic??"",
      "family_member_id":familyMemberId??"",
      "type":type??"",
      "weight":weight,
      "spo2":spo2,
      "temperature":temperature,
      "sugar_random":sugarRandom,
      "sugar_fasting":sugarFasting,
      "date":date,
      "time":time
    };
    final res=await PostService.postReq(updateVitalsUrl, body);
    return res;
  }

  static Future deleteData(
      {String? id,

      })async{
    Map body={
      "id":id,
    };
    final res=await PostService.postReq(deleteUrl, body);
    return res;
  }
}