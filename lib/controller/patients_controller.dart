import 'package:get/get.dart';
import '../model/patient_model.dart';
import '../services/patient_service.dart';

class PatientsController extends GetxController {
  var isLoading = false.obs; // Loading for data fetching
  var dataList = <PatientModel>[].obs; // list of all fetched data
  var isError = false.obs;


  void getData() async {
    isLoading(true);
    try {
      final getDataList = await PatientsService.getDataByUID();

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
