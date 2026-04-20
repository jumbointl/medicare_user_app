import 'package:get/get.dart';
import '../services/testimonial_service.dart';

class TestimonialController extends GetxController{
  var isLoading=false.obs; //Loading for data fetching
  var dataList= [].obs; //Object of blog post model
  var isError=false.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getData("");
    super.onInit();
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
  void getData(clinicId)async{
    isLoading(true);
    try{
      final getDataList=await TestimonialsService.getData(clinicId,""); //Get all blog post list details from the blog post service page
      if (getDataList!=null) {
        isLoading(false);
        dataList.value=getDataList;
      } else {
        isError(true);
      } // If its error
    }
    catch(e){
      isError(true);  // If its error
    }
    finally{
      isLoading(false); // Run try block with error ot without error
    }

  }


}
