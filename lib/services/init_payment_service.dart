import '../utilities/api_content.dart';
import '../helpers/post_req_helper.dart';

class InitPaymentService{


  static const  initPaymentUrl=   ApiContents.initPaymentUrl;

  static Future initOrder(
      {
        required String  preOrderId,
      }
      )async{

    Map body={
      "pre_order_id":preOrderId,
    };
    final res=await PostService.postReq(initPaymentUrl, body);
    return res;
  }
}