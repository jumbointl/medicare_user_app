import '../helpers/get_req_helper.dart';
import '../model/web_page_model.dart';
import '../utilities/api_content.dart';

class WebPageService {

  static const getUrl = ApiContents.getWebApiUrl;

  static Future <WebPageModel?> getDataById({required String? id})async {


    final res=await GetService.getReq("$getUrl/$id");


    if(res==null) {

      return null;
    } else {
      WebPageModel dataModel = WebPageModel.fromJson(res);
      return dataModel;
    }
  }
}
