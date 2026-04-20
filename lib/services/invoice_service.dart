import '../model/invoice_model.dart';
import '../helpers/get_req_helper.dart';
import '../utilities/api_content.dart';

class InvoiceService{
  static const  getUrl=   ApiContents.getInvoiceUrl;
  static const  getLabUrl=   ApiContents.getInvoiceByLabAppIdUrl;

  static List<InvoiceModel> dataFromJson (jsonDecodedData){

    return List<InvoiceModel>.from(jsonDecodedData.map((item)=>InvoiceModel.fromJson(item)));
  }

  static Future <InvoiceModel?> getDataByAppLabId({required String? appId})async {
    final res=await GetService.getReq("$getLabUrl/${appId??""}");
    if(res==null) {
      return null;
    } else {
      InvoiceModel dataModel = InvoiceModel.fromJson(res);
      return dataModel;
    }
  }

  static Future <List<InvoiceModel>?> getDataByAppId(appId)async {

    final body={
      "appointment_id":appId
    };
    final res=await GetService.getReqWithBodY(getUrl,body);
    if(res==null) {
      return null;
    } else {
      List<InvoiceModel> dataModelList = dataFromJson(res);
      return dataModelList;
    }
  }
}