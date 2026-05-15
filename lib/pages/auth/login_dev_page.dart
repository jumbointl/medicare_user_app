// Login para desarrollo (impersonate opcional). Triggered desde
// LoginPage cuando `AppConstants.isProductionMode == true`. El backend
// (POST /v1/login/dev) hace el gate de rol (Super Admin / Developer);
// esta vista solo recolecta los 3 inputs, llama el endpoint y persiste
// el bundle de sesión espejando `LoginPage._handleSuccessLogin`.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controller/user_controller.dart';
import '../../services/user_service.dart';
import '../../services/user_subscription.dart';
import '../../utilities/colors_constant.dart' show ColorResources;
import '../../utilities/sharedpreference_constants.dart';
import '../../widget/toast_message.dart';

class LoginDevPage extends StatefulWidget {
  /// Callback invocado al login exitoso (igual contrato que LoginPage).
  /// Si es null, hace `Get.back()` y deja que el caller refresque.
  /// `Function?` (no `VoidCallback?`) para matchear el tipo del campo
  /// en LoginPage que lo declara así.
  final Function? onSuccessLogin;

  const LoginDevPage({super.key, this.onSuccessLogin});

  @override
  State<LoginDevPage> createState() => _LoginDevPageState();
}

class _LoginDevPageState extends State<LoginDevPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _impersonateCtrl = TextEditingController();
  bool _obscurePwd = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _impersonateCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await UserService.loginDev(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        impersonateEmail: _impersonateCtrl.text,
      );
      if (res == null) {
        _setError('something_went_wrong'.tr);
        return;
      }
      // El postReq helper devuelve el JSON parseado. Backend convención:
      //   { response: 200, status: true, message: "Login successful"|
      //     "Impersonation successful", token, data, ... }
      // En 401/403/422 devuelve `{status:false, message}` (también JSON).
      if (res is! Map) {
        _setError('something_went_wrong'.tr);
        return;
      }
      final ok = res['status'] == true;
      if (!ok) {
        final msg = (res['message'] ?? '').toString();
        // Mensaje custom del backend cuando target del impersonate no existe:
        if (msg.toLowerCase().contains('suplantar')) {
          _setError('login_dev_user_not_exists'.tr);
        } else if ((res['response'] ?? 0) == 403) {
          _setError('login_dev_no_permission'.tr);
        } else {
          _setError(msg.isEmpty ? 'login_failed'.tr : msg);
        }
        return;
      }
      await _persistSession(res);
      // Refresh state global como hace `_handleSuccessLogin` del LoginPage.
      final userController = Get.find<UserController>(tag: 'user');
      await userController.getData();
      userController.loginEpoch.value++;
      await UserService.updateFCM();
      await UserSubscribe.toTopi(topicName: 'PATIENT_APP');

      final isImpersonating = res['impersonator_id'] != null;
      IToastMsg.showMessage(
        isImpersonating
            ? 'login_dev_impersonated_as'.trParams({
                'email': (res['data']?['email'] ?? '').toString(),
              })
            : 'logged_in'.tr,
      );

      if (!mounted) return;
      if (widget.onSuccessLogin != null) {
        widget.onSuccessLogin!();
      } else {
        Get.back();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setError(String msg) {
    if (!mounted) return;
    setState(() {
      _error = msg;
      _isLoading = false;
    });
  }

  /// Espejo de `LoginPage._handleSuccessLogin` pero sin la UI. Toda
  /// pantalla autenticada del app lee de estos SharedPreferences.
  Future<void> _persistSession(Map res) async {
    final prefs = await SharedPreferences.getInstance();
    final data = res['data'] is Map ? Map<String, dynamic>.from(res['data']) : <String, dynamic>{};

    await prefs.setString(
      SharedPreferencesConstants.token,
      (res['token'] ?? '').toString(),
    );
    await prefs.setString(
      SharedPreferencesConstants.dynamicKey,
      (res['dynamic_key'] ?? '').toString(),
    );

    final refreshTokenStr = (res['refresh_token'] ?? '').toString();
    if (refreshTokenStr.isNotEmpty) {
      await prefs.setString(
        SharedPreferencesConstants.refreshToken,
        refreshTokenStr,
      );
      await prefs.setString(
        SharedPreferencesConstants.refreshTokenCreatedAt,
        DateTime.now().toUtc().toIso8601String(),
      );
    }
    await prefs.setString(
      SharedPreferencesConstants.sessionTokenCreatedAt,
      DateTime.now().toUtc().toIso8601String(),
    );
    await prefs.setString(
      SharedPreferencesConstants.loginProvider,
      (res['login_provider'] ?? 'password').toString(),
    );
    await prefs.setString(
      SharedPreferencesConstants.uid,
      (data['id'] ?? '').toString(),
    );
    await prefs.setString(
      SharedPreferencesConstants.patientId,
      (data['patient_id'] ?? '').toString(),
    );
    await prefs.setString(
      SharedPreferencesConstants.name,
      '${data['f_name'] ?? ''} ${data['l_name'] ?? ''}'.trim(),
    );
    await prefs.setString(
      SharedPreferencesConstants.phone,
      (data['phone'] ?? '').toString(),
    );
    await prefs.setBool(SharedPreferencesConstants.login, true);

    // Impersonation audit fields. Backend devuelve impersonator_id !=
    // null SOLO cuando se usó impersonate_email; en login normal vienen
    // ausentes, así que persisto cadena vacía para limpiar cualquier
    // sesión impersonada previa.
    await prefs.setString(
      SharedPreferencesConstants.impersonatorId,
      (res['impersonator_id'] ?? '').toString(),
    );
    await prefs.setString(
      SharedPreferencesConstants.impersonatorEmail,
      (res['impersonator_email'] ?? '').toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImp = _impersonateCtrl.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: Text('login_dev_page_title'.tr),
        backgroundColor: ColorResources.btnColorGreen,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'login_dev_subtitle'.tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'login_dev_alert'.tr,
                          style: const TextStyle(color: Color(0xFF065F46), fontSize: 12),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: 'email'.tr,
                          hintText: 'vos@dominio.com',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty || !s.contains('@')) {
                            return 'enter_valid_email'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePwd,
                        decoration: InputDecoration(
                          labelText: 'password'.tr,
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePwd ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                          ),
                        ),
                        validator: (v) {
                          if ((v ?? '').isEmpty) return 'enter_valid_password'.tr;
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _impersonateCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'login_dev_impersonate_label'.tr,
                          hintText: 'login_dev_impersonate_placeholder'.tr,
                          border: const OutlineInputBorder(),
                          helperText: 'login_dev_impersonate_hint'.tr,
                          helperMaxLines: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Text(
                                hasImp
                                    ? 'login_dev_login_as_button'.tr
                                    : 'login_dev_login_button'.tr,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
