
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:udemy_core/udemy_core.dart';

import 'medicare_client_payment_gateway_controller.dart';

class MedicareClientPaymentGatewayPage extends StatelessWidget {
  MedicareClientPaymentGatewayPage({super.key});

  final MedicareClientPaymentGatewayController con =
  Get.put(MedicareClientPaymentGatewayController());

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[PG PAGE] build -> '
          'uiStatus=${con.uiStatus.value.name}, '
          'isBusy=${con.isBusy.value}, '
          'isSuccess=${con.isSuccess}, '
          'isPending=${con.isPending}, '
          'isCanceled=${con.isCanceled}, '
          'isFailed=${con.isFailed}, '
          'webViewController=${con.webViewController != null}',
    );

    return GetBuilder<MedicareClientPaymentGatewayController>(
      builder: (_) => PopScope(
        canPop: con.canExitNow,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          final bool isTerminal =
              con.isSuccess || con.isCanceled || con.isFailed;

          if (!isTerminal) {
            final bool? exitAnyway = await Get.dialog<bool>(
              AlertDialog(
                title: Text("paymentGateway.cancelPayment".tr),
                content: Text("paymentGateway.cancelPaymentConfirm".tr),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: Text("paymentGateway.no".tr),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: true),
                    child: Text("paymentGateway.yesExit".tr),
                  ),
                ],
              ),
              barrierDismissible: false,
            );

            if (exitAnyway == true) {
              await con.exitGatewayByClient();
            } else {
              Get.snackbar(
                "paymentGateway.title".tr,
                "paymentGateway.checkingPaymentStatus".tr,
              );
            }
            return;
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: MemorySol.COLOR_IS_DEBIT_TRANSACTION,
            iconTheme: const IconThemeData(color: Colors.black),
            title: Text(
              "paymentGateway.title".tr,
              style: const TextStyle(color: Colors.black),
            ),
            automaticallyImplyLeading: true,
          ),
          body: Column(
            children: [
              _statusHeader(),
              if (con.showLinearProgress.value)
                LinearProgressIndicator(
                  value: con.webProgressValue,
                  minHeight: 3,
                ),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
          bottomNavigationBar: SafeBottomBar(child: _bottomBar()),
        ),
      ),
    );
  }

  Widget _statusHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      child: Text(
        _headerMessage(),
        style: const TextStyle(fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _headerMessage() {
    if (con.isSuccess) {
      return "paymentGateway.approved".tr;
    }
    if (con.isCanceled) {
      return "paymentGateway.canceled".tr;
    }
    if (con.isPending) {
      return "paymentGateway.verifying".tr;
    }
    if (con.isFailed) {
      return "paymentGateway.failed".tr;
    }

    return con.statusMessage.value.isNotEmpty
        ? con.statusMessage.value
        : "paymentGateway.completeToContinue".tr;
  }

  Widget _buildBody() {
    debugPrint(
      '[PG PAGE] _buildBody -> '
          'webViewController=${con.webViewController != null}, '
          'status=${con.uiStatus.value.name}',
    );

    if (con.webViewController == null && !con.isFailed) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (con.isSuccess || con.isPending || con.isCanceled || con.isFailed) {
      return _resultView();
    }

    return WebViewWidget(controller: con.webViewController!);
  }

  Widget _resultView() {
    IconData icon = Icons.info_outline;
    String title = "paymentGateway.paymentStatusTitle".tr;
    String message = con.statusMessage.value;

    if (con.isSuccess) {
      icon = Icons.check_circle_outline;
      title = "paymentGateway.approved".tr;
      message = message.isNotEmpty
          ? message
          : "paymentGateway.confirmedCorrectly".tr;
    } else if (con.isPending) {
      icon = Icons.hourglass_bottom;
      title = "paymentGateway.verifying".tr;
      message = message.isNotEmpty
          ? message
          : "paymentGateway.verifyingStatus".tr;
    } else if (con.isCanceled) {
      icon = Icons.cancel_outlined;
      title = "paymentGateway.canceled".tr;
      message = message.isNotEmpty
          ? message
          : "paymentGateway.userCanceled".tr;
    } else if (con.isFailed) {
      icon = Icons.error_outline;
      title = "paymentGateway.failed".tr;
      message = message.isNotEmpty
          ? message
          : "paymentGateway.couldNotConfirm".tr;
    }

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 72),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          runSpacing: 8,
          children: [
            if (con.isBusy.value)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: CircularProgressIndicator(),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan[800],
                  foregroundColor: Colors.white,
                ),
                onPressed: _bottomButtonPressed,
                child: Text(_bottomButtonText()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _bottomButtonPressed() async {
    final bool isTerminal = con.isSuccess || con.isCanceled || con.isFailed;

    if (!isTerminal) {
      final bool? exitAnyway = await Get.dialog<bool>(
        AlertDialog(
          title: Text("paymentGateway.cancelPayment".tr),
          content: Text("paymentGateway.cancelPaymentConfirm".tr),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text("paymentGateway.no".tr),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text("paymentGateway.yesExit".tr),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      if (exitAnyway == true) {
        await con.exitGatewayByClient();
      }
      return;
    }

    await con.goToPaymentReturnPage();
  }

  String _bottomButtonText() {
    if (con.isSuccess) {
      return "paymentGateway.back".tr;
    }
    if (con.isCanceled) {
      return "paymentGateway.backWithCancellation".tr;
    }
    if (con.isPending) {
      return "paymentGateway.exit".tr;
    }
    if (con.isFailed) {
      return "paymentGateway.exit".tr;
    }
    return "paymentGateway.exitCancel".tr;
  }
}