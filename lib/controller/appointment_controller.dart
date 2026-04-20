import 'package:get/get.dart';
import '../model/appointment_model.dart';
import '../services/appointment_service.dart';
import '../model/doctors_model.dart';

class AppointmentController extends GetxController {
  var isLoading = false.obs; // Loading for data fetching
  var dataList = <AppointmentModel>[].obs; // list of all fetched data
  var isError = false.obs;
  var dataMap = DoctorsModel().obs; // list of all fetched data

  void getData() async {
    isLoading(true);
    try {
      final getDataList = await AppointmentService.getData();

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
