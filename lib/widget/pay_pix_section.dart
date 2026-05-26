import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../model/appointment_model.dart';
import '../services/pix_service.dart';

/// Sección de pago PIX para el paciente en la pantalla
/// `appointment_details_page`. Muestra un botón verde "Pagar con PIX"
/// solo cuando paymentStatus != 'Paid' y el appointment no está cancelado.
/// Al tocarlo, llama POST /v1/pix/init con auth del paciente (helper
/// PostService usa el token de SharedPreferences) y abre un BottomSheet
/// con monto + QR + botón "Copia y pega" que copia el URL al clipboard.
///
/// Reglas backend (medicare-node-api):
///  - Si caller es patient.user_id del appointment → ownership check OK
///  - Caller paciente → NO emite al panel-TV (paga en mobile)
///
/// El polling de "ya pagó" lo hace el componente padre al cerrar el
/// BottomSheet (refresca el appointment).
class PayPixSection extends StatefulWidget {
  const PayPixSection({
    super.key,
    required this.appointment,
    this.onPaid,
  });
  final AppointmentModel appointment;
  final VoidCallback? onPaid;

  @override
  State<PayPixSection> createState() => _PayPixSectionState();
}

class _PayPixSectionState extends State<PayPixSection> {
  bool _busy = false;
  String? _error;

  bool get _isPaid =>
      (widget.appointment.paymentStatus ?? '').toLowerCase() == 'paid';

  Future<void> _handlePay() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final apptId = int.tryParse(widget.appointment.id?.toString() ?? '');
      final clinicId = widget.appointment.clinicId;
      final feeRaw = widget.appointment.fee;
      final amount = feeRaw is num
          ? feeRaw
          : num.tryParse(feeRaw?.toString() ?? '') ?? 0;

      if (apptId == null || clinicId == null) {
        setState(() => _error = 'pix.invalidAppointment'.tr);
        return;
      }
      if (amount <= 0) {
        setState(() => _error = 'pix.invalidAmount'.tr);
        return;
      }

      final res = await PixService.initPix(
        appointmentId: apptId,
        clinicId: clinicId,
        amount: amount,
        description: widget.appointment.type == 'OPD'
            ? 'Consulta presencial #$apptId'
            : 'Cita #$apptId',
      );
      if (!mounted) return;
      final inner = res?['data'];
      if (inner is! Map<String, dynamic> || inner['url'] == null) {
        setState(() => _error = res?['message']?.toString() ?? 'pix.error'.tr);
        return;
      }
      await _showPixSheet(inner);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showPixSheet(Map<String, dynamic> data) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PixSheet(payload: data, type: widget.appointment.type),
    );
    // Tras cerrar el sheet, refrescar el appointment (puede haber sido
    // marcado Paid en otra pestaña / por el simulate del cliente).
    widget.onPaid?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPaid) return const SizedBox.shrink();
    final status = (widget.appointment.status ?? '').toLowerCase();
    if (status == 'cancelled' || status == 'rejected') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: _busy ? null : _handlePay,
            icon: const Icon(Icons.qr_code_2, color: Colors.white),
            label: Text(
              _busy ? '...' : 'pix.payNow'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _PixSheet extends StatelessWidget {
  const _PixSheet({required this.payload, this.type});
  final Map<String, dynamic> payload;
  final String? type;

  @override
  Widget build(BuildContext context) {
    final url = payload['url']?.toString() ?? '';
    final amount = payload['amount'];
    final processId = payload['process_id']?.toString() ?? '';
    final description = payload['description']?.toString() ?? '';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'pix.title'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            if (amount != null)
              Text(
                'G\$ ${_formatGs(amount)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF15803D),
                ),
              ),
            if (description.isNotEmpty)
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: url,
                size: 220,
                version: QrVersions.auto,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Process ID: $processId',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('pix.copied'.tr),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_outlined),
                label: Text('pix.copyPaste'.tr),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'pix.hint'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('close'.tr),
            ),
          ],
        ),
      ),
    );
  }

  String _formatGs(dynamic v) {
    final n = v is num ? v : num.tryParse(v.toString()) ?? 0;
    final intPart = n.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write('.');
      buf.write(intPart[i]);
    }
    return buf.toString();
  }
}
