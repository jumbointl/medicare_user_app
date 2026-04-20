import 'package:get/get.dart';
import '../model/prescription_model.dart';
import '../services/prescription_service.dart';

class PrescriptionController extends GetxController {
  var isLoading = false.obs; // Loading for data fetching
  var dataList = <PrescriptionModel>[].obs; // list of all fetched data
  var isError = false.obs;


  void getData({required String appointmentId}) async {
    isLoading(true);
    try {
      final getDataList = await PrescriptionService.getData(appointmentId:appointmentId);

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
  void getDataBYUid() async {
    isLoading(true);
    try {
      final getDataList = await PrescriptionService.getDataByUid();

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
