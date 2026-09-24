import 'package:flutter/material.dart';
import '../utils/error_messages.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../main.dart' show authRepositoryProvider;
import '../models/bank_verification_model.dart';
import '../models/earnings_model.dart';
import '../repositories/bank_verification_repository.dart';
import '../state/partner_app_state.dart';

class EarningsTab extends ConsumerStatefulWidget {
  const EarningsTab({Key? key}) : super(key: key);

  @override
  ConsumerState<EarningsTab> createState() => _EarningsTabState();
}

class _EarningsTabState extends ConsumerState<EarningsTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => partnerAppState.refreshEarnings());
  }

  /// Buckets the last 50 ledger transactions into the last 7 calendar days
  /// (oldest first) and this week vs. the previous week, so the trend chart
  /// reflects real earnings instead of scripted numbers.
  ({List<double> days, List<String> labels, double thisWeek, double lastWeek}) _weeklyTrend() {
    final transactions = partnerAppState.earnings?.transactions ?? [];
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final days = List<double>.filled(7, 0);
    final labels = List<String>.filled(7, '');
    const weekdayAbbrev = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (var i = 0; i < 7; i++) {
      final date = todayDate.subtract(Duration(days: 6 - i));
      labels[i] = weekdayAbbrev[date.weekday - 1];
    }
    double thisWeek = 0;
    double lastWeek = 0;
    for (final t in transactions) {
      if (t.entryType != 'JOB_EARNING') continue;
      final parsed = DateTime.tryParse(t.createdAt);
      if (parsed == null) continue;
      final date = DateTime(parsed.year, parsed.month, parsed.day);
      final daysAgo = todayDate.difference(date).inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        days[6 - daysAgo] += t.amount;
        thisWeek += t.amount;
      } else if (daysAgo >= 7 && daysAgo < 14) {
        lastWeek += t.amount;
      }
    }
    return (days: days, labels: labels, thisWeek: thisWeek, lastWeek: lastWeek);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => partnerAppState.refreshEarnings(),
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Earnings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('January 2026 • Mira Road Zone', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.grey.shade900, Colors.grey.shade800]),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AVAILABLE BALANCE', style: TextStyle(fontSize: 11, color: Colors.white70)),
                const SizedBox(height: 4),
                Text('₹${partnerAppState.walletBalance}',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('This Month', style: TextStyle(fontSize: 11, color: Colors.white70)),
                          const SizedBox(height: 2),
                          Text('₹${(partnerAppState.earnings?.monthEarnings ?? 0).round()}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showWithdrawModal(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Withdraw', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Earnings Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('Today', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text('₹${partnerAppState.todayEarnings}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('This Week', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text('₹${(partnerAppState.earnings?.weekEarnings ?? 0).round()}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('This Month', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text('₹${(partnerAppState.earnings?.monthEarnings ?? 0).round()}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Builder(builder: (context) {
            final trend = _weeklyTrend();
            final maxVal = trend.days.fold<double>(0, (m, v) => v > m ? v : m);
            final chartMax = maxVal <= 0 ? 100.0 : maxVal * 1.2;
            final changePct = trend.lastWeek > 0 ? ((trend.thisWeek - trend.lastWeek) / trend.lastWeek * 100) : null;
            return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Weekly Trend', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    if (changePct != null)
                      Text('${changePct >= 0 ? '↑' : '↓'} ${changePct.abs().round()}%',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: changePct >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626))),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartMax,
                      barGroups: [
                        for (var i = 0; i < 7; i++) _barGroup(i, trend.days[i]),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) => Text(trend.labels[v.toInt()],
                                style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            ),
          );
          }),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => _showPaymentHistory(),
              child: const Text('View full payment history', style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF))),
            ),
          ),
        ],
      ),
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y, color: AppTheme.saffron, width: 16, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }

  void _showWithdrawModal() {
    final vendorId = ref.read(authRepositoryProvider).getCurrentUserId();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: _WithdrawModal(vendorId: vendorId),
      ),
    );
  }

  void _showPaymentHistory() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: _PaymentHistoryModal(transactions: partnerAppState.earnings?.transactions ?? []),
      ),
    );
  }
}

class _WithdrawModal extends StatefulWidget {
  final String? vendorId;
  const _WithdrawModal({required this.vendorId});

  @override
  State<_WithdrawModal> createState() => _WithdrawModalState();
}

class _WithdrawModalState extends State<_WithdrawModal> {
  final _bankVerificationRepository = BankVerificationRepository();
  late TextEditingController _amountController;

  bool _loadingStatus = true;
  BankVerificationStatus _status = BankVerificationStatus.notSubmitted;
  String? _accountLast4;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: '5000');
    _loadBankStatus();
  }

  Future<void> _loadBankStatus() async {
    final vendorId = widget.vendorId;
    if (vendorId == null) {
      setState(() => _loadingStatus = false);
      return;
    }
    try {
      final info = await _bankVerificationRepository.fetchStatus(vendorId);
      if (!mounted) return;
      setState(() {
        _status = info.status;
        _accountLast4 = info.accountNumberLast4;
        _loadingStatus = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingStatus) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_status != BankVerificationStatus.verified) {
      return _unverifiedPrompt();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Withdraw to Bank', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Instant transfer to verified account (XXXX-${_accountLast4 ?? "----"})',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          const Text('Amount to Withdraw', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefix: const Text('₹ ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text('Available: ₹${partnerAppState.walletBalance}',
              style: const TextStyle(fontSize: 10, color: Color(0xFF059669))),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = int.tryParse(_amountController.text);
                    if (amount == null || amount < 100 || amount > partnerAppState.walletBalance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a valid amount within your available balance')),
                      );
                      return;
                    }
                    try {
                      await partnerAppState.withdraw(amount);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('₹$amount withdrawn successfully!')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Withdraw Now', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _unverifiedPrompt() {
    final pending = _status == BankVerificationStatus.pending;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: pending ? const Color(0xFFFEF3C7) : const Color(0xFFFFE3D1),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(pending ? '⏳' : '🏦', style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(height: 14),
          Text(
            pending ? 'Bank Verification In Progress' : 'Add Your Bank Account',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            pending
                ? "We're confirming your bank account with a small verification credit. This usually takes a minute - try again shortly."
                : 'To withdraw earnings, add and verify a bank account first. We confirm it with a small real bank credit before your first withdrawal.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Not Now'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: pending
                      ? _loadBankStatus
                      : () async {
                          Navigator.pop(context);
                          await context.push('/bank-verification');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.saffron,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(pending ? 'Refresh' : 'Add Bank Account', style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentHistoryModal extends StatelessWidget {
  final List<LedgerTransaction> transactions;
  const _PaymentHistoryModal({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Payment History & Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PDF Export - Demo')),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('📄 Export PDF', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('CSV Export - Demo')),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('📊 Export CSV', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Recent Transactions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: transactions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No transactions yet', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: transactions.map((t) {
                        final isCredit = t.amount >= 0;
                        return _transactionRow(
                          t.description ?? t.entryType,
                          t.createdAt,
                          '${isCredit ? '+' : '-'} ₹${t.amount.abs().round()}',
                          isCredit ? Colors.green : Colors.red,
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionRow(String title, String subtitle, String amount, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(amount, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
