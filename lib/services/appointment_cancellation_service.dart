import '../helpers/get_req_helper.dart';
import '../model/appointment_cancellation_model.dart';
import '../utilities/api_content.dart';
import '../helpers/post_req_helper.dart';

class AppointmentCancellationService{

  static const  getByAppIdUrl=   ApiContents.getAppointmentCancellationUrlByAppId;
  static const  addAppUrl=   ApiContents.appointmentCancellationUrl;
  static const deleteAppUrl=   ApiContents.deleteAppointmentCancellationUrl;
  static const addDoctorsReviewUrl=   ApiContents.addDoctorsReviewUrl;

  static List<AppointmentCancellationRedModel> dataFromJson (jsonDecodedData){
    return List<AppointmentCancellationRedModel>.from(jsonDecodedData.map((item)=>AppointmentCancellationRedModel.fromJson(item)));
  }
  static Future addAppointmentCancelRequest(
      {
        required String appointmentId,
        required String status,
      }
      )async{

    Map body={
      'status': status,
      'appointment_id':appointmentId
    };
    final res=await PostService.postReq(addAppUrl, body);
    return res;
  }
  static Future deleteReq({required String appointmentId})async{
    Map body={
      "appointment_id":appointmentId
    };
    final res=await PostService.postReq(deleteAppUrl, body);
    return res;
  }
  static Future <List<AppointmentCancellationRedModel>?> getData({required String appointmentId})async {
    final res=await GetService.getReq("$getByAppIdUrl/$appointmentId");
    if(res==null) {
      return null;
    } else {
      List<AppointmentCancellationRedModel> dataModelList = dataFromJson(res);
      return dataModelList;
    }
  }

}