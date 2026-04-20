import 'package:shared_preferences/shared_preferences.dart';
import '../model/txn_model.dart';
import '../utilities/api_content.dart';
import '../utilities/sharedpreference_constants.dart';
import '../helpers/get_req_helper.dart';
import '../helpers/post_req_helper.dart';

class TxnService{

  static const  addUrl=   ApiContents.addWalletMoneyUrl;
  static const  getWalletByUidUrl=   ApiContents.getWalletByUidUrl;


  static Future addUTxn(String paymentId,String amount,String type,String description)async{
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"";
    Map body={
      "user_id":uid,
      "amount":amount,
      "payment_transaction_id":paymentId,
      "payment_method":"Online" ,//1=credit 2=debit
      "transaction_type":type,
      "description":description
    };
    final res=await PostService.postReq(addUrl, body);
    return res;
  }

  static List<TxnModel> dataFromJson (jsonDecodedData){

    return List<TxnModel>.from(jsonDecodedData.map((item)=>TxnModel.fromJson(item)));
  }
  static Future <List<TxnModel>?> getDataWalletTxnByUId()async {
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"";
    final body={
      "user_id":uid
    };
    final res=await GetService.getReqWithBodY(getWalletByUidUrl,body);
    if(res==null) {
      return null;
    } else {

      List<TxnModel> dataModelList = dataFromJson(res);

      return dataModelList;
    }
  }

}