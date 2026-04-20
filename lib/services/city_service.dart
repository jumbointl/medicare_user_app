import 'package:flutter/foundation.dart';

import '../model/city_model.dart';
import '../helpers/get_req_helper.dart';
import '../utilities/api_content.dart';


class CityService{

  static const  getUrl=   ApiContents.getCityUrl;
  static const  getLocationUrl=   ApiContents.getLocationUrl;
  static List<CityModel> dataFromJson (jsonDecodedData){

    return List<CityModel>.from(jsonDecodedData.map((item)=>CityModel.fromJson(item)));
  }


  static Future <List<CityModel>?> getData({String? search})async {
    // fetch data
    final body = {
      "search":search,
      "active":1
    };

    final res=await GetService.getReqWithBodY(getUrl,body);

    if(res==null) {
      return null; //check if any null value
    } else {
      List<CityModel> dataModelList = dataFromJson(res); // convert all list to model
      return dataModelList;  // return converted data list model
    }
  }

  static Future  getLocationData({String? lat,String? lng})async {
    // fetch data
    final body = {
      "latitude":lat??"",
      "longitude":lng??""
    };
    if (kDebugMode) {
      debugPrint("CityService.getLocationData lat=$lat lng=$lng");
    }
    final res=await GetService.getReqWithBodY(getLocationUrl,body);


    if(res==null) {
      return null; //check if any null value
    } else {// convert all list to model
      return res;  // return converted data list model
    }
  }
}