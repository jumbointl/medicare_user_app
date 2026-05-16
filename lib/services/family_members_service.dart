import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/get_req_helper.dart';
import '../helpers/post_req_helper.dart';
import '../model/family_members_model.dart';
import '../utilities/api_content.dart';
import '../utilities/sharedpreference_constants.dart';

class FamilyMembersService{

  static const  addUrl=   ApiContents.addFamilyMemberUrl;
  static const  updateUrl=   ApiContents.updateFamilyMemberUrl;
  static const  deleteFamilyMemberUrl=   ApiContents.deleteFamilyMemberUrl;
  static const  getFamilyMembersByUIDUrl=   ApiContents.getFamilyMembersByUIDUrl;

  static List<FamilyMembersModel> dataFromJson (jsonDecodedData){

    return List<FamilyMembersModel>.from(jsonDecodedData.map((item)=>FamilyMembersModel.fromJson(item)));
  }

  static Future <List<FamilyMembersModel>?> getData()async {
    SharedPreferences preferences=await SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"";

    final res=await GetService.getReq("$getFamilyMembersByUIDUrl/$uid");
    if(res==null) {
      return null;
    } else {

      List<FamilyMembersModel> dataModelList = dataFromJson(res);

      return dataModelList;
    }
  }
  static Future updateUser(
      {required String? fName,
        required String? lName,
        required String? gender,
        required String? dob,
        required String? phone,
        required String? isdCode,
        required String? id,
      })async{
    Map body={
      "id":id,
      "f_name":fName??"",
      "l_name":lName??"",
      "phone":phone??"",
      "gender":gender??"",
      "isd_code":isdCode??"",
      "dob":dob??""
    };
    final res=await PostService.postReq(updateUrl, body);
    return res;
  }

  /// Backend refactor 2026-05-16: 4 casos según presencia de phone/email/password.
  ///   A) phone existente   → backend reusa user (cross-owner)
  ///   B) phone nuevo + password → backend crea user con login propio
  ///   C) sin phone NI email → familiar 'managed' (hijo menor, sin login)
  ///   D) email solo        → backend crea user, Google login dedupea después
  /// El form debe pasar SOLO los campos con valor (no empty strings).
  static Future addUser(
      {required String? fName,
        required String? lName,
        required String? gender,
        required String? dob,
        String? phone,
        String? email,
        String? password,
        String? isdCode,

      })async{
    SharedPreferences preferences=await SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"";
    final Map<String, dynamic> body = {
      "user_id": uid,
      "f_name": fName ?? "",
      "l_name": lName ?? "",
      "gender": gender ?? "",
      "isd_code": isdCode ?? "",
      "dob": dob ?? "",
    };
    // Backend rechaza phone/email empty string (superRefine). Mandar campo
    // solo si tiene valor real.
    final phoneTrim = phone?.trim();
    if (phoneTrim != null && phoneTrim.isNotEmpty) body["phone"] = phoneTrim;
    final emailTrim = email?.trim();
    if (emailTrim != null && emailTrim.isNotEmpty) body["email"] = emailTrim;
    final passwordTrim = password?.trim();
    if (passwordTrim != null && passwordTrim.isNotEmpty) {
      body["password"] = passwordTrim;
    }
    final res = await PostService.postReq(addUrl, body);
    return res;
  }
  static Future deleteData(
      {required String? id
      })async{
    Map body={
      "id":id,
    };
    final res=await PostService.postReq(deleteFamilyMemberUrl, body);
    return res;
  }

  static FamilyMembersModel dataFromJsonById(data) {
    return FamilyMembersModel.fromJson(data);
  }
  static Future <FamilyMembersModel?> getDataById({required String? addId})async {

    final res=await GetService.getReq("$getFamilyMembersByUIDUrl/${addId??""}");
    if(res==null) {
      return null;
    } else {
      FamilyMembersModel dataModel = dataFromJsonById(res);
      return dataModel;
    }
  }

}