import 'package:get/get.dart';
import '../model/clinic_model.dart';
import '../services/clinic_service.dart';



class ClinicController extends GetxController {
  var isLoading = false.obs; // Loading for data fetching
  var dataList = <ClinicModel>[].obs; // list of all fetched data
  var isError = false.obs;
  var dataMap = ClinicModel().obs; // list of all fetched data

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
  }

  void getData( String start, String end,String cityId,) async {
    isLoading(true);
    try {
      final getDataList = await ClinicService.getData(start:start,end:end,cityId:cityId );

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
