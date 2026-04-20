import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user_model.dart';
import '../services/user_service.dart';
import '../utilities/sharedpreference_constants.dart';

class UserController extends GetxController {
  var isLoading = false.obs;
  var usersData = UserModel().obs;
  var isError = false.obs;

  Future<void> getData() async {
    isLoading(true);

    try {
      final preferences = await SharedPreferences.getInstance();
      final uid =
          preferences.getString(SharedPreferencesConstants.uid) ?? '';

      if (uid.isEmpty || uid == '-1') {
        isError(true);
        return;
      }

      final getDataList = await UserService.getDataById();

      if (getDataList != null) {
        isError(false);
        usersData.value = getDataList;
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