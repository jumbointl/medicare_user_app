import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/post_req_helper.dart';
import '../model/coupon_model.dart';
import '../utilities/api_content.dart';
import '../utilities/sharedpreference_constants.dart';

class CouponService {

  static const getValidateUrl = ApiContents.getValidateUrl;
  static const getValidateLabUrl = ApiContents.getValidateLabUrl;

  static List<CouponModel> dataFromJson(jsonDecodedData) {
    return List<CouponModel>.from(
        jsonDecodedData.map((item) => CouponModel.fromJson(item)));
  }

  static Future getValidateData(
      {
        String? title,
        String? clinicId,

      })async{
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"";
    Map body={
      "user_id":uid,
      "title":title??"",
      "clinic_id":clinicId,
    };
    final res=await PostService.postReq(getValidateUrl, body);
    return res;
  }

  static Future getValidateDataLab(
      {
        String? title,
        String? labId,

      })async{
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"";
    Map body={
      "user_id":uid,
      "title":title??"",
      "lab_id":labId,
    };
    final res=await PostService.postReq(getValidateLabUrl, body);
    return res;
  }



}