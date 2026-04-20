import 'package:get/get.dart';
import '../model/lab_booking_model.dart';
import '../services/lab_booking_service.dart';

class LabBookingController extends GetxController {
  var isLoading = false.obs; // Loading for data fetching
  var dataList = <LabBookingModel>[].obs; // list of all fetched data
  var isError = false.obs;

  void getData() async {
    isLoading(true);
    try {
      final getDataList = await LabBookingService.getData();

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
