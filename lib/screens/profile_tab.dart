import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../main.dart' show authRepositoryProvider;
import '../repositories/service_category_repository.dart';
import '../state/partner_app_state.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  final _categoryRepository = ServiceCategoryRepository();
  bool _loadingCategories = true;
  List<String> _myCategoryNames = [];

  @override
  void initState() {
    super.initState();
    partnerAppState.refreshEarnings();
    _loadMyCategories();
  }

  Future<void> _loadMyCategories() async {
    final vendorId = ref.read(authRepositoryProvider).getCurrentUserId();
    if (vendorId == null) {
      setState(() => _loadingCategories = false);
      return;
    }
    try {
      final all = await _categoryRepository.fetchCategories();
      final mine = await _categoryRepository.fetchVendorCategoryIds(vendorId);
      if (!mounted) return;
      setState(() {
        _myCategoryNames = all.where((c) => mine.contains(c.id)).map((c) => c.name).toList();
        _loadingCategories = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authRepository = ref.watch(authRepositoryProvider);
    final vendorName = authRepository.getCurrentVendorName() ?? 'Partner';
    final vendorPhone = authRepository.getCurrentVendorPhone();

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
                  children: [
                    Text(vendorName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    if (vendorPhone != null)
                      Text('+91 $vendorPhone', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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
                    children: [
                      const Text('Jobs Done', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text('${partnerAppState.earnings?.jobsDone ?? 0}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('My Service Categories', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_loadingCategories)
            const SizedBox(
              height: 20,
              child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else if (_myCategoryNames.isEmpty)
            const Text('No categories selected yet', style: TextStyle(fontSize: 11, color: Color(0xFF64748B)))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _myCategoryNames
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
                      const SnackBar(content: Text('Training content coming soon')),
                    )),
                _divider(),
                _menuItem('🆘', 'Help & Emergency Support', () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Support contact coming soon')),
                    )),
                _divider(),
                _menuItem('📄', 'Documents & Verification', () => context.push('/verification')),
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
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await ref.read(authRepositoryProvider).logout();
                          partnerAppState.resetSession();
                          if (context.mounted) context.go('/login');
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
}
