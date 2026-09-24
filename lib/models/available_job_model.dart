enum JobOfferStatus { pending, accepted, rejected, expired }

class AvailableJob {
  final int id;
  final String customerName;
  final String customerPhone;
  final String serviceName;
  final int serviceCategoryId;
  final String address;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final int amount;
  final String? scheduledDate; // null for instant booking
  final String? scheduledTime; // time slot for booking
  final String? description; // service description/notes
  final String bookingType; // 'instant' or 'slot'
  final int customerId;
  final DateTime createdAt;
  final DateTime expiresAt; // After this time, request expires
  JobOfferStatus status; // Vendor's response status
  final String? otp; // One-time password for verification

  AvailableJob({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.serviceName,
    required this.serviceCategoryId,
    required this.address,
    required this.pincode,
    this.latitude,
    this.longitude,
    required this.amount,
    this.scheduledDate,
    this.scheduledTime,
    this.description,
    required this.bookingType,
    required this.customerId,
    required this.createdAt,
    required this.expiresAt,
    this.status = JobOfferStatus.pending,
    this.otp,
  });

  factory AvailableJob.fromJson(Map<String, dynamic> json) {
    return AvailableJob(
      id: json['id'] ?? 0,
      customerName: json['customer_name'] ?? 'Unknown',
      customerPhone: json['customer_phone'] ?? '',
      serviceName: json['service_name'] ?? '',
      serviceCategoryId: json['service_category_id'] ?? 0,
      address: json['location_address'] ?? '',
      pincode: json['pincode'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      amount: json['budget']?.toInt() ?? json['amount']?.toInt() ?? 0,
      scheduledDate: json['scheduled_date'],
      scheduledTime: json['scheduled_time'],
      description: json['description'],
      bookingType: json['booking_type'] ?? 'instant',
      customerId: json['customer_id'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : DateTime.now().add(const Duration(minutes: 10)),
      status: _jobOfferStatusFromString(json['status'] ?? 'pending'),
      otp: json['otp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'service_name': serviceName,
      'service_category_id': serviceCategoryId,
      'location_address': address,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'budget': amount,
      'scheduled_date': scheduledDate,
      'scheduled_time': scheduledTime,
      'description': description,
      'booking_type': bookingType,
      'customer_id': customerId,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'status': _jobOfferStatusToString(status),
      'otp': otp,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  int get timeRemainingSeconds =>
      expiresAt.difference(DateTime.now()).inSeconds;

  bool get isPending => status == JobOfferStatus.pending;
  bool get isAccepted => status == JobOfferStatus.accepted;

  static JobOfferStatus _jobOfferStatusFromString(String status) {
    switch (status) {
      case 'accepted':
        return JobOfferStatus.accepted;
      case 'rejected':
        return JobOfferStatus.rejected;
      case 'expired':
        return JobOfferStatus.expired;
      default:
        return JobOfferStatus.pending;
    }
  }

  static String _jobOfferStatusToString(JobOfferStatus status) {
    switch (status) {
      case JobOfferStatus.pending:
        return 'pending';
      case JobOfferStatus.accepted:
        return 'accepted';
      case JobOfferStatus.rejected:
        return 'rejected';
      case JobOfferStatus.expired:
        return 'expired';
    }
  }
}
