import 'package:udemy_core/udemy_core.dart';

import '../helpers/post_req_helper.dart';
import '../utilities/api_content.dart';

class BancardAppointmentExternalPaymentsProvider {
  Future<ResponseApi> confirmAppointmentPayment({
    required int paymentId,
  }) async {
    final String route =
        '${ApiContents.bancardBaseUrl}/api/vi/bancard/card/appointment/confirm';

    final Map<String, dynamic> body = {
      'payment_id': paymentId,
    };

    final dynamic res = await PostService.postReq(route, body);

    if (res == null) {
      return ResponseApi(
        success: false,
        message: 'paymentGateway.couldNotConfirm',
        data: null,
      );
    }

    return ResponseApi(
      success: res['status'] == true || res['success'] == true,
      message: res['message']?.toString() ?? '',
      data: res,
    );
  }

  Future<ResponseApi> cancelAndRollbackAppointmentPayment({
    required int paymentId,
  }) async {
    final String route =
        '${ApiContents.bancardBaseUrl}/api/vi/bancard/card/appointment/cancel-and-rollback';

    final Map<String, dynamic> body = {
      'payment_id': paymentId,
    };

    final dynamic res = await PostService.postReq(route, body);

    if (res == null) {
      return ResponseApi(
        success: false,
        message: 'paymentGateway.couldNotCancelPayment',
        data: null,
      );
    }

    return ResponseApi(
      success: res['status'] == true || res['success'] == true,
      message: res['message']?.toString() ?? '',
      data: res,
    );
  }
}