import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/post_req_helper.dart';
import '../utilities/api_content.dart';
import '../utilities/sharedpreference_constants.dart';

class AiChatService {

  static const String chatUrl = ApiContents.aiChatUrl;

  /// Send message to AI Chat API
  static Future<Map<String, dynamic>?> sendMessage({
    required String message,
    String? sessionId,
  }) async {

    SharedPreferences preferences = await SharedPreferences.getInstance();
    final uid = preferences.getString(SharedPreferencesConstants.uid) ?? "";
    final cityId = preferences.getString("city_id") ?? "";

    Map body = {
      "message": message,
      "city_id": cityId,
      "session_id": sessionId,
      "user_id": uid,
      "city_id"
      "source": Platform.isAndroid
          ? "Android App"
          : Platform.isIOS
          ? "Ios App"
          : ""
    };

    final res = await PostService.postReq(chatUrl, body);

    return res;
  }
}
