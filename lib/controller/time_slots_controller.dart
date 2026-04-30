import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/time_slots_model.dart';
import '../services/time_slots_service.dart';
import '../utilities/clinic_config.dart';
import '../utilities/sharedpreference_constants.dart';

class TimeSlotsController extends GetxController {
  var isLoading = false.obs; // Loading for data fetching
  var dataList = <TimeSlotsModel>[].obs; // list of all fetched data

  var isError = false.obs;


  void getData(String doctId,String day,String slotType,{String? clinicId}) async {
    isLoading(true);
    try {
      String? resolvedClinicId = clinicId;
      if (resolvedClinicId == null || resolvedClinicId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        resolvedClinicId = prefs.getString(SharedPreferencesConstants.clinicId);
      }
      // Fallback to build-time dart-define VITE_CLINIC_ID / VITE_CLINIC_IDS.
      if (resolvedClinicId == null || resolvedClinicId.isEmpty) {
        final defId = ClinicConfig.defaultClinicId;
        if (defId != null) {
          resolvedClinicId = defId.toString();
        } else if (ClinicConfig.allowedClinicIds.isNotEmpty) {
          resolvedClinicId = ClinicConfig.allowedClinicIds.first.toString();
        }
      }
      final getDataList = await TimeSlotsService.getData(doctId: doctId,day: day,slotType: slotType,clinicId: resolvedClinicId);

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
