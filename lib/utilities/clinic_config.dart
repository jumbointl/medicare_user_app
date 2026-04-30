import 'package:shared_preferences/shared_preferences.dart';

import 'sharedpreference_constants.dart';

/// App-wide clinic configuration. Two layers, runtime takes precedence:
///   - Runtime override: clinic_id picked by the user (e.g. tapping a clinic
///     card). Persisted in SharedPreferences under
///     `SharedPreferencesConstants.clinicId`.
///   - Build-time defaults via dart-defines, mirroring `medicare-user-web`:
///       flutter run --dart-define=VITE_CLINIC_ID=5
///       flutter run --dart-define=VITE_CLINIC_IDS=5,7,9
///       flutter run --dart-define=VITE_SHOW_LAB=true
///       flutter run --dart-define=VITE_SHOW_AIBANNER=true
class ClinicConfig {
  static const String _rawClinicId =
      String.fromEnvironment('VITE_CLINIC_ID', defaultValue: '');
  static const String _rawClinicIds =
      String.fromEnvironment('VITE_CLINIC_IDS', defaultValue: '');
  static const String _rawShowLab =
      String.fromEnvironment('VITE_SHOW_LAB', defaultValue: '');
  static const String _rawShowAiBanner =
      String.fromEnvironment('VITE_SHOW_AIBANNER', defaultValue: '');
  static const String _rawShowBlog =
      String.fromEnvironment('VITE_SHOW_BLOG', defaultValue: '');
  static const String _rawAppointmentOnly =
      String.fromEnvironment('VITE_APPOINTMENT_ONLY', defaultValue: '');

  // Runtime override loaded from SharedPreferences and mutated by
  // setActiveClinicId. Null means "no runtime selection".
  static int? _runtimeClinicId;

  static bool _parseBool(String raw, {bool defaultValue = false}) {
    final v = raw.trim().toLowerCase();
    if (v.isEmpty) return defaultValue;
    return v == 'true' || v == '1';
  }

  /// Show pathology/lab section in the home and allow PathologyPage content.
  /// Default false — opt in with --dart-define=VITE_SHOW_LAB=true.
  static bool get showLab => _parseBool(_rawShowLab);

  /// Show the AI assistant banner card on the home page.
  /// Default false — opt in with --dart-define=VITE_SHOW_AIBANNER=true.
  static bool get showAiBanner => _parseBool(_rawShowAiBanner);

  /// Show the blog section (home list, blog list page, and any link/button
  /// pointing to it). Default false — opt in with
  /// --dart-define=VITE_SHOW_BLOG=true.
  static bool get showBlog => _parseBool(_rawShowBlog);

  /// Appointment-only mode: replace the home page with a redirector that goes
  /// straight to DoctorsDetailsPage (when there is a single clinic with a
  /// single doctor), ClinicPage (single clinic with multiple doctors), or
  /// ClinicListPage (more than one clinic). Default true — opt out with
  /// --dart-define=VITE_APPOINTMENT_ONLY=false.
  static bool get showAppointmentOnly =>
      _parseBool(_rawAppointmentOnly, defaultValue: true);

  /// Build-time clinic id from --dart-define=VITE_CLINIC_ID. Null if unset.
  static int? get _buildTimeClinicId {
    if (_rawClinicId.trim().isEmpty) return null;
    return int.tryParse(_rawClinicId.trim());
  }

  /// Effective single clinic id. Runtime override wins; otherwise falls back
  /// to the dart-define.
  static int? get defaultClinicId =>
      _runtimeClinicId ?? _buildTimeClinicId;

  /// Allowed clinic ids when a multi-clinic allow-list is configured. Empty
  /// list when unset.
  static List<int> get allowedClinicIds {
    if (_rawClinicIds.trim().isEmpty) return const <int>[];
    return _rawClinicIds
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .where((id) => id > 0)
        .toList(growable: false);
  }

  /// True when either CLINIC_ID, CLINIC_IDS, or the runtime override is set.
  static bool get hasClinicFilter =>
      defaultClinicId != null || allowedClinicIds.isNotEmpty;

  /// Hydrate the runtime override from SharedPreferences. Call once at app
  /// startup before any service that calls applyTo() runs.
  static Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(SharedPreferencesConstants.clinicId);
    if (raw != null && raw.trim().isNotEmpty) {
      _runtimeClinicId = int.tryParse(raw.trim());
    }
  }

  /// Persist a clinic_id chosen at runtime (e.g. user tapped a clinic card)
  /// and update the in-memory cache so subsequent applyTo() calls pick it up
  /// immediately.
  static Future<void> setActiveClinicId(int? id) async {
    final normalized = (id != null && id > 0) ? id : null;
    _runtimeClinicId = normalized;
    final prefs = await SharedPreferences.getInstance();
    if (normalized != null) {
      await prefs.setString(
        SharedPreferencesConstants.clinicId,
        normalized.toString(),
      );
    } else {
      await prefs.remove(SharedPreferencesConstants.clinicId);
    }
  }

  /// Adds clinic_id / clinic_ids to a query map following the same rule as
  /// the web: `clinic_ids` (CSV) takes precedence over `clinic_id` when both
  /// are set, matching backend `CityController`/`ClinicController` filters.
  static Map<String, dynamic> applyTo(Map<String, dynamic> query) {
    final ids = allowedClinicIds;
    if (ids.isNotEmpty) {
      query['clinic_ids'] = ids.join(',');
    } else if (defaultClinicId != null) {
      query['clinic_id'] = defaultClinicId;
    }
    return query;
  }
}
