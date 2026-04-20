import '../model/appointment_model.dart';

String buildAppointmentTimeRange(AppointmentModel appointment) {
  final date = appointment.date ?? '';
  final time = appointment.timeSlot ?? '';
  final duration = appointment.durationMinutes ?? 15;

  final start = DateTime.parse('$date $time');
  final end = start.add(Duration(minutes: duration));

  String two(int n) => n.toString().padLeft(2, '0');

  return '${two(start.hour)}:${two(start.minute)} - ${two(end.hour)}:${two(end.minute)}';
}