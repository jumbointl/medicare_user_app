import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/appointment_reschedule_controller.dart';
import '../model/doctors_model.dart';

/// User-facing reschedule page.
/// Pass the appointment + (optionally) the doctor so we can client-side
/// gate the submit button. The backend re-validates regardless.
class RescheduleAppointmentPage extends StatefulWidget {
  final String appointmentId;
  final DateTime appointmentStart;
  final String appointmentType; // 'Video Consultant' | 'OPD' | 'Emergency'
  final String? paymentStatus;  // 'Paid' | 'Unpaid' | 'Refunded' | null
  final DoctorsModel? doctor;

  const RescheduleAppointmentPage({
    super.key,
    required this.appointmentId,
    required this.appointmentStart,
    required this.appointmentType,
    this.paymentStatus,
    this.doctor,
  });

  @override
  State<RescheduleAppointmentPage> createState() => _RescheduleAppointmentPageState();
}

class _RescheduleAppointmentPageState extends State<RescheduleAppointmentPage> {
  DateTime? _date;
  TimeOfDay? _time;
  final _notesCtrl = TextEditingController();
  late final AppointmentRescheduleController _controller =
      Get.put(AppointmentRescheduleController(), tag: 'resch_${widget.appointmentId}');

  bool get _isVideo => widget.appointmentType == 'Video Consultant';
  bool get _isPaid => widget.paymentStatus?.toLowerCase() == 'paid';

  int get _allowedFlag {
    if (widget.doctor == null) return 0;
    return _isVideo
        ? (widget.doctor!.videoAutoRescheduledAllowed ?? 0)
        : (widget.doctor!.autoRescheduledAllowed ?? 0);
  }

  int get _beforeMinutes {
    if (widget.doctor == null) return 1440;
    return _isVideo
        ? (widget.doctor!.videoAutoRescheduledAllowedBeforeMinutes ?? 1440)
        : (widget.doctor!.autoRescheduledAllowedBeforeMinutes ?? 1440);
  }

  bool get _autoEligible {
    if (!_isPaid) return true;
    if (_allowedFlag != 1) return false;
    final deadline = widget.appointmentStart.subtract(Duration(minutes: _beforeMinutes));
    return DateTime.now().isBefore(deadline);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (_date == null || _time == null) {
      Get.snackbar('Missing data', 'Pick a date and time');
      return;
    }
    final dateStr = '${_date!.year.toString().padLeft(4, '0')}-'
        '${_date!.month.toString().padLeft(2, '0')}-'
        '${_date!.day.toString().padLeft(2, '0')}';
    final timeStr = '${_time!.hour.toString().padLeft(2, '0')}:'
        '${_time!.minute.toString().padLeft(2, '0')}';

    final result = await _controller.submitReschedule(
      appointmentId: widget.appointmentId,
      date: dateStr,
      timeSlots: timeStr,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    if (!mounted) return;
    if (result.mode == 'rescheduled') {
      Get.snackbar('Success', 'Appointment rescheduled');
      Navigator.of(context).pop(true);
    } else if (result.mode == 'reschedule_request') {
      Get.snackbar(
        'Pending approval',
        result.message ?? 'Reschedule request sent to doctor',
        duration: const Duration(seconds: 3),
      );
      Navigator.of(context).pop(true);
    } else {
      Get.snackbar('Error', result.message ?? 'Could not reschedule');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reschedule appointment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _autoEligible
                  ? 'You can reschedule directly.'
                  : 'Your request will be sent to the doctor for approval.',
              style: TextStyle(
                color: _autoEligible ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_isPaid && _allowedFlag != 1)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Auto-reschedule is disabled by the doctor.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            if (_isPaid && _allowedFlag == 1 && !_autoEligible)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Auto-reschedule window closed (must be > $_beforeMinutes min before appointment).',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('New date'),
              subtitle: Text(_date == null
                  ? 'Pick a date'
                  : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            ListTile(
              title: const Text('New time'),
              subtitle: Text(_time == null
                  ? 'Pick a time'
                  : _time!.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: _pickTime,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _controller.isSubmitting.value ? null : _submit,
                    child: _controller.isSubmitting.value
                        ? const CircularProgressIndicator()
                        : Text(_autoEligible
                            ? 'Reschedule now'
                            : 'Send request to doctor'),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
