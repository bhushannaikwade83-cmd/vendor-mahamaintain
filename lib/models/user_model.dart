class User {
  final String id;
  final String phoneNumber;
  final String? name;
  final String? email;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSocietyRegistered;

  User({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.email,
    required this.createdAt,
    this.updatedAt,
    this.isSocietyRegistered = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      name: json['name'],
      email: json['email'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      isSocietyRegistered: json['is_society_registered'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'name': name,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_society_registered': isSocietyRegistered,
    };
  }

  User copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSocietyRegistered,
  }) {
    return User(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSocietyRegistered: isSocietyRegistered ?? this.isSocietyRegistered,
    );
  }
}
