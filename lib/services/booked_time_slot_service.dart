import 'package:flutter/foundation.dart';

import '../helpers/get_req_helper.dart';
import '../model/booked_time_slot_mdel.dart';
import '../utilities/api_content.dart';

class BookedTimeSlotsService {
  static const _getUrl = ApiContents.getBookedTimeSlotsUrl;

  static List<BookedTimeSlotsModel> dataFromJson(jsonDecodedData) {
    return List<BookedTimeSlotsModel>.from(
      jsonDecodedData.map((item) => BookedTimeSlotsModel.fromJson(item)),
    );
  }

  /// Backend route is the legacy flat one:
  ///   GET $baseApiUrl/get_booked_time_slots?doct_id=...&date=...&type=...&clinic_id=...
  /// `doct_id` (not doctor_id) is intentional — the appointments table column
  /// uses that spelling and renaming is out of scope.
  /// `clinic_id` is nullable on the backend, so it is sent only when provided.
  static Future<List<BookedTimeSlotsModel>?> getData({
    String? doctId,
    String? date,
    String? type,
    String? clinicId,
  }) async {
    if (doctId == null || doctId.isEmpty || doctId == 'null') {
      debugPrint('BookedTimeSlotsService.getData skipped: missing doctId');
      return null;
    }
    final qs = <String>[
      'doct_id=${Uri.encodeQueryComponent(doctId)}',
      if (date != null && date.isNotEmpty)
        'date=${Uri.encodeQueryComponent(date)}',
      if (type != null && type.isNotEmpty)
        'type=${Uri.encodeQueryComponent(type)}',
      if (clinicId != null && clinicId.isNotEmpty && clinicId != 'null')
        'clinic_id=${Uri.encodeQueryComponent(clinicId)}',
    ];
    final url = '$_getUrl?${qs.join('&')}';
    final res = await GetService.getReq(url);
    if (res == null) return null;
    return dataFromJson(res);
  }
}
