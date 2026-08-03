import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../state/partner_app_state.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1F2937), Color(0xFF111827)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFE2E8F0), width: 2),
                ),
                alignment: Alignment.center,
                child: const Text('👤', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Suresh Patil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('Top Rated Partner • 4.92', style: TextStyle(fontSize: 11, color: Color(0xFF059669))),
                    SizedBox(height: 2),
                    Text('Electrician • Plumber • Carpenter • Mira Road',
                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                    children: const [
                      Text('Jobs Done', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      SizedBox(height: 4),
                      Text('487', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      Text('Rating', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      SizedBox(height: 4),
                      Text('4.92', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
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
                      Text('Response', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      SizedBox(height: 4),
                      Text('98%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('My Service Categories', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ['Electrician', 'Plumber', 'AC Repair', 'Appliance Repair', 'Carpenter', 'Pest Control']
                .map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(tag, style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _menuItem('🎓', 'Training Videos & Certifications', () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('12 training videos available')),
                    )),
                _divider(),
                _menuItem('🆘', 'Help & Emergency Support', () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Creating support ticket...')),
                    )),
                _divider(),
                _menuItem('📄', 'Documents & Verification', () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All documents verified ✓')),
                    )),
                _divider(),
                _menuItem('📊', 'GPS Error Analytics (Admin)', () => _showGpsAnalytics()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('GPS Tracking Settings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Error Simulation Frequency (Demo)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _freqButton('Low', GpsErrorFrequency.low)),
                    const SizedBox(width: 6),
                    Expanded(child: _freqButton('Medium', GpsErrorFrequency.medium)),
                    const SizedBox(width: 6),
                    Expanded(child: _freqButton('High', GpsErrorFrequency.high)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Affects Water Purifier & other jobs', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Logout?'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.go('/login');
                        },
                        child: const Text('Logout', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout from Partner Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(String icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, color: Color(0xFFF1F5F9));
  }

  Widget _freqButton(String label, GpsErrorFrequency freq) {
    final active = partnerAppState.errorFrequency == freq;
    return InkWell(
      onTap: () => setState(() => partnerAppState.setErrorFrequency(freq)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFD1FAE5) : Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? const Color(0xFF059669) : Colors.black87)),
      ),
    );
  }

  void _showGpsAnalytics() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('GPS Error Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Admin Dashboard • Mira Road Zone', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text('Total Errors', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text('${partnerAppState.activeTrackingErrors.length}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text('Water Purifier', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text('${partnerAppState.activeTrackingErrors.where((e) => e.service == 'Water Purifier').length}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF97316))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: const [
                          Text('Error Rate', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          SizedBox(height: 4),
                          Text('0%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Note: Errors tracked during job completion', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    partnerAppState.clearTrackingErrors();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Clear Analytics Data'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
