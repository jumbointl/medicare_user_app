import '../helpers/get_req_helper.dart';
import '../model/LabAppointmentCancellationReqModel.dart';
import '../utilities/api_content.dart';
import '../helpers/post_req_helper.dart';

class LabBookingCancellationService{

  static const  getByAppIdUrl=   ApiContents.getLabBookingCancellationUrl;
  static const  addAppUrl=   ApiContents.labBookingCancellationUrl;
  static const deleteAppUrl=   ApiContents.deleteLabBookingCancellationUrl;

  static List<Labappointmentcancellationreqmodel> dataFromJson (jsonDecodedData){
    return List<Labappointmentcancellationreqmodel>.from(jsonDecodedData.map((item)=>Labappointmentcancellationreqmodel.fromJson(item)));
  }
  static Future addAppointmentCancelRequest(
      {
        required String appointmentId,
        required String status,
      }
      )async{

    Map body={
      'status': status,
      'lab_booking_id':appointmentId
    };
    final res=await PostService.postReq(addAppUrl, body);
    return res;
  }
  static Future deleteReq({required String appointmentId})async{
    Map body={
      "lab_booking_id":appointmentId
    };
    final res=await PostService.postReq(deleteAppUrl, body);
    return res;
  }
  static Future <List<Labappointmentcancellationreqmodel>?> getData({required String bookingId})async {
    final body={
      "lab_booking_id":bookingId
    };
    final res=await GetService.getReqWithBodY(getByAppIdUrl,body);
    if(res==null) {
      return null;
    } else {
      List<Labappointmentcancellationreqmodel> dataModelList = dataFromJson(res);
      return dataModelList;
    }
  }

}