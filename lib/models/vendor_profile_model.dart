class VendorProfile {
  final String id;
  final String phoneNumber;
  final String? name;
  final String? email;
  final String pincode;
  final List<int> enrolledServiceIds; // IDs of services vendor provides
  final bool isKycVerified;
  final bool isBankVerified;
  final String? deviceToken; // For push notifications
  final DateTime createdAt;
  final DateTime? updatedAt;

  VendorProfile({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.email,
    required this.pincode,
    required this.enrolledServiceIds,
    required this.isKycVerified,
    required this.isBankVerified,
    this.deviceToken,
    required this.createdAt,
    this.updatedAt,
  });

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    return VendorProfile(
      id: json['id'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      name: json['name'],
      email: json['email'],
      pincode: json['pincode'] ?? '',
      enrolledServiceIds: json['enrolled_service_ids'] != null
          ? List<int>.from(json['enrolled_service_ids'] as List)
          : [],
      isKycVerified: json['is_kyc_verified'] ?? false,
      isBankVerified: json['is_bank_verified'] ?? false,
      deviceToken: json['device_token'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'name': name,
      'email': email,
      'pincode': pincode,
      'enrolled_service_ids': enrolledServiceIds,
      'is_kyc_verified': isKycVerified,
      'is_bank_verified': isBankVerified,
      'device_token': deviceToken,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  VendorProfile copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? email,
    String? pincode,
    List<int>? enrolledServiceIds,
    bool? isKycVerified,
    bool? isBankVerified,
    String? deviceToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorProfile(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      pincode: pincode ?? this.pincode,
      enrolledServiceIds: enrolledServiceIds ?? this.enrolledServiceIds,
      isKycVerified: isKycVerified ?? this.isKycVerified,
      isBankVerified: isBankVerified ?? this.isBankVerified,
      deviceToken: deviceToken ?? this.deviceToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
