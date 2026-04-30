import 'package:flutter/foundation.dart';

import '../helpers/get_req_helper.dart';
import '../model/time_slots_model.dart';
import '../utilities/api_content.dart';

class TimeSlotsService {
  static List<TimeSlotsModel> dataFromJson(jsonDecodedData) {
    return List<TimeSlotsModel>.from(
      jsonDecodedData.map((item) => TimeSlotsModel.fromJson(item)),
    );
  }

  /// Time interval for a specific day.
  ///   slotType "1" → /doctors/{doctId}/clinics/{clinicId}/time-interval/{day}
  ///   slotType "2" → /doctors/{doctId}/clinics/{clinicId}/video-time-interval/{day}
  static Future<List<TimeSlotsModel>?> getData({
    String? doctId,
    String? day,
    String? slotType,
    String? clinicId,
  }) async {
    if (doctId == null || doctId.isEmpty || doctId == 'null') {
      debugPrint('TimeSlotsService.getData skipped: missing doctId');
      return null;
    }
    if (clinicId == null || clinicId.isEmpty || clinicId == 'null') {
      debugPrint('TimeSlotsService.getData skipped: missing clinicId');
      return null;
    }
    if (day == null || day.isEmpty) {
      debugPrint('TimeSlotsService.getData skipped: missing day');
      return null;
    }
    final endpoint = slotType == '2' ? 'video-time-interval' : 'time-interval';
    final url =
        '${ApiContents.baseApiUrl}/doctors/$doctId/clinics/$clinicId/$endpoint/$day';
    final res = await GetService.getReq(url);
    if (res == null) return null;
    return dataFromJson(res);
  }

  /// Configured time-slots (no day) for a doctor at a clinic.
  ///   slotType "1" → /doctors/{doctId}/clinics/{clinicId}/time-slots
  ///   slotType "2" → /doctors/{doctId}/clinics/{clinicId}/video-time-slots
  static Future<List<TimeSlotsModel>?> getSlots({
    required String doctId,
    required String clinicId,
    required String slotType,
  }) async {
    if (doctId.isEmpty || doctId == 'null') return null;
    if (clinicId.isEmpty || clinicId == 'null') return null;
    final endpoint = slotType == '2' ? 'video-time-slots' : 'time-slots';
    final url =
        '${ApiContents.baseApiUrl}/doctors/$doctId/clinics/$clinicId/$endpoint';
    final res = await GetService.getReq(url);
    if (res == null) return null;
    return dataFromJson(res);
  }
}
