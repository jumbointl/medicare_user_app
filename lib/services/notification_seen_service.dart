import 'package:shared_preferences/shared_preferences.dart';
import '../utilities/api_content.dart';
import '../utilities/sharedpreference_constants.dart';
import '../helpers/get_req_helper.dart';
import '../model/notification_senn_model.dart';

class NotificationSeenService{

  static const  usersNotificationSeenStatusUrl=   ApiContents.usersNotificationSeenStatusUrl;

  static NotificationSeenModel dataFromJsonById(data) {
    return NotificationSeenModel.fromJson(data);
  }
  static Future <NotificationSeenModel?> getDataById()async {
    SharedPreferences preferences=await SharedPreferences.getInstance();
    final uid=preferences.getString(SharedPreferencesConstants.uid)??"-1";
    final res=await GetService.getReq("$usersNotificationSeenStatusUrl/$uid");
    if(res==null) {
      return null;
    } else {
      NotificationSeenModel dataModel = dataFromJsonById(res);
      return dataModel;
    }
  }

}