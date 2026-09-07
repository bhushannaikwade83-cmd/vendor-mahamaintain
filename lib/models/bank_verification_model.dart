enum BankVerificationStatus { notSubmitted, pending, verified, failed }

BankVerificationStatus bankVerificationStatusFromString(String? value) {
  switch (value) {
    case 'PENDING':
      return BankVerificationStatus.pending;
    case 'VERIFIED':
      return BankVerificationStatus.verified;
    case 'FAILED':
      return BankVerificationStatus.failed;
    case 'NOT_SUBMITTED':
    default:
      return BankVerificationStatus.notSubmitted;
  }
}

class BankVerificationInfo {
  final BankVerificationStatus status;
  final String? accountHolderName;
  final String? accountNumberLast4;
  final String? ifscCode;
  final String? registeredName;
  final bool? nameMatch;
  final DateTime? verifiedAt;

  const BankVerificationInfo({
    required this.status,
    this.accountHolderName,
    this.accountNumberLast4,
    this.ifscCode,
    this.registeredName,
    this.nameMatch,
    this.verifiedAt,
  });

  factory BankVerificationInfo.initial() =>
      const BankVerificationInfo(status: BankVerificationStatus.notSubmitted);

  factory BankVerificationInfo.fromJson(Map<String, dynamic> json) {
    return BankVerificationInfo(
      status: bankVerificationStatusFromString(json['status'] as String?),
      accountHolderName: json['account_holder_name'] as String?,
      accountNumberLast4: json['account_number_last4'] as String?,
      ifscCode: json['ifsc_code'] as String?,
      registeredName: json['registered_name'] as String?,
      nameMatch: json['name_match'] as bool?,
      verifiedAt: json['verified_at'] != null ? DateTime.tryParse(json['verified_at'] as String) : null,
    );
  }
}
