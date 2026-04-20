import 'package:get/get.dart';
import '../services/patient_files_service.dart';

class PatientFileController extends GetxController{
  var isLoading=false.obs; //Loading for data fetching
  var dataList= [].obs; //Object of blog post model
  var isError=false.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
  void getData(String searchQ)async{
    isLoading(true);
    try{
      final getDataList=await PatientFilesService.getData(searchQ); //Get all blog post list details from the blog post service page
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
