class NearbyPincode {
  final String pincode;
  final double distance; // Distance in km
  final String area; // Area name (e.g., "Wakad", "Hinjewadi")
  final int priority; // Priority order for expansion (1=closest)

  const NearbyPincode({
    required this.pincode,
    required this.distance,
    required this.area,
    required this.priority,
  });

  factory NearbyPincode.fromJson(Map<String, dynamic> json) {
    return NearbyPincode(
      pincode: json['pincode'] ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      area: json['area'] ?? '',
      priority: json['priority'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pincode': pincode,
      'distance': distance,
      'area': area,
      'priority': priority,
    };
  }
}

/// Tracks job expansion history
class JobExpansionHistory {
  final int jobId;
  final String originalPincode;
  final List<String> expandedPincodes; // List of pincodes job was expanded to
  final DateTime expandedAt;
  final String reason; // "no_acceptance", "low_acceptance_rate", etc.

  const JobExpansionHistory({
    required this.jobId,
    required this.originalPincode,
    required this.expandedPincodes,
    required this.expandedAt,
    required this.reason,
  });

  factory JobExpansionHistory.fromJson(Map<String, dynamic> json) {
    return JobExpansionHistory(
      jobId: json['job_id'] ?? 0,
      originalPincode: json['original_pincode'] ?? '',
      expandedPincodes: List<String>.from(json['expanded_pincodes'] ?? []),
      expandedAt: json['expanded_at'] != null
          ? DateTime.parse(json['expanded_at'])
          : DateTime.now(),
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'original_pincode': originalPincode,
      'expanded_pincodes': expandedPincodes,
      'expanded_at': expandedAt.toIso8601String(),
      'reason': reason,
    };
  }
}
