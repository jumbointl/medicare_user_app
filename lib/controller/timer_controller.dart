import 'package:get/get.dart';

class TimerController extends GetxController{
  var timeSecond= 60.obs;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
setValue(int value){
  timeSecond.value=value;
}


}
