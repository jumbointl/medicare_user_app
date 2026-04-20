import '../helpers/get_req_helper.dart';
import '../model/department_model.dart';
import '../utilities/api_content.dart';

class DepartmentService{

  static const  getUrl=   ApiContents.getDepartmentUrl;

  static List<DepartmentModel> dataFromJson (jsonDecodedData){

    return List<DepartmentModel>.from(jsonDecodedData.map((item)=>DepartmentModel.fromJson(item)));
  }

  static Future <List<DepartmentModel>?> getData()async {

    // fetch data
    final res=await GetService.getReq(getUrl);

    if(res==null) {
      return null; //check if any null value
    } else {
      List<DepartmentModel> dataModelList = dataFromJson(res); // convert all list to model
      return dataModelList;  // return converted data list model
    }
  }


}