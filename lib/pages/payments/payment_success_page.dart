import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utilities/image_constants.dart';
import '../../widget/app_bar_widget.dart';
import '../../widget/loading_Indicator_widget.dart';
import '../../widget/toast_message.dart';
import 'dart:async' show Timer;

class PaymentSuccessPage extends StatefulWidget {
  final Function? onSuccess;
  final String? txnId;
  final String? successMessage;
  const PaymentSuccessPage({super.key,this.onSuccess,
    this.txnId,
    this.successMessage
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  bool _isLoading =true;
  bool paymentSuccess=false;
  int counterValue=8;
  Timer? _timer;
  @override
  void initState() {
    // TODO: implement initState
    getAndSetData();
    super.initState();
  }


  @override
  void dispose() {
    // TODO: implement dispose

    _timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isLoading||paymentSuccess?false:true,
      child: Scaffold(
        appBar: IAppBar.commonAppBar(title: "payment".tr),
        body:_isLoading?const ILoadingIndicatorWidget(): _buildBody(),
      ),
    );
  }

  void getAndSetData() async{
    setState(() {
      _isLoading=true;
    });
    setState(() {
      paymentSuccess=true;
      _isLoading=false;
    });
    _startTimer(widget.txnId??"--");
    IToastMsg.showMessage(widget.successMessage??"success".tr);

    // final res=await PreOrderService.addPayment(preOrderId: widget.preOrderId??"", txnId: widget.txnId??"");
    // if(res!=null){
    //   IToastMsg.showMessage(widget.successMessage??"success".tr);
    // }
    // else{
    //   IToastMsg.showMessage('failed_to_create_order'.tr);
    // }

  }
  _buildBody()
  {
    return  Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(ImageConstants.paymentSuccessImageBox,
            height: 200,
          ),
          Text("payment_success".tr,
            style:const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 18
            ),),
          const SizedBox(height: 10),
          Text("payment_return_id_desc".trParams({"id":widget.txnId??""}),
            textAlign: TextAlign.center,
            style:const  TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500
            ),),
          const SizedBox(height: 10),
          Text("seconds_value".trParams({"value": "$counterValue"}),
            style:const  TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500
            ),)
        ],
      ),
    );
  }

  void _startTimer(String paymentId) {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        counterValue--;
      });
      if(counterValue==0){
        _stopTimer();
        Get.back();
        if( widget.onSuccess!=null)
        {
          widget.onSuccess!();
        }
      }
    });

  }
  void _stopTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
  }
}
