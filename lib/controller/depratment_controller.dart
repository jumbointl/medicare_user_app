import 'package:get/get.dart';
import '../model/department_model.dart';
import '../services/department_service.dart';

class DepartmentController extends GetxController {
  var isLoading = false.obs; // Loading for data fetching
  var dataList = <DepartmentModel>[].obs; // list of all fetched data
  var isError = false.obs;


  void getData() async {
    isLoading(true);
    try {
      final getDataList = await DepartmentService.getData();

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
