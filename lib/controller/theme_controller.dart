import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utilities/sharedpreference_constants.dart';

class ThemeController extends GetxController {
  final SharedPreferences sharedPreferences;
  ThemeController({required this.sharedPreferences}) {
    _loadCurrentTheme();
  }
  bool _darkTheme = false;
  bool get darkTheme => _darkTheme;

  void toggleTheme() {
    _darkTheme = !_darkTheme;
      sharedPreferences.setBool(SharedPreferencesConstants.theme, _darkTheme);
    sharedPreferences.setBool(SharedPreferencesConstants.theme, _darkTheme);
    update();
  }

  void _loadCurrentTheme() async {
    _darkTheme = sharedPreferences.getBool(SharedPreferencesConstants.theme) ?? false;
    update();
  }
}
