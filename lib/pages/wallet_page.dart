import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:medicare_user_app/helpers/currency_formatter_helper.dart';
import 'package:medicare_user_app/pages/payments/payment_page.dart';
import 'package:medicare_user_app/services/init_payment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/payment_gateway_service.dart';
import '../services/pre_order_service.dart';
import '../services/txn_service.dart';
import '../utilities/image_constants.dart';
import '../controller/txn_controller.dart';
import '../controller/user_controller.dart';
import '../helpers/date_time_helper.dart';
import '../helpers/theme_helper.dart';
import '../model/txn_model.dart';
import '../services/user_service.dart';
import '../utilities/colors_constant.dart';
import '../utilities/sharedpreference_constants.dart';
import '../widget/app_bar_widget.dart';
import '../widget/button_widget.dart';
import '../widget/loading_Indicator_widget.dart';
import '../widget/toast_message.dart';
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final ScrollController _scrollController=ScrollController();
  final  TextEditingController _amountController=TextEditingController();
  final TxnController txnController=Get.put(TxnController());
  String? activePaymentGatewayName;
  String email="";
  UserController userController=Get.find(tag: "user");
  bool _paymentLoading = false;
  List <double> amountList=[250,500,1000,1500,2000];
  bool _isLoading=false;
  final GlobalKey<FormState> _formKey3 =  GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {

    // TODO: implement dispose
    txnController.getData();
    super.dispose();
  }
  @override
  void initState() {
    // TODO: implement initState
    txnController.getData();
    getAndSetData();
    super.initState();
  }
  void getAndSetData() async{
    setState(() {
      _isLoading=true;
    });
    final res=await UserService.getDataById();
    if(res!=null){
      email=res.email??"";
    }
    final activePG=await PaymentGatewayService.getActivePaymentGateway();
    if(activePG!=null){
      activePaymentGatewayName=activePG.title;
    }
    setState(() {
      _isLoading=false;
    });

  }
  successPayment()async {
    IToastMsg.showMessage("success".tr);
      txnController.getData();
      userController.getData();
    setState(() {
      _paymentLoading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_paymentLoading,
      child: Scaffold(
        backgroundColor: ColorResources.bgColor,
       appBar: IAppBar.commonAppBar(title: "Wallet".tr),
        body: _isLoading?const ILoadingIndicatorWidget():_paymentLoading
            ? const ILoadingIndicatorWidget(): _buildBody(),
      ),
    );
  }

  _buildBody() {
    return ListView(
      controller: _scrollController,
      padding:const EdgeInsets.all(8),
      children: [
        Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            color: ColorResources.secondaryColor,
          ),
          height: 200,
          child: Stack(
            children: [
              Positioned(
                  top:0,
                  right:0,
                  bottom:0,
                  left:0,
                  child: Image.asset(ImageConstants.containerBgImage)),
              Center(child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children:  [
                   Text("current_balance".tr,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400
                    ),),
                  FutureBuilder(
                      future: UserService.getDataById(),
                      builder: (context,AsyncSnapshot snapshot) {
                        return RichText(
                          text:  TextSpan(
                            text: CurrencyFormatterHelper.format(snapshot.hasData?snapshot.data?.walletAmount??0:0),
                            style:  const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600
                            ),
                            children: const <TextSpan>[
                              TextSpan(text: '',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400
                                  )
                              ),

                            ],
                          ),
                        );
                      }
                  ),
                  const SizedBox(height: 20),
                  SmallButtonsWidget(
                      rounderRadius: 20,
                      color: ColorResources.greenFontColor,
                      width: 200,
                      title: "add_money_btn".tr, onPressed: (){
                    _openBottomSheet();

                  })
                ],
              )
              )
            ],
          ),
        ),
         ListTile(title: Text("transaction_history".tr,
          style:const  TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16
          ),
        ),),
        Obx(() {
          if (!txnController.isError.value) { // if no any error
            if (txnController.isLoading.value) {
              return const IVerticalListLongLoadingWidget();
            } else if (txnController.dataList.isEmpty) {
              return  Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("no_transaction_found".tr),
              );
            } else {
              return
                _buildConsultationList(txnController.dataList);
            }
          }else {
            return Container();
          } //Error svg
        }
        )

      ],
    );
  }

  _buildConsultationList(List dataList) {

    return ListView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        itemCount:dataList.length,
        itemBuilder: (context,index){
          TxnModel txnModel=dataList[index];
          return  Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
            elevation: .1,
            child: ExpansionTile(
              title:
              Text(CurrencyFormatterHelper.format(txnModel.amount??0),
                    style:  TextStyle(
                      color:  txnModel.type=="Credited"?Colors.green:txnModel.type=="Debited"?Colors.red:null,
                        fontSize: 14,
                        fontWeight: FontWeight.w600
                    ),
                  ),

              trailing:   Text(txnModel.type??"--".tr,
                style:   TextStyle(
                    color: txnModel.type=="Credited"?Colors.green:txnModel.type=="Debited"?Colors.red:null,
                    fontSize: 14,
                    fontWeight: FontWeight.w400
                ),
              ),
              subtitle:  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  txnModel.notes==null||txnModel.notes==""?Container():  Text(txnModel.notes??"",
                    style: const TextStyle(
                        color: ColorResources.secondaryFontColor ,
                        fontSize: 12,
                        fontWeight: FontWeight.w400
                    ),
                  )   ,
                  Text(DateTimeHelper.getDataFormatWithTime(txnModel.createdAt??""),
                    style: const TextStyle(
                        color: ColorResources.secondaryFontColor ,
                        fontSize: 12,
                        fontWeight: FontWeight.w400
                    ),
                  ),
                ],
              ),
           //   notes
              leading:  txnModel.type=="Credited"?
              const CircleAvatar(
                  backgroundColor: Colors.green,
                  radius: 10,
                  child: Icon(Icons.add,
                    color: Colors.white,
                    size: 12,
                  )
              ):txnModel.type=="Debited"?
              const CircleAvatar(
                backgroundColor: Colors.redAccent,
                radius: 10,
                child: Icon(Icons.remove,
                  color: Colors.white,
                  size: 12,
                ),
              ): Container(),
              children: [
                const SizedBox(height: 3),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("transaction_id".trParams(
                          {"id": "${txnModel.id ?? "--"}"}),
                        textAlign: TextAlign.start,
                        style: const TextStyle(
                            color: ColorResources.secondaryFontColor ,
                            fontSize: 14,
                            fontWeight: FontWeight.w500
                        ),),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
              ],
            ),
          );

        });
  }
  _openBottomSheet(){
    final formKey = GlobalKey<FormState>();
    return
      showModalBottomSheet(
        isScrollControlled: true,
        shape:  const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20.0),
            topLeft: Radius.circular(20.0),
          ),
        ),
        context: context,
        builder: (BuildContext context) {
          return Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                       Text("add_money".tr,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600
                        ),),
                      IconButton(
                          onPressed: (){
                            Get.back();
                          }, icon: const Icon(Icons.close)),
                    ],
                  ),
                  Form(
                    key: formKey,
                    child: Container(
                      decoration: ThemeHelper().inputBoxDecorationShaddow(),
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                          // FilteringTextInputFormatter.allow(
                          //     RegExp(r'^\d+\.?\d{0,2}$')), // Limit to two decimal places
                        ],
                        validator: ( item){
                          if(item!.isEmpty){
                            return "enter_valid_amount".tr;
                          }
                          else if(item.isNotEmpty){
                            if(double.parse(item)<=0||double.parse(item)>5000){
                              return "amt_des".trParams({"am_1":CurrencyFormatterHelper.format(1),
                              "am_2":CurrencyFormatterHelper.format(5000)
                              });
                            }else    if(double.parse(item)>0){
                              return null;
                            }
                          }
                          return null;
                        },
                        controller: _amountController,
                        decoration: ThemeHelper().textInputDecoration('amount'.tr),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 2,      // horizontal gap
                    runSpacing: 2,  // vertical gap
                    children: List.generate(amountList.length, (index) {
                      return GestureDetector(
                        onTap: () {
                          _amountController.text = amountList[index].toInt().toString();
                        },
                        child: Card(
                          color: Colors.grey.shade100,
                          elevation: .1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              CurrencyFormatterHelper.format(amountList[index]),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: ColorResources.primaryFontColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  SmallButtonsWidget(title: "process".tr, onPressed: (){
                    if(formKey.currentState!.validate()){
                      Get.back();
                      if(activePaymentGatewayName=="Paystack"&&email==""){
                        _openBottomSheetEmail();
                      }
                      else{
                        createOrder();
                      }
                    }

                  })

                ],
              ),
            ),
          );
        },
      ).whenComplete(() {

      });
  }

  _openBottomSheetEmail(){
    return
      showModalBottomSheet(
        isScrollControlled: true,
        shape:  const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20.0),
            topLeft: Radius.circular(20.0),
          ),
        ),
        context: context,
        builder: (BuildContext context) {
          return Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row( mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("email".tr,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600
                        ),),
                      IconButton(
                          onPressed: (){
                            Get.back();
                          }, icon: const Icon(Icons.close)),
                    ],
                  ),
                  Form(
                    key: _formKey3,
                    child: Container(
                      decoration: ThemeHelper().inputBoxDecorationShaddow(),
                      child: TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "enter_a_valid_email_address".tr;
                          }
                          // Simple email pattern check
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return "enter_a_valid_email_address".tr;
                          }
                          return null;
                        },
                        controller: _emailController, // Consider renaming to _emailController
                        decoration: ThemeHelper().textInputDecoration('email'.tr),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SmallButtonsWidget(title: "next".tr, onPressed: (){
                    Get.back();
                    if(_formKey3.currentState!.validate()){
                      email =_emailController.text;
                      UserService.updateProfile(fName:"" , lName: "", gender: "", dob: "", email: email);
                      createOrder();
                    }

                  })

                ],
              ),
            ),
          );
        },
      ).whenComplete(() {

      });
  }

  void createOrder() async{
    setState(() {
      _isLoading=true;
    });

    SharedPreferences preferences=await  SharedPreferences.getInstance();
    final uid= preferences.getString(SharedPreferencesConstants.uid)??"-1";

    Map payLoad={
      "amount":_amountController.text,
      "user_id":uid,
      "payment_method":"Online" ,//1=credit 2=debit
      "transaction_type":"Credited",
      "description":"Amount credited to user wallet",
      "email":email
    };

    final preOrder=await PreOrderService.addData(type: "Wallet", payLoad: payLoad,
        payAmount: _amountController.text
    );
    if(preOrder==null){
      setState(() {
        _isLoading=false;
      });
      return;
    }
    final preOrderId=preOrder['id'];
    if(preOrderId==null){
      setState(() {
        _isLoading=false;
      });
      return;
    }
    final res=await InitPaymentService.initOrder(preOrderId: preOrderId.toString());
    if(res!=null){
      if(kDebugMode){
        print("Payment Url${res['payment_url']}");
      }
      final paymentUrl=res['payment_url'];
      final transactionId=res['transaction_id']??"";
      if(paymentUrl!=null||paymentUrl!=""){
        Get.to(()=>PaymentWebView(
          onSuccess: successPayment,
          transactionId:transactionId ,
          paymentUrl: paymentUrl, successMessage: "add_money_to_you_wallet_successfully".tr,));

      }else{
        IToastMsg.showMessage("something_went_wrong".tr);
      }
    }
    setState(() {
      _isLoading=false;
    });
  }

  void handleSuccessData(String paymentId) async{
    setState(() {
      _isLoading=true;
    });
    final res=await TxnService.addUTxn(paymentId, _amountController.text, "Credited", "Amount credited to user wallet");
    setState(() {
      _isLoading=false;
    });
    if(res!=null){
   // IToastMsg.showMessage("success".tr);
    successPayment();
    }
  }
}


