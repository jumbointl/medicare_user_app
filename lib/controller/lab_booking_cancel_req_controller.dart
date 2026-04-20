import 'package:get/get.dart';
import 'package:medicare_user_app/services/lab_booking_cancellation_service.dart';
import '../model/LabAppointmentCancellationReqModel.dart';
import '../model/doctors_model.dart';

class LabBookingCancelReqController extends GetxController {
  var isLoading = false.obs; // Loading for data fetching
  var dataList = <Labappointmentcancellationreqmodel>[].obs; // list of all fetched data
  var isError = false.obs;
  var dataMap = DoctorsModel().obs; // list of all fetched data

  void getData({required String bookingId}) async {
    isLoading(true);
    try {
      final getDataList = await LabBookingCancellationService.getData(bookingId:bookingId);
      if (getDataList !=null) {
        isError(false);
        dataList.value = getDataList;

      } else {
        isError(true);
      }
    } catch (e) {
      isError(true);
    } finally {
      isLoading(false);
    }
  }
}
