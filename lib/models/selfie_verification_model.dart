enum SelfieVerificationStatus { notSubmitted, pending, approved, rejected }

SelfieVerificationStatus selfieVerificationStatusFromString(String? value) {
  switch (value) {
    case 'PENDING':
      return SelfieVerificationStatus.pending;
    case 'APPROVED':
      return SelfieVerificationStatus.approved;
    case 'REJECTED':
      return SelfieVerificationStatus.rejected;
    case 'NOT_SUBMITTED':
    default:
      return SelfieVerificationStatus.notSubmitted;
  }
}

class SelfieVerificationInfo {
  final SelfieVerificationStatus status;
  final DateTime? uploadedAt;
  final DateTime? reviewedAt;

  const SelfieVerificationInfo({required this.status, this.uploadedAt, this.reviewedAt});

  factory SelfieVerificationInfo.initial() =>
      const SelfieVerificationInfo(status: SelfieVerificationStatus.notSubmitted);

  factory SelfieVerificationInfo.fromJson(Map<String, dynamic> json) {
    return SelfieVerificationInfo(
      status: selfieVerificationStatusFromString(json['status'] as String?),
      uploadedAt: json['uploaded_at'] != null ? DateTime.tryParse(json['uploaded_at'] as String) : null,
      reviewedAt: json['reviewed_at'] != null ? DateTime.tryParse(json['reviewed_at'] as String) : null,
    );
  }
}
