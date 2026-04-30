import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import '../../utilities/colors_constant.dart';
import '../../widget/toast_message.dart';
import 'payment_success_page.dart';

class PaymentWebView extends StatefulWidget {
  final String paymentUrl;
  final String? successMessage;
  final String? transactionId;
  final Function? onSuccess;

   const PaymentWebView({super.key, required this.paymentUrl,required this.successMessage,required this.onSuccess, required this.transactionId});

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;

            /// ✅ PAYMENT SUCCESS
            if (url.contains('/payment-success')) {
              Get.back();
              Get.to(()=>PaymentSuccessPage(
                txnId: widget.transactionId,
                onSuccess: widget.onSuccess,
                successMessage: widget.successMessage,
              ));
              return NavigationDecision.prevent;
            }

            /// ❌ PAYMENT FAILED
            if (url.contains('/payment-failed')) {
              IToastMsg.showMessage("payment_error".tr);
              Get.back();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
          elevation: 0,
          backgroundColor:ColorResources.appBarColor,
          title:  Text('payment'.tr,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400
            ),
          ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
