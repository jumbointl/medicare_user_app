import 'package:get/get.dart';

class NotificationDotController extends GetxController{
  var isShow=false.obs; //Loading for data fetching

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
 setDotStatus(bool status){
    isShow(status);
 }
}
