import 'package:get/get.dart';
import 'package:medicare_user_app/model/lab_cart_model.dart';
import 'package:medicare_user_app/services/lab_cart_service.dart';
import '../model/doctors_model.dart';

class LabCartController extends GetxController {
  var isLoading = false.obs; // Loading for data fetching
  var dataList = <LabCartModel>[].obs; // list of all fetched data
  var isError = false.obs;
  var dataMap = DoctorsModel().obs; // list of all fetched data

  void getData(String labId) async {
    isLoading(true);
    try {
      final getDataList = await LabCartService.getData(labId);

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
