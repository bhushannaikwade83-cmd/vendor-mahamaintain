class Society {
  final int id;
  final String name;
  final String? phase;
  final String area;
  final int units;
  final String? contactName;
  final String? contactPhone;
  final bool hasAmc;
  final String? accessNotes;
  final double? latitude;
  final double? longitude;

  const Society({
    required this.id,
    required this.name,
    this.phase,
    required this.area,
    required this.units,
    this.contactName,
    this.contactPhone,
    required this.hasAmc,
    this.accessNotes,
    this.latitude,
    this.longitude,
  });

  factory Society.fromJson(Map<String, dynamic> json) {
    return Society(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? '',
      phase: json['phase'] as String?,
      area: (json['area'] as String?) ?? '',
      units: (json['units'] as int?) ?? 0,
      contactName: json['contact_name'] as String?,
      contactPhone: json['contact_phone'] as String?,
      hasAmc: json['has_amc'] as bool? ?? false,
      accessNotes: json['access_notes'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
