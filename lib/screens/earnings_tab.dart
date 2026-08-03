import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/app_theme.dart';
import '../state/partner_app_state.dart';

class EarningsTab extends StatefulWidget {
  const EarningsTab({Key? key}) : super(key: key);

  @override
  State<EarningsTab> createState() => _EarningsTabState();
}

class _EarningsTabState extends State<EarningsTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                        children: const [
                          Text('This Month', style: TextStyle(fontSize: 11, color: Colors.white70)),
                          SizedBox(height: 2),
                          Text('₹42,650', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
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
                    children: const [
                      Text('This Week', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      SizedBox(height: 4),
                      Text('₹11,400', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    children: const [
                      Text('This Month', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      SizedBox(height: 4),
                      Text('₹42,650', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
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
                    const Text('↑ 18%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 7000,
                      barGroups: [
                        _barGroup(0, 3200),
                        _barGroup(1, 4100),
                        _barGroup(2, 2850),
                        _barGroup(3, 5100),
                        _barGroup(4, 3900),
                        _barGroup(5, 6200),
                        _barGroup(6, 2850),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) => Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][v.toInt()],
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
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => _showPaymentHistory(),
              child: const Text('View full payment history', style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF))),
            ),
          ),
        ],
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
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: _WithdrawModal(),
      ),
    );
  }

  void _showPaymentHistory() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const _PaymentHistoryModal(),
      ),
    );
  }
}

class _WithdrawModal extends StatefulWidget {
  @override
  State<_WithdrawModal> createState() => _WithdrawModalState();
}

class _WithdrawModalState extends State<_WithdrawModal> {
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: '5000');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Withdraw to Bank', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Instant transfer to linked account (XXXX-4521)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
                  onPressed: () {
                    final amount = int.tryParse(_amountController.text);
                    if (amount != null && partnerAppState.withdraw(amount)) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('₹$amount withdrawn successfully!')),
                      );
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
}

class _PaymentHistoryModal extends StatelessWidget {
  const _PaymentHistoryModal();

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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _transactionRow('Job #107 • Kavita Nair', 'UPI • Jan 16', '+ ₹720', Colors.green),
                  _transactionRow('Job #108 • Ramesh Iyer', 'UPI • Jan 15', '+ ₹950', Colors.green),
                  _transactionRow('Job #109 • Pooja Malhotra', 'UPI • Jan 14', '+ ₹2,400', Colors.green),
                  _transactionRow('Weekly Incentive', 'Bonus • Jan 13', '+ ₹1,500', Colors.green),
                ],
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
