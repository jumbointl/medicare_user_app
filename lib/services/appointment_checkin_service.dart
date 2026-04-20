import '../helpers/get_req_helper.dart';
import '../model/appointment_check_in_model.dart';
import '../utilities/api_content.dart';

class AppointmentCheckinService{

  static const  getAppointmentCheckInUserUrl=   ApiContents.getAppointmentCheckInUserUrl;

  static List<AppointmentCheckInModel> dataFromJson (jsonDecodedData){

    return List<AppointmentCheckInModel>.from(jsonDecodedData.map((item)=>AppointmentCheckInModel.fromJson(item)));
  }

  static Future <List<AppointmentCheckInModel>?> getData({required String doctId, required String date})async {
    final body={
      "doctor_id":doctId,
      "date":date
    };

    final res=await GetService.getReqWithBodY(getAppointmentCheckInUserUrl,body);
    if(res==null) {
      return null;
    } else {
      List<AppointmentCheckInModel> dataModelList = dataFromJson(res);
      return dataModelList;
    }
  }


}