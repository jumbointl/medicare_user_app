
class CityModel {
  final int? id;
  final String? title;
  final int? stateId;
  final String? latitude;
  final String? longitude;
  final int? active;
  final String? createdAt;
  final String? updatedAt;
  final String? stateTitle;
  final int? clinicId;
  final String? clinicTitle;

  CityModel({
    this.id,
    this.title,
    this.stateId,
    this.latitude,
    this.longitude,
    this.active,
    this.createdAt,
    this.updatedAt,
    this.stateTitle,
    this.clinicId,
    this.clinicTitle,
  });

  // Factory method to create a Location object from JSON
  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as int?,
      title: (json['title'] ?? json['city_title']) as String?,
      stateId: json['state_id'] as int?,
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      active: json['active'] as int?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      stateTitle: json['state_title'] as String?,
      clinicId: json['clinic_id'] as int?,
      clinicTitle: json['clinic_title'] as String?,
    );
  }
  }