import 'package:get/get.dart';
import '../model/booked_time_slot_mdel.dart';
import '../services/booked_time_slot_service.dart';

class BookedTimeSlotsController extends GetxController {
  var isLoading = false.obs; // Loading for data fetching
  var dataList = <BookedTimeSlotsModel>[].obs; // list of all fetched data
  var isError = false.obs;

  void getData(String doctId,String date,String slotType) async {
    isLoading(true);
    try {
      final getDataList = await BookedTimeSlotsService.getData(doctId: doctId,date: date,type: slotType);

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
