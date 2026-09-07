class LedgerTransaction {
  final int id;
  final int? bookingId;
  final String entryType;
  final double amount;
  final String? description;
  final String createdAt;

  LedgerTransaction({
    required this.id,
    required this.bookingId,
    required this.entryType,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  factory LedgerTransaction.fromJson(Map<String, dynamic> json) {
    return LedgerTransaction(
      id: json['id'] as int,
      bookingId: json['booking_id'] as int?,
      entryType: (json['entry_type'] as String?) ?? '',
      amount: ((json['amount'] as num?) ?? 0).toDouble(),
      description: json['description'] as String?,
      createdAt: (json['created_at'] as String?) ?? '',
    );
  }
}

class VendorEarnings {
  final double walletBalance;
  final double todayEarnings;
  final double weekEarnings;
  final double monthEarnings;
  final int jobsDone;
  final List<LedgerTransaction> transactions;

  VendorEarnings({
    required this.walletBalance,
    required this.todayEarnings,
    required this.weekEarnings,
    required this.monthEarnings,
    required this.jobsDone,
    required this.transactions,
  });

  factory VendorEarnings.fromJson(Map<String, dynamic> json) {
    return VendorEarnings(
      walletBalance: ((json['wallet_balance'] as num?) ?? 0).toDouble(),
      todayEarnings: ((json['today_earnings'] as num?) ?? 0).toDouble(),
      weekEarnings: ((json['week_earnings'] as num?) ?? 0).toDouble(),
      monthEarnings: ((json['month_earnings'] as num?) ?? 0).toDouble(),
      jobsDone: (json['jobs_done'] as int?) ?? 0,
      transactions: ((json['transactions'] as List?) ?? [])
          .map((e) => LedgerTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
