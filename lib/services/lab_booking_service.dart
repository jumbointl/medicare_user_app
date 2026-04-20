import 'package:flutter/foundation.dart';
import 'package:medicare_user_app/model/lab_cart_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/lab_booking_model.dart';
import '../helpers/get_req_helper.dart';
import '../helpers/post_req_helper.dart';
import '../utilities/api_content.dart';
import '../utilities/sharedpreference_constants.dart';

class LabBookingService{

  static const  labBookingGetUrl=   ApiContents.labBookingGetUrl;
  static const  labBooingUrl=   ApiContents.labBooingUrl;


  static List<LabBookingModel> dataFromJson (jsonDecodedData){
    return List<LabBookingModel>.from(jsonDecodedData.map((item)=>LabBookingModel.fromJson(item)));
  }

  static Future <List<LabBookingModel>?> getData()async {
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"-1";
    final body={
      "user_id":uid
    };
    try{    final res=await GetService.getReqWithBodY(labBookingGetUrl,body);
    if(res==null) {
      return null;
    } else {
      List<LabBookingModel> dataModelList = dataFromJson(res);
      return dataModelList;
    }}catch(e){if (kDebugMode) {
      print(e);
    }}
    return null;
  }
  static Future <LabBookingModel?> getDataById({required String? appId})async {
    final res=await GetService.getReq("$labBookingGetUrl/${appId??""}");
    if(res==null) {
      return null;
    } else {
      LabBookingModel dataModel = LabBookingModel.fromJson(res);
      return dataModel;
    }
  }
  static Future addBooking(
      {
        required String pathId,
        required String patientId,
        required String status,
        required String date,
        required String paymentStatus,
        required String totalAmount,
        required String invoiceDescription,
        required String paymentMethod,
        required String paymentTransactionId,
        required String isWalletTxn,
        required String familyMemberId,
        required String couponId,
        required String couponValue,
        required String couponTitle,
        required String couponOffAmount,
        required List<LabCartModel> labTestCartData,
      }
      )async{
    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"-1";
    final labTestIds=labTestCartData.map((e) => {
      "lab_id": e.labTestId,
      "test_title": e.title,
      "total_amount": e.amount,
      "fee": e.amount,
    }).toList();
    Map body=
    {
      "patient_id": patientId,
      "status": status,
      "date": date,
      "pathology_id": pathId,
      "invoice_description": invoiceDescription,
      "payment_method": paymentMethod,
      "user_id": uid,
      "payment_transaction_id": paymentTransactionId,
      "is_wallet_txn": isWalletTxn,
      "payment_status": paymentStatus,
      "coupon_id": couponId,
      "coupon_title": couponTitle,
      "coupon_value": couponValue,
      "coupon_off_amount": couponOffAmount,
      "source": "Android App",
      "total_amount": totalAmount,
      "family_member_id": familyMemberId,
      "lab_test_ids":labTestIds
    };
    final res=await PostService.postReq(labBooingUrl, body);
    return res;
  }
}