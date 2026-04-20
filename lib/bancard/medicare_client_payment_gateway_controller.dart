import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:udemy_core/udemy_core.dart';

import 'bancard_appointment_external_payments_provider.dart';
import 'bancard_lab_booking_payment_provider.dart';
import 'medicare_payments_provider.dart';

enum PaymentGatewayUiStatus {
  loading,
  browsing,
  pending,
  success,
  canceled,
  failed,
}

class PaymentStatusIds {
  static const int created = 0;
  static const int processIdTimeout = 5;
  static const int pendingPayment = 10;
  static const int reportedByApp = 60;
  static const int processIdError = 90;
  static const int canceledByClient = 91;
  static const int rejected = 92;
  static const int rollback = 93;
  static const int success = 99;

  static bool allowsRetry(int? value) {
    return value == created ||
        value == processIdTimeout ||
        value == pendingPayment ||
        value == reportedByApp ||
        value == processIdError ||
        value == canceledByClient ||
        value == rollback;
  }

  static String label(int? value) {
    switch (value) {
      case created:
        return 'paymentGateway.statusCreated'.tr;
      case processIdTimeout:
        return 'paymentGateway.statusTimeoutProcessId'.tr;
      case pendingPayment:
        return 'paymentGateway.statusPendingPayment'.tr;
      case reportedByApp:
        return 'paymentGateway.statusReportedByApp'.tr;
      case processIdError:
        return 'paymentGateway.statusProcessIdError'.tr;
      case canceledByClient:
        return 'paymentGateway.statusCanceledByClient'.tr;
      case rejected:
        return 'paymentGateway.statusRejected'.tr;
      case rollback:
        return 'paymentGateway.statusRollback'.tr;
      case success:
        return 'paymentGateway.statusSuccess'.tr;
      default:
        return 'paymentGateway.statusUnknown'.tr;
    }
  }
}

void payLog(String step, [Map<String, dynamic>? data]) {
  if (!MemorySol.debugMode) return;
  try {
    debugPrint('[PAYFLOW][$step] ${jsonEncode(data ?? <String, dynamic>{})}');
  } catch (_) {
    debugPrint('[PAYFLOW][$step] $data');
  }
}

class MedicareClientPaymentGatewayController extends GetxController {
  final MedicarePaymentsProvider paymentsProvider = MedicarePaymentsProvider();
  final BancardAppointmentExternalPaymentsProvider externalPaymentsProvider =
  BancardAppointmentExternalPaymentsProvider();
  final BancardLabBookingPaymentProvider labPaymentsProvider =
  BancardLabBookingPaymentProvider();

  final RxBool isProcessing = false.obs;
  final RxBool isBusy = false.obs;
  final RxInt webProgress = 0.obs;
  final RxBool showLinearProgress = false.obs;

  final RxnInt currentPaymentStatusId = RxnInt();
  final RxString currentPaymentStatusLabel = ''.obs;
  final RxString paymentMessage = ''.obs;
  final RxString statusMessage = ''.obs;
  final Rx<PaymentGatewayUiStatus> uiStatus =
      PaymentGatewayUiStatus.loading.obs;

  String? authorizationCode;
  String? responseDescription;
  String? confirmedAt;
  String? paymentCurrency = 'PYG';
  WebViewController? webViewController;

  int? appointmentId;
  int? labBookingId;
  String? patientName;
  double? paymentAmount;

  String? paymentUrl;
  String? checkoutPageUrl;
  int? paymentId;
  int? paymentTypeId;
  String? provider;
  String? providerReference;
  String? providerProcessId;
  bool isRetryPaymentFlow = false;

  String flowType = 'appointment';

  Timer? _paymentStatusTimer;
  bool _isPollingPaymentStatus = false;
  Timer? _unlockExitTimer;
  Timer? _gatewayTimeoutTimer;

  bool _isFinishingFlow = false;
  bool _exitLocked = false;

  static const Duration gatewayTimeout = Duration(minutes: 10);

  bool get isSuccess => uiStatus.value == PaymentGatewayUiStatus.success;
  bool get isPending => uiStatus.value == PaymentGatewayUiStatus.pending;
  bool get isCanceled => uiStatus.value == PaymentGatewayUiStatus.canceled;
  bool get isFailed => uiStatus.value == PaymentGatewayUiStatus.failed;
  bool get isWebLoading => showLinearProgress.value;
  bool get canExitNow =>
      !_exitLocked || isSuccess || isCanceled || isFailed || isPending;

  bool get isLabFlow => flowType == 'lab_booking';
  bool get isAppointmentFlow => flowType != 'lab_booking';

  double? get webProgressValue {
    if (!showLinearProgress.value) return null;
    final int value = webProgress.value.clamp(0, 100);
    return value / 100.0;
  }

  @override
  void onInit() {
    super.onInit();
    _readArguments();
    _setupWebViewIfNeeded();
  }

  void _readArguments() {
    final dynamic args = Get.arguments;

    if (args is! Map) {
      statusMessage.value = 'paymentGateway.missingPaymentArgs'.tr;
      uiStatus.value = PaymentGatewayUiStatus.failed;
      update();
      return;
    }

    appointmentId = _readInt(args['appointment_id']);
    labBookingId = _readInt(args['lab_booking_id']);
    patientName = args['patient_name']?.toString();

    final dynamic rawAmount = args['payment_amount'];
    if (rawAmount is num) {
      paymentAmount = rawAmount.toDouble();
    } else if (rawAmount != null) {
      paymentAmount = double.tryParse(rawAmount.toString());
    }

    checkoutPageUrl = args['checkout_page_url']?.toString();
    paymentUrl = checkoutPageUrl ?? args['payment_url']?.toString();

    paymentId = _readInt(args['payment_id']);
    paymentTypeId = _readInt(args['payment_type_id']);
    provider = args['provider']?.toString();
    providerReference = args['provider_reference']?.toString();
    providerProcessId = args['provider_process_id']?.toString();
    isRetryPaymentFlow = args['retry_payment_flow'] == true;

    flowType = args['flow_type']?.toString() ?? 'appointment';

    if (isAppointmentFlow && appointmentId == null) {
      statusMessage.value = 'paymentGateway.missingAppointmentId'.tr;
      uiStatus.value = PaymentGatewayUiStatus.failed;
      update();
      return;
    }

    if (isLabFlow && labBookingId == null) {
      statusMessage.value = 'paymentGateway.missingLabBookingId'.tr;
      uiStatus.value = PaymentGatewayUiStatus.failed;
      update();
      return;
    }

    if (paymentUrl == null || paymentUrl!.isEmpty) {
      statusMessage.value = 'paymentGateway.missingPaymentUrl'.tr;
      uiStatus.value = PaymentGatewayUiStatus.failed;
      update();
      return;
    }

    statusMessage.value = 'paymentGateway.completeToContinue'.tr;
    uiStatus.value = PaymentGatewayUiStatus.loading;
    update();
  }

  void lockExitTemporarily() {
    _unlockExitTimer?.cancel();
    _exitLocked = true;

    _unlockExitTimer = Timer(const Duration(seconds: 8), () {
      _exitLocked = false;
      update();
    });

    update();
  }

  void unlockExitNow() {
    _unlockExitTimer?.cancel();
    _exitLocked = false;
    update();
  }

  void startGatewayTimeout() {
    _gatewayTimeoutTimer?.cancel();

    _gatewayTimeoutTimer = Timer(gatewayTimeout, () async {
      await forceExitAndRollback(reason: 'timeout');
    });
  }

  void stopGatewayTimeout() {
    if (_gatewayTimeoutTimer == null) return;
    _gatewayTimeoutTimer?.cancel();
    _gatewayTimeoutTimer = null;
  }

  void startPaymentStatusPolling() {
    if (_paymentStatusTimer != null) return;
    if (isAppointmentFlow && appointmentId == null) return;
    if (isLabFlow && labBookingId == null) return;

    _paymentStatusTimer = Timer.periodic(
      const Duration(seconds: 3),
          (_) async => await pollPaymentStatusOnce(),
    );
  }

  void stopPaymentStatusPolling() {
    if (_paymentStatusTimer == null) return;
    _paymentStatusTimer?.cancel();
    _paymentStatusTimer = null;
  }

  Future<void> finishWithFailureAndReturn({
    required int? idPaymentStatus,
    String? message,
  }) async {
    if (_isFinishingFlow) return;
    _isFinishingFlow = true;

    isBusy.value = false;
    showLinearProgress.value = false;
    webProgress.value = 100;
    stopPaymentStatusPolling();
    stopGatewayTimeout();
    unlockExitNow();

    currentPaymentStatusId.value = idPaymentStatus;
    currentPaymentStatusLabel.value = PaymentStatusIds.label(idPaymentStatus);

    final String finalMessage = (message?.trim().isNotEmpty == true)
        ? message!.trim()
        : 'paymentGateway.paymentNotApproved'.tr;

    paymentMessage.value = finalMessage;
    statusMessage.value = finalMessage;
    uiStatus.value = PaymentGatewayUiStatus.failed;
    update();

    await showPaymentResultDialog(
      isSuccess: false,
      title: 'paymentGateway.paymentRejected'.tr,
      message: finalMessage,
    );

    await goToPaymentReturnPage();
  }

  Future<void> finishWithCanceledAndReturn({
    required int? idPaymentStatus,
    String? message,
  }) async {
    if (_isFinishingFlow) return;
    _isFinishingFlow = true;

    isBusy.value = false;
    showLinearProgress.value = false;
    webProgress.value = 100;
    stopPaymentStatusPolling();
    stopGatewayTimeout();
    unlockExitNow();

    currentPaymentStatusId.value = idPaymentStatus;
    currentPaymentStatusLabel.value = PaymentStatusIds.label(idPaymentStatus);

    final String finalMessage = (message?.trim().isNotEmpty == true)
        ? message!.trim()
        : 'paymentGateway.operationCanceled'.tr;

    paymentMessage.value = finalMessage;
    statusMessage.value = finalMessage;
    uiStatus.value = PaymentGatewayUiStatus.canceled;
    update();

    await showPaymentResultDialog(
      isSuccess: false,
      title: 'paymentGateway.canceled'.tr,
      message: finalMessage,
    );

    await goToPaymentReturnPage();
  }

  Future<void> finishWithSuccessAndReturn() async {
    if (_isFinishingFlow) return;
    _isFinishingFlow = true;

    stopPaymentStatusPolling();
    stopGatewayTimeout();
    unlockExitNow();

    isBusy.value = false;
    showLinearProgress.value = false;
    webProgress.value = 100;

    currentPaymentStatusId.value = PaymentStatusIds.success;
    currentPaymentStatusLabel.value =
        PaymentStatusIds.label(PaymentStatusIds.success);

    paymentMessage.value = responseDescription?.trim().isNotEmpty == true
        ? responseDescription!.trim()
        : 'paymentGateway.paymentConfirmedCorrectly'.tr;
    statusMessage.value = paymentMessage.value;
    uiStatus.value = PaymentGatewayUiStatus.success;
    update();

    await showPaymentResultDialog(
      isSuccess: true,
      title: 'paymentGateway.approved'.tr,
      message: paymentMessage.value,
    );

    await goToPaymentReturnPage();
  }

  String _formatPaymentDateTime(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) return '';

    try {
      final DateTime date = DateTime.parse(value).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value;
    }
  }

  Future<void> forceExitAndRollback({required String reason}) async {
    stopPaymentStatusPolling();
    stopGatewayTimeout();
    unlockExitNow();

    if (paymentId != null) {
      try {
        if (isLabFlow) {
          await labPaymentsProvider.cancelAndRollbackLabBookingPayment(
            paymentId: paymentId!,
          );
        } else {
          await paymentsProvider.cancelAndRollbackAppointmentPayment(
            paymentId: paymentId!,
          );
        }
      } catch (e) {
        payLog('FORCE_EXIT_AND_ROLLBACK_ERROR', {
          'appointment_id': appointmentId,
          'lab_booking_id': labBookingId,
          'payment_id': paymentId,
          'reason': reason,
          'error': e.toString(),
        });
      }
    }

    final String message = reason == 'timeout'
        ? 'paymentGateway.timeoutCanceled'.tr
        : 'paymentGateway.operationCanceled'.tr;

    currentPaymentStatusId.value = PaymentStatusIds.rollback;
    currentPaymentStatusLabel.value =
        PaymentStatusIds.label(PaymentStatusIds.rollback);
    paymentMessage.value = message;
    statusMessage.value = message;
    uiStatus.value = PaymentGatewayUiStatus.canceled;
    update();

    await goToPaymentReturnPage();
  }

  Future<void> pollPaymentStatusOnce() async {
    if (_isPollingPaymentStatus) return;
    if (isAppointmentFlow && appointmentId == null) return;
    if (isLabFlow && labBookingId == null) return;
    if (_isFinishingFlow) return;

    _isPollingPaymentStatus = true;

    try {
      Map<String, dynamic>? paymentData;

      if (isLabFlow && labBookingId != null) {
        paymentData = await labPaymentsProvider.findCurrentByLabBookingId(
          labBookingId: labBookingId!,
        );
      } else if (appointmentId != null) {
        paymentData =
        await paymentsProvider.findCurrentByAppointmentId(appointmentId!);
      }

      final int? idPaymentStatus = _readInt(paymentData?['id_payment_status']);

      providerReference =
          paymentData?['provider_reference']?.toString() ?? providerReference;
      providerProcessId =
          paymentData?['provider_process_id']?.toString() ?? providerProcessId;
      authorizationCode =
          paymentData?['authorization_code']?.toString() ?? authorizationCode;

      responseDescription =
          paymentData?['response_message']?.toString() ??
              paymentData?['gateway_description']?.toString() ??
              responseDescription;

      confirmedAt = paymentData?['confirmed_at']?.toString() ?? confirmedAt;
      paymentCurrency =
          paymentData?['currency_code']?.toString() ?? paymentCurrency ?? 'PYG';

      currentPaymentStatusId.value = idPaymentStatus;
      currentPaymentStatusLabel.value = PaymentStatusIds.label(idPaymentStatus);

      final String terminalMessage = _resolveTerminalMessage(paymentData);

      if (_isTerminalStatus(idPaymentStatus)) {
        if (_isTerminalSuccessStatus(idPaymentStatus)) {
          await finishWithSuccessAndReturn();
          return;
        }

        if (_isTerminalCanceledStatus(idPaymentStatus)) {
          await finishWithCanceledAndReturn(
            idPaymentStatus: idPaymentStatus,
            message: terminalMessage,
          );
          return;
        }

        await finishWithFailureAndReturn(
          idPaymentStatus: idPaymentStatus,
          message: terminalMessage,
        );
        return;
      }
    } catch (e) {
      payLog('POLLING_ERROR', {
        'appointment_id': appointmentId,
        'lab_booking_id': labBookingId,
        'error': e.toString(),
      });
    } finally {
      _isPollingPaymentStatus = false;
    }
  }

  void _setupWebViewIfNeeded() {
    if (paymentUrl == null || paymentUrl!.isEmpty) {
      return;
    }

    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            webProgress.value = progress;
            showLinearProgress.value = progress >= 0 && progress < 100;
            update();
          },
          onPageStarted: (String url) {
            showLinearProgress.value = true;
            webProgress.value = 0;

            if (!isSuccess && !isCanceled && !isFailed) {
              uiStatus.value = PaymentGatewayUiStatus.browsing;
            }

            update();
          },
          onPageFinished: (String url) {
            webProgress.value = 100;
            showLinearProgress.value = false;
            update();
          },
          onWebResourceError: (WebResourceError error) {
            payLog('GATEWAY_WEB_ERROR', {
              'errorCode': error.errorCode,
              'description': error.description,
              'errorType': error.errorType?.name ?? 'ERROR',
              'url': error.url,
              'appointment_id': appointmentId,
              'lab_booking_id': labBookingId,
              'payment_id': paymentId,
            });

            showLinearProgress.value = false;
            update();
          },
          onNavigationRequest: (NavigationRequest request) {
            final Uri? uri = Uri.tryParse(request.url);

            if (uri == null) {
              return NavigationDecision.navigate;
            }

            final bool isBancardReturn =
                uri.queryParameters.containsKey('status') ||
                    uri.queryParameters.containsKey('process_id') ||
                    request.url.contains('payment-result') ||
                    request.url.contains('bancard/card/return') ||
                    request.url.contains('bancard/card/cancel');

            if (isBancardReturn) {
              showLinearProgress.value = true;
              webProgress.value = 100;
              update();

              handleBancardReturnUri(
                uri: uri,
                providerReference: providerReference,
              );

              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(paymentUrl!));

    uiStatus.value = PaymentGatewayUiStatus.browsing;
    lockExitTemporarily();
    startPaymentStatusPolling();
    startGatewayTimeout();
    update();
  }

  Future<void> handleBancardReturnUri({
    required Uri uri,
    String? providerReference,
  }) async {
    if (isProcessing.value) return;
    if (_isFinishingFlow) return;

    isProcessing.value = true;
    isBusy.value = true;
    showLinearProgress.value = true;
    webProgress.value = 70;
    update();

    try {
      final String status = (uri.queryParameters['status'] ?? '').toLowerCase();
      final String? processId = uri.queryParameters['process_id'];
      final int? returnedPaymentId =
      int.tryParse(uri.queryParameters['payment_id'] ?? '');
      final String? message = uri.queryParameters['message'];

      if (processId != null && processId.isNotEmpty) {
        providerProcessId = processId;
      }
      if (returnedPaymentId != null) {
        paymentId = returnedPaymentId;
      }

      final bool isCanceledStatus = status == 'canceled' ||
          status == 'cancel' ||
          status == 'payment_canceled';

      final bool isSuccessStatus = status == 'success' ||
          status == 'payment_success' ||
          status == 'approved' ||
          status == 'ok';

      final bool isFailedStatus = status == 'payment_fail' ||
          status == 'failed' ||
          status == 'error' ||
          status == 'rejected';

      if (isCanceledStatus) {
        await handleCanceledReturn(
          paymentId: returnedPaymentId ?? paymentId,
          processId: processId,
          message: message,
        );
        return;
      }

      if (isSuccessStatus) {
        await handleSuccessReturn(
          paymentId: returnedPaymentId ?? paymentId,
          processId: processId,
          providerReference: providerReference,
        );
        return;
      }

      if (isFailedStatus) {
        await handleFailedReturn(
          paymentId: returnedPaymentId ?? paymentId,
          processId: processId,
          message: message,
          shouldConfirmWithBackend: true,
        );
        return;
      }

      await handleFailedReturn(
        paymentId: returnedPaymentId ?? paymentId,
        processId: processId,
        message: message,
        shouldConfirmWithBackend: true,
      );
    } catch (e) {
      payLog('RETURN_EXCEPTION', {
        'appointment_id': appointmentId,
        'lab_booking_id': labBookingId,
        'payment_id': paymentId,
        'error': e.toString(),
      });

      paymentMessage.value = 'paymentGateway.returnProcessingError'.tr;
      statusMessage.value = paymentMessage.value;
      uiStatus.value = PaymentGatewayUiStatus.pending;
      update();
      return;
    } finally {
      isProcessing.value = false;
      isBusy.value = false;
      webProgress.value = 100;
      showLinearProgress.value = false;
      update();
    }
  }

  Future<void> handleSuccessReturn({
    required int? paymentId,
    required String? processId,
    String? providerReference,
  }) async {
    if (paymentId == null) {
      paymentMessage.value = 'paymentGateway.missingBancardReturnData'.tr;
      statusMessage.value = paymentMessage.value;
      uiStatus.value = PaymentGatewayUiStatus.pending;
      update();
      return;
    }

    ResponseApi response;

    if (isLabFlow) {
      response = await labPaymentsProvider.confirmLabBookingPayment(
        paymentId: paymentId,
      );
    } else {
      response = await paymentsProvider.confirmAppointmentPayment(
        paymentId: paymentId,
      );
    }

    final Map<String, dynamic> responseMap = _parseDynamicMap(response.data);
    final Map<String, dynamic> payment = _extractPaymentMap(responseMap);

    final int? idPaymentStatus = _readInt(payment['id_payment_status']);

    this.providerReference =
        payment['provider_reference']?.toString() ?? providerReference;
    providerProcessId =
        payment['provider_process_id']?.toString() ?? providerProcessId;
    authorizationCode =
        payment['authorization_code']?.toString() ?? authorizationCode;

    responseDescription =
        payment['response_message']?.toString() ??
            payment['gateway_description']?.toString() ??
            responseDescription;

    confirmedAt = payment['confirmed_at']?.toString() ?? confirmedAt;
    paymentCurrency =
        payment['currency_code']?.toString() ?? paymentCurrency ?? 'PYG';

    currentPaymentStatusId.value = idPaymentStatus;
    currentPaymentStatusLabel.value = PaymentStatusIds.label(idPaymentStatus);

    if (_isTerminalStatus(idPaymentStatus)) {
      if (_isTerminalSuccessStatus(idPaymentStatus)) {
        await finishWithSuccessAndReturn();
        return;
      }

      if (_isTerminalCanceledStatus(idPaymentStatus)) {
        await finishWithCanceledAndReturn(
          idPaymentStatus: idPaymentStatus,
          message: responseDescription ??
              response.message ??
              'paymentGateway.operationCanceled'.tr,
        );
        return;
      }

      await finishWithFailureAndReturn(
        idPaymentStatus: idPaymentStatus,
        message: responseDescription ??
            response.message ??
            'paymentGateway.paymentRejected'.tr,
      );
      return;
    }

    paymentMessage.value =
        response.message ?? 'paymentGateway.returnProcessingError'.tr;
    statusMessage.value = paymentMessage.value;
    uiStatus.value = PaymentGatewayUiStatus.pending;
    update();
  }

  bool _isTerminalStatus(int? value) {
    return (value ?? 0) > 89;
  }

  bool _isTerminalSuccessStatus(int? value) {
    return value == PaymentStatusIds.success;
  }

  bool _isTerminalCanceledStatus(int? value) {
    return value == PaymentStatusIds.canceledByClient ||
        value == PaymentStatusIds.rollback;
  }

  String _resolveTerminalMessage(Map<String, dynamic>? paymentData) {
    return paymentData?['gateway_description']?.toString() ??
        paymentData?['response_message']?.toString() ??
        responseDescription ??
        'paymentGateway.statusUnknown'.tr;
  }

  Future<void> handleCanceledReturn({
    required int? paymentId,
    required String? processId,
    String? message,
  }) async {
    currentPaymentStatusId.value = PaymentStatusIds.canceledByClient;
    currentPaymentStatusLabel.value =
        PaymentStatusIds.label(PaymentStatusIds.canceledByClient);

    try {
      ResponseApi response;

      if (isLabFlow) {
        response = await labPaymentsProvider.cancelAndRollbackLabBookingPayment(
          paymentId: paymentId ?? 0,
        );
      } else {
        response = await paymentsProvider.cancelAndRollbackAppointmentPayment(
          paymentId: paymentId ?? 0,
        );
      }

      _parseDynamicMap(response.data);
    } catch (e) {
      payLog('RETURN_CANCELED_API_ERROR', {
        'appointment_id': appointmentId,
        'lab_booking_id': labBookingId,
        'payment_id': paymentId,
        'error': e.toString(),
      });
    }

    stopPaymentStatusPolling();
    stopGatewayTimeout();
    unlockExitNow();

    await finishWithCanceledAndReturn(
      idPaymentStatus: PaymentStatusIds.canceledByClient,
      message: message ?? 'paymentGateway.paymentCanceledByClient'.tr,
    );
  }

  Future<void> handleFailedReturn({
    required int? paymentId,
    required String? processId,
    String? message,
    bool shouldConfirmWithBackend = true,
  }) async {
    if (paymentId != null && shouldConfirmWithBackend) {
      try {
        final ResponseApi response = isLabFlow
            ? await labPaymentsProvider.confirmLabBookingPayment(
          paymentId: paymentId,
        )
            : await paymentsProvider.confirmAppointmentPayment(
          paymentId: paymentId,
        );

        final Map<String, dynamic> responseMap = _parseDynamicMap(response.data);
        final Map<String, dynamic> payment = _extractPaymentMap(responseMap);

        final int? idPaymentStatus = _readInt(payment['id_payment_status']);

        providerReference =
            payment['provider_reference']?.toString() ?? providerReference;
        providerProcessId =
            payment['provider_process_id']?.toString() ?? providerProcessId;
        authorizationCode =
            payment['authorization_code']?.toString() ?? authorizationCode;
        responseDescription =
            payment['response_message']?.toString() ??
                payment['gateway_description']?.toString() ??
                responseDescription;
        confirmedAt = payment['confirmed_at']?.toString() ?? confirmedAt;
        paymentCurrency =
            payment['currency_code']?.toString() ?? paymentCurrency ?? 'PYG';

        currentPaymentStatusId.value = idPaymentStatus;
        currentPaymentStatusLabel.value = PaymentStatusIds.label(idPaymentStatus);

        final String terminalMessage = responseDescription ??
            response.message ??
            message ??
            'paymentGateway.paymentNotApproved'.tr;

        if (_isTerminalStatus(idPaymentStatus)) {
          if (_isTerminalSuccessStatus(idPaymentStatus)) {
            await finishWithSuccessAndReturn();
            return;
          }

          if (_isTerminalCanceledStatus(idPaymentStatus)) {
            await finishWithCanceledAndReturn(
              idPaymentStatus: idPaymentStatus,
              message: terminalMessage,
            );
            return;
          }

          await finishWithFailureAndReturn(
            idPaymentStatus: idPaymentStatus ?? PaymentStatusIds.rejected,
            message: terminalMessage,
          );
          return;
        }
      } catch (e) {
        payLog('RETURN_FAILED_CONFIRM_ERROR', {
          'appointment_id': appointmentId,
          'lab_booking_id': labBookingId,
          'payment_id': paymentId,
          'process_id': processId,
          'error': e.toString(),
        });
      }
    }

    currentPaymentStatusId.value = PaymentStatusIds.rejected;
    currentPaymentStatusLabel.value =
        PaymentStatusIds.label(PaymentStatusIds.rejected);

    await finishWithFailureAndReturn(
      idPaymentStatus: PaymentStatusIds.rejected,
      message: message ?? 'paymentGateway.paymentNotApproved'.tr,
    );
  }

  Future<void> reloadPaymentPage() async {
    if (paymentUrl == null || paymentUrl!.isEmpty) {
      Get.snackbar(
        'paymentGateway.title'.tr,
        'paymentGateway.missingPaymentUrl'.tr,
      );
      return;
    }

    if (webViewController == null) {
      _setupWebViewIfNeeded();
      return;
    }

    await webViewController!.loadRequest(Uri.parse(paymentUrl!));
    uiStatus.value = PaymentGatewayUiStatus.browsing;
    statusMessage.value = 'paymentGateway.verifying'.tr;
    update();
  }

  Future<void> goToPaymentReturnPage() async {
    stopPaymentStatusPolling();
    stopGatewayTimeout();
    unlockExitNow();

    final Map<String, dynamic> args = {
      'flow_type': flowType,
      'appointment_id': appointmentId,
      'lab_booking_id': labBookingId,
      'patient_name': patientName,
      'payment_gateway_status': _statusCodeForReturn(),
      'payment_gateway_message': statusMessage.value,
      'payment_amount': paymentAmount,
      'payment_currency': paymentCurrency ?? 'PYG',
      'payment_reference': providerReference,
      'payment_process_id': providerProcessId,
      'payment_id': paymentId,
      'id_payment_status': currentPaymentStatusId.value,
      'payment_confirmed_at': confirmedAt,
      'payment_response_description': responseDescription,
      'payment_authorization_code': authorizationCode,
    };

    Get.back(result: args);
  }

  String _statusCodeForReturn() {
    if (isSuccess) return 'success';
    if (isCanceled) return 'canceled';
    if (isPending) return 'pending';

    if (currentPaymentStatusId.value == PaymentStatusIds.processIdTimeout) {
      return 'timeout';
    }

    return 'failed';
  }

  int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Map<String, dynamic> _parseDynamicMap(dynamic rawData) {
    if (rawData == null) return <String, dynamic>{};

    if (rawData is Map<String, dynamic>) {
      return rawData;
    }

    if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    }

    if (rawData is String) {
      try {
        final dynamic decoded = jsonDecode(rawData);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return <String, dynamic>{};
      }
    }

    return <String, dynamic>{};
  }

  Map<String, dynamic> _extractPaymentMap(Map<String, dynamic> root) {
    if (root['payment'] is Map<String, dynamic>) {
      return Map<String, dynamic>.from(root['payment']);
    }

    if (root['payment'] is Map) {
      return Map<String, dynamic>.from(root['payment']);
    }

    if (root['data'] is Map<String, dynamic>) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(root['data']);

      if (data['payment'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data['payment']);
      }

      if (data['payment'] is Map) {
        return Map<String, dynamic>.from(data['payment']);
      }

      return data;
    }

    if (root['data'] is Map) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(root['data']);
      if (data['payment'] is Map) {
        return Map<String, dynamic>.from(data['payment']);
      }
      return data;
    }

    return root;
  }

  @override
  void onClose() {
    stopPaymentStatusPolling();
    stopGatewayTimeout();
    _unlockExitTimer?.cancel();
    super.onClose();
  }

  Future<void> showPaymentResultDialog({
    required bool isSuccess,
    required String title,
    required String message,
  }) async {
    final String amountText = paymentAmount != null
        ? '${MemorySol.numberFormatter.format(paymentAmount)} ${paymentCurrency ?? 'PYG'}'
        : '';

    final String entityText =
    isLabFlow ? (labBookingId?.toString() ?? '') : (appointmentId?.toString() ?? '');
    final String entityLabel =
    isLabFlow ? 'paymentGateway.booking'.tr : 'paymentGateway.appointment'.tr;

    final String bancardReferenceText = (providerReference ?? '').trim();
    final String confirmedText = (confirmedAt ?? '').trim();
    final String descriptionText = (responseDescription ?? '').trim();
    final String authorizationText = (authorizationCode ?? '').trim();

    Widget infoRow(String label, String value) {
      if (value.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      );
    }

    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
              size: 30,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSuccess ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'paymentGateway.transactionData'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    infoRow('paymentGateway.dateTime'.tr,
                        _formatPaymentDateTime(confirmedText)),
                    infoRow(entityLabel, entityText),
                    infoRow('paymentGateway.reference'.tr, bancardReferenceText),
                    infoRow('paymentGateway.amount'.tr, amountText),
                    infoRow('paymentGateway.description'.tr, descriptionText),
                    infoRow('paymentGateway.authorization'.tr, authorizationText),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSuccess ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(),
            child: Text('paymentGateway.close'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> exitGatewayByClient() async {
    if (isProcessing.value || _isFinishingFlow) return;

    isProcessing.value = true;
    isBusy.value = true;
    showLinearProgress.value = true;
    webProgress.value = 80;
    update();

    try {
      Map<String, dynamic>? currentPayment;

      if (isLabFlow && labBookingId != null) {
        currentPayment = await labPaymentsProvider.findCurrentByLabBookingId(
          labBookingId: labBookingId!,
        );
      } else if (appointmentId != null) {
        currentPayment =
        await paymentsProvider.findCurrentByAppointmentId(appointmentId!);
      }

      final int? foundPaymentId = _readInt(currentPayment?['id']) ?? paymentId;

      providerReference =
          currentPayment?['provider_reference']?.toString() ?? providerReference;
      providerProcessId =
          currentPayment?['provider_process_id']?.toString() ?? providerProcessId;

      final ResponseApi response = isLabFlow
          ? await labPaymentsProvider.cancelAndRollbackLabBookingPayment(
        paymentId: foundPaymentId ?? 0,
      )
          : await paymentsProvider.cancelAndRollbackAppointmentPayment(
        paymentId: foundPaymentId ?? 0,
      );

      final Map<String, dynamic> data = _parseDynamicMap(response.data);

      final String backendCode =
      (data['code'] ?? data['error_code'] ?? data['name'] ?? '').toString();

      final String backendMessage =
      (data['message'] ?? response.message ?? '').toString();

      final bool isNonFatal = backendCode == 'PaymentNotFoundError' ||
          backendCode == 'AlreadyRollBackError' ||
          backendCode == '0';

      if (response.success == true || isNonFatal) {
        await finishWithCanceledAndReturn(
          idPaymentStatus: PaymentStatusIds.canceledByClient,
          message: backendMessage.trim().isNotEmpty
              ? backendMessage
              : 'paymentGateway.paymentCanceledByClient'.tr,
        );
        return;
      }

      await finishWithFailureAndReturn(
        idPaymentStatus: PaymentStatusIds.processIdError,
        message: backendMessage.trim().isNotEmpty
            ? backendMessage
            : 'paymentGateway.couldNotCancelPayment'.tr,
      );
    } catch (e) {
      final String rawError = e.toString();

      payLog('EXIT_BY_CLIENT_ERROR', {
        'appointment_id': appointmentId,
        'lab_booking_id': labBookingId,
        'payment_id': paymentId,
        'error': rawError,
      });

      final bool isNonFatal = rawError.contains('PaymentNotFoundError') ||
          rawError.contains('AlreadyRollBackError');

      if (isNonFatal) {
        await finishWithCanceledAndReturn(
          idPaymentStatus: PaymentStatusIds.canceledByClient,
          message: 'paymentGateway.operationCanceled'.tr,
        );
        return;
      }

      await finishWithFailureAndReturn(
        idPaymentStatus: PaymentStatusIds.processIdError,
        message: 'paymentGateway.cancelPaymentError'.tr,
      );
    } finally {
      isProcessing.value = false;
      isBusy.value = false;
      showLinearProgress.value = false;
      webProgress.value = 100;
      update();
    }
  }
}
