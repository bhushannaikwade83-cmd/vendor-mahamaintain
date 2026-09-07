enum JobStatus { newJob, accepted, inProgress, completed, cancelled }

JobStatus jobStatusFromString(String s) {
  switch (s) {
    case 'new':
      return JobStatus.newJob;
    case 'accepted':
      return JobStatus.accepted;
    case 'in_progress':
      return JobStatus.inProgress;
    case 'completed':
      return JobStatus.completed;
    case 'cancelled':
      return JobStatus.cancelled;
  }
  return JobStatus.newJob;
}

class Job {
  final int id;
  final String customer;
  final String address;
  final String phone;
  final String service;
  final String type;
  final String duration;
  final int amount;
  JobStatus status;
  final String time;
  final String notes;
  final String distance;
  final String paymentMode;
  int? rating;
  String? beforePhoto;
  String? afterPhoto;
  String? otp;
  final double? latitude;
  final double? longitude;

  Job({
    required this.id,
    required this.customer,
    required this.address,
    required this.phone,
    required this.service,
    required this.type,
    required this.duration,
    required this.amount,
    required this.status,
    required this.time,
    this.notes = '',
    required this.distance,
    required this.paymentMode,
    this.rating,
    this.beforePhoto,
    this.afterPhoto,
    this.otp,
    this.latitude,
    this.longitude,
  });

  String get timeShort {
    final parts = time.split('•');
    return parts.length > 1 ? parts[1].trim() : time;
  }

  String get addressShort => address.split(',').first;

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as int,
      customer: (json['customer_name'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      phone: (json['customer_phone'] as String?) ?? '',
      service: (json['category_name'] as String?) ?? '',
      type: (json['service_type'] as String?) ?? '',
      duration: '',
      amount: ((json['amount'] as num?) ?? 0).round(),
      status: _bookingStatusToJobStatus((json['status'] as String?) ?? 'REQUESTED'),
      time: (json['scheduled_at'] as String?) ?? (json['created_at'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
      distance: '',
      paymentMode: (json['payment_mode'] as String?) ?? '',
      rating: json['rating'] as int?,
      beforePhoto: json['before_photo_url'] as String?,
      afterPhoto: json['after_photo_url'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

JobStatus _bookingStatusToJobStatus(String status) {
  switch (status) {
    case 'REQUESTED':
      return JobStatus.newJob;
    case 'ACCEPTED':
      return JobStatus.accepted;
    case 'IN_PROGRESS':
      return JobStatus.inProgress;
    case 'COMPLETED':
      return JobStatus.completed;
    case 'CANCELLED':
    case 'REJECTED':
      return JobStatus.cancelled;
  }
  return JobStatus.newJob;
}

