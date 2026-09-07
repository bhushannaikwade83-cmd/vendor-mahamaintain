enum VendorVerificationStatus {
  unverified,
  digilockerConnected,
  underReview,
  verified,
  rejected,
}

VendorVerificationStatus vendorVerificationStatusFromString(String? value) {
  switch (value) {
    case 'DIGILOCKER_CONNECTED':
      return VendorVerificationStatus.digilockerConnected;
    case 'UNDER_REVIEW':
      return VendorVerificationStatus.underReview;
    case 'VERIFIED':
      return VendorVerificationStatus.verified;
    case 'REJECTED':
      return VendorVerificationStatus.rejected;
    case 'UNVERIFIED':
    default:
      return VendorVerificationStatus.unverified;
  }
}

class VendorVerificationStatusInfo {
  final VendorVerificationStatus status;
  final bool digilockerConnected;
  final bool identityVerified;
  final bool panVerified;
  final DateTime? updatedAt;

  const VendorVerificationStatusInfo({
    required this.status,
    required this.digilockerConnected,
    required this.identityVerified,
    required this.panVerified,
    this.updatedAt,
  });

  factory VendorVerificationStatusInfo.initial() => const VendorVerificationStatusInfo(
        status: VendorVerificationStatus.unverified,
        digilockerConnected: false,
        identityVerified: false,
        panVerified: false,
      );

  factory VendorVerificationStatusInfo.fromJson(Map<String, dynamic> json) {
    return VendorVerificationStatusInfo(
      status: vendorVerificationStatusFromString(json['status'] as String?),
      digilockerConnected: json['digilocker_connected'] == true,
      identityVerified: json['identity_verified'] == true,
      panVerified: json['pan_verified'] == true,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
    );
  }
}
