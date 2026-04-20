import '../helpers/post_req_helper.dart';
import '../utilities/api_content.dart';
import '../utilities/sharedpreference_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreOrderService{

  static const  addUrl=   ApiContents.preOrderUrl;
  static const  updatePaymentUrl=   ApiContents.updatePaymentUrl;
  static Future addData({
    required String type,
    required Map payLoad,
    required String payAmount,
  })async{
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"";
    Map body={
      "type":type,
      "payload":payLoad,
      "user_id":uid,
      "pay_amount":payAmount
    };
    final res=await PostService.postReq(addUrl, body);

    return res;
  }
  static Future addPayment({
    required String preOrderId,
    required String txnId,
  })async{
    Map body={
      "payment_transaction_id":txnId,
      "pre_order_id":preOrderId
    };
    final res=await PostService.postReq(updatePaymentUrl, body);

    return res;
  }
}