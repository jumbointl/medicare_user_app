import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user_model.dart';
import '../services/user_service.dart';
import '../utilities/sharedpreference_constants.dart';

class UserController extends GetxController {
  var isLoading = false.obs;
  var usersData = UserModel().obs;
  var isError = false.obs;
  // Bump tras login exitoso (en login_page._handleSuccessLogin). HomePage
  // suscribe via ever() y dispara re-fetch de todo (departments, doctors,
  // clinics, banner, blog, notif, config). Sin esto, tras logout→login
  // los tabs quedan con estado vacío hasta que el user refresca a mano.
  var loginEpoch = 0.obs;

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