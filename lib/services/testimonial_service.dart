import '../model/testimonial_model.dart';
import '../helpers/get_req_helper.dart';
import '../utilities/api_content.dart';


class TestimonialsService {


  static const getByUrl = ApiContents.getTestimonialApiUrl;


  static List<TestimonialModel> dataFromJson(jsonDecodedData) {
    return List<TestimonialModel>.from(
        jsonDecodedData.map((item) => TestimonialModel.fromJson(item)));
  }

  static Future <List<TestimonialModel>?> getData(String clinicId,String pathId) async {
    final body={
      "clinic_id":clinicId,
      "path_id":pathId
    };

    final res = await GetService.getReqWithBodY(getByUrl,body);
    if (res == null) {
      return null;
    } else {
      List<TestimonialModel> dataModelList = dataFromJson(res);
      return dataModelList;
    }
  }
}