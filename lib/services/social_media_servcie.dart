import '../model/social_media_model.dart';
import '../helpers/get_req_helper.dart';
import '../utilities/api_content.dart';

class SocialMediaService {


  static const getByUrl = ApiContents.getSocialMediaApiUrl;


  static List<SocialMediaModel> dataFromJson(jsonDecodedData) {
    return List<SocialMediaModel>.from(
        jsonDecodedData.map((item) => SocialMediaModel.fromJson(item)));
  }

  static Future <List<SocialMediaModel>?> getData() async {
    final res = await GetService.getReq(getByUrl);
    if (res == null) {
      return null;
    } else {
      List<SocialMediaModel> dataModelList = dataFromJson(res);
      return dataModelList;
    }
  }
}