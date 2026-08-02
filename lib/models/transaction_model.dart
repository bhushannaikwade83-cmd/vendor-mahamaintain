class Transaction {
  final String id;
  final String userId;
  final String? propertyId;
  final double amount;
  final String description;
  final String status; // pending, completed, failed
  final String type; // payment, refund, etc.
  final String? paymentId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Transaction({
    required this.id,
    required this.userId,
    this.propertyId,
    required this.amount,
    required this.description,
    required this.status,
    required this.type,
    this.paymentId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      propertyId: json['property_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      type: json['type'] ?? '',
      paymentId: json['payment_id'],
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
      'user_id': userId,
      'property_id': propertyId,
      'amount': amount,
      'description': description,
      'status': status,
      'type': type,
      'payment_id': paymentId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Transaction copyWith({
    String? id,
    String? userId,
    String? propertyId,
    double? amount,
    String? description,
    String? status,
    String? type,
    String? paymentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      propertyId: propertyId ?? this.propertyId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      status: status ?? this.status,
      type: type ?? this.type,
      paymentId: paymentId ?? this.paymentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
