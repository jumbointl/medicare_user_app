import '../helpers/post_req_helper.dart';
import '../utilities/api_content.dart';

/// PIX — paciente inicia su propio cobro desde user-app. Espejo de
/// la implementación en user-web (PayPixSection). Backend valida
/// ownership: si el caller es patient.user_id del appointment, no
/// emite al panel-TV (paga desde mobile).
class PixService {
  /// POST /v1/pix/init.
  /// Devuelve el body raw `{response, status, message, data: {process_id,
  /// md5, url, amount, ...}}` o null si el helper falló.
  static Future<Map<String, dynamic>?> initPix({
    required int appointmentId,
    required int clinicId,
    required num amount,
    int checkoutNumber = 1,
    int tvNumber = 1,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'appointment_id': appointmentId,
      'clinic_id': clinicId,
      'checkout_number': checkoutNumber,
      'tv_number': tvNumber,
      'amount': amount,
      if (description != null && description.isNotEmpty)
        'description': description,
    };
    final res = await PostService.postReq(ApiContents.pixInitUrl, body);
    if (res == null) return null;
    if (res is Map<String, dynamic>) return res;
    return null;
  }
}
