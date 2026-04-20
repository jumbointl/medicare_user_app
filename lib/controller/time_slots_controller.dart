import 'package:get/get.dart';
import '../model/time_slots_model.dart';
import '../services/time_slots_service.dart';

class TimeSlotsController extends GetxController {
  var isLoading = false.obs; // Loading for data fetching
  var dataList = <TimeSlotsModel>[].obs; // list of all fetched data

  var isError = false.obs;


  void getData(String doctId,String day,String slotType) async {
    isLoading(true);
    try {
      final getDataList = await TimeSlotsService.getData(doctId: doctId,day: day,slotType: slotType);

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
