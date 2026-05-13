class SharedPreferencesConstants{
  static const String token = 'token';
  static const String theme = 'theme';
  static const String uid = 'uid';
  static const String patientId = 'patient_id';
  static const String phone = 'phone';
  static const String name = 'name';
  static const String login = 'login';
  static const String languageCode = 'language_code';
  static const String allLanguages = 'languages';
  static const String clinicId = 'clinic_id';
  // Dynamic-key (rotating HMAC, 2026-05-08). Server emite junto al token
  // en login y refresh-dynamic-key. Sent en header `x-dynamic-key` en cada
  // request autenticado.
  static const String dynamicKey = 'dynamic_key';
  // 'password' | 'google'. Decide qué hacer cuando server rechaza dynamic_key:
  //   google   → llamar /v1/refresh-dynamic-key (sin re-login)
  //   password → clear session y mandar a login
  static const String loginProvider = 'login_provider';

  // Refresh-token Fase 2 (Pablo 2026-05-12). El backend emite estos
  // campos al login. Permite que el interceptor 401 llame POST /v1/refresh
  // cuando el session-JWT (12h) expira, en lugar de forzar logout.
  static const String refreshToken = 'refresh_token';
  static const String refreshTokenCreatedAt = 'refresh_token_created_at';
  static const String sessionTokenCreatedAt = 'session_token_created_at';
}