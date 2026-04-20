import '../helpers/get_req_helper.dart';
import '../model/payment_gateway_model.dart';
import '../utilities/api_content.dart';

class PaymentGatewayService{

  static const  getPaymentGatewayActiveUrl=   ApiContents.getPaymentGatewayActiveUrl;

  static PaymentGatewayModel dataFromJsonById(data) {
    return PaymentGatewayModel.fromJson(data);
  }
  static Future <PaymentGatewayModel?> getActivePaymentGateway()async {

    final res=await GetService.getReq(getPaymentGatewayActiveUrl);
    if(res==null) {
      return null;
    } else {
      PaymentGatewayModel dataModel = dataFromJsonById(res);
      return dataModel;
    }
  }

}