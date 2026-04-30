import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/doctors_review_model.dart';
import '../helpers/get_req_helper.dart';
import '../helpers/post_req_helper.dart';
import '../model/doctors_model.dart';
import '../utilities/api_content.dart';
import '../utilities/app_constans.dart';
import '../utilities/clinic_config.dart';
import '../utilities/sharedpreference_constants.dart';

class DoctorsService{

  static const  getUrl=   ApiContents.getDoctorsUrl;
  static const  getDoctorsActiveUrl=   ApiContents.getDoctorsUrl;
  static const  addDoctorsReviewUrl=   ApiContents.addDoctorsReviewUrl;
  static const  getDoctorReviewUrl=   ApiContents.getDoctorReviewUrl;

  static List<DoctorsModel> dataFromJson (jsonDecodedData){

    return List<DoctorsModel>.from(jsonDecodedData.map((item)=>DoctorsModel.fromJson(item)));
  }
  static List<DoctorsReviewModel> dataFromJsonDR (jsonDecodedData){

    return List<DoctorsReviewModel>.from(jsonDecodedData.map((item)=>DoctorsReviewModel.fromJson(item)));
  }
  static Future addDoctorReView(
      {
        required String appointmentId,
        required String points,
        required String description,
        required String doctorId,
      }
      )async{
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"";
    Map body={
      'doctor_id': doctorId,
      'points': points,
      'description': description,
      'appointment_id':appointmentId,
      "user_id":uid
    };
    final res=await PostService.postReq(addDoctorsReviewUrl, body);
    return res;
  }


  static Future <List<DoctorsModel>?> getData({String? searchQuery,String? cityId})async {
      // fetch data
    final body=<String, dynamic>{
      "active":"1",
      "search_query":searchQuery??"",
      "city_id":cityId??""
    };
    ClinicConfig.applyTo(body);
    final res=await GetService.getReqWithBodY(getDoctorsActiveUrl,body);

    if(res==null) {
      return null; //check if any null value
    } else {
      List<DoctorsModel> dataModelList = dataFromJson(res); // convert all list to model
      return dataModelList;  // return converted data list model
    }
  }


  static Future <List<DoctorsModel>?> getDataByClinicId({String? searchQuery,String? clinicId})async {
    // fetch data
    final body={
      "active":"1",
      // "search_query":searchQuery??"",
      "clinic_id":clinicId??""
    };
    final res=await GetService.getReqWithBodY(getDoctorsActiveUrl,body);

    if(res==null) {
      return null; //check if any null value
    } else {
      List<DoctorsModel> dataModelList = dataFromJson(res); // convert all list to model
      return dataModelList;  // return converted data list model
    }
  }

  static Future <DoctorsModel?> getDataById({required String? doctId})async {
    // Guard against null / empty / literal-"null" — would otherwise build
    // /get_doctor/null which 404s on the backend.
    if (doctId == null || doctId.isEmpty || doctId == 'null') {
      return null;
    }
    final res=await GetService.getReq("$getUrl/$doctId");
    if(res==null) {
      return null;
    } else {
      DoctorsModel dataModel = DoctorsModel.fromJson(res);
      return dataModel;
    }
  }

  /// Fetch a single doctor row from view_clinic_doctors filtered by clinic
  /// and doctor. Use this whenever a clinic context exists so the returned
  /// row carries the per-clinic fees (user_clinic_opd_fee /
  /// user_clinic_video_c_fee / user_clinic_emergency_fee), not the
  /// per-doctor defaults shared across clinics.
  static Future<DoctorsModel?> getDataByClinicAndDoctorId({
    required String clinicId,
    required String doctId,
  }) async {
    if (clinicId.isEmpty || clinicId == 'null') return null;
    if (doctId.isEmpty || doctId == 'null') return null;
    final url = '${ApiContents.getClinicDoctorsUrl}'
        '?clinic_id=${Uri.encodeQueryComponent(clinicId)}'
        '&doctor_id=${Uri.encodeQueryComponent(doctId)}'
        '&limit=1';
    // Direct Dio fetch because the shared GetService.getReq helper requires
    // the legacy `response: 200` envelope, but get_clinic_doctors returns
    // the modern `status: true` shape — the helper would drop our payload
    // and we'd silently fall through to the legacy /get_doctor/{id} endpoint.
    dynamic raw;
    try {
      final dio = Dio(BaseOptions(
        headers: {
          'x-api-key': AppConstants.apiKey,
          'Accept': 'application/json',
        },
      ));
      final response = await dio.get(url);
      raw = response.data;
      if (raw is String) raw = jsonDecode(raw);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('getDataByClinicAndDoctorId fetch failed: $e');
      }
      return null;
    }
    List rows;
    if (raw is List) {
      rows = raw;
    } else if (raw is Map && raw['data'] is List) {
      rows = raw['data'] as List;
    } else {
      return null;
    }
    if (rows.isEmpty) return null;
    final first = rows.first;
    if (first is! Map) return null;
    return DoctorsModel.fromJson(Map<String, dynamic>.from(first));
  }
  static Future <List<DoctorsReviewModel>?> getDataDoctorsReview({String? doctId})async {
    final body={
      "doctor_id":doctId
    };
    // fetch data
    final res=await GetService.getReqWithBodY(getDoctorReviewUrl,body);

    if(res==null) {
      return null; //check if any null value
    } else {
      List<DoctorsReviewModel> doctorsReviewModelList = dataFromJsonDR(res); // convert all list to model
      return doctorsReviewModelList;  // return converted data list model
    }
  }

}