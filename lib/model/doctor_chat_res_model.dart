class DoctorChatResModel {
  final int id;
  final int? userId;
  final String name;
  final String department;
  final String clinicTitle;
  final String image;
  final String exYear;
  final String specialization;
  final String rating;
  final String reviewCount;
  final String? totalAppointmentDone;
  DoctorChatResModel({
    required this.id,
    required this.name,
    required this.department,
    required this.rating,
  required this.image,
  required this.clinicTitle,
  required this.exYear,
  required this.specialization,
    required this.reviewCount,
    required this.userId,
    required this.totalAppointmentDone,

  });

  factory DoctorChatResModel.fromJson(Map<String, dynamic> json) {
    return DoctorChatResModel(
      userId: json['user_id'],
      id: json['id'],
      name: "${json['f_name']} ${json['l_name']}",
      department: json['department_name'],
      rating: json['average_rating']?.toString() ?? "0",
      clinicTitle: json['clinic_title'] ?? "",
      image: json['image'] ?? "",
      exYear: json['ex_year'].toString() ,
      specialization: json['specialization'] ?? "",
      reviewCount: json['review_count']?.toString() ?? "0",
      totalAppointmentDone: json['total_appointment_done']?.toString() ?? "0",
    );
  }
}
