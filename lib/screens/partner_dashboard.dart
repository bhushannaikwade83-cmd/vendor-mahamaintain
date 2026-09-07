import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/error_messages.dart';
import '../config/app_theme.dart';
import '../state/partner_app_state.dart';
import '../widgets/app_toast.dart';
import '../widgets/job_details_sheet.dart';
import 'home_tab.dart';
import 'bookings_tab.dart';
import 'earnings_tab.dart';
import 'map_tab.dart';
import 'society_tab.dart';
import 'profile_tab.dart';

class PartnerDashboard extends StatefulWidget {
  const PartnerDashboard({Key? key}) : super(key: key);

  @override
  State<PartnerDashboard> createState() => _PartnerDashboardState();
}

class _PartnerDashboardState extends State<PartnerDashboard> {
  int _selectedTab = 0;
  Timer? _jobPollTimer;

  @override
  void initState() {
    super.initState();
    // Real "new job" alerts need Firebase Cloud Messaging (not wired to the
    // backend yet - see server/README.md design notes). Until then, poll
    // for new jobs periodically so the badge/list reflect real data instead
    // of showing fabricated notifications.
    _jobPollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      partnerAppState.refreshJobs();
    });
  }

  @override
  void dispose() {
    _jobPollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: partnerAppState,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedTab,
                    children: [
                      HomeTab(onJobTap: (id) => openJobDetailsSheet(context, id)),
                      BookingsTab(onJobTap: (id) => openJobDetailsSheet(context, id)),
                      const EarningsTab(),
                      MapTab(onJobTap: (id) => openJobDetailsSheet(context, id)),
                      SocietyTab(),
                      const ProfileTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNav(),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.saffron, AppTheme.saffronDark],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 40,
                      height: 40,
                      color: Colors.white,
                      alignment: Alignment.center,
                      child: const Text('🏢', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Maha Maintain Pro',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 2),
                      const Text('Partner App', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              try {
                await partnerAppState.toggleOnline();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(friendlyErrorMessage(e))),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: partnerAppState.isOnline ? const Color(0xFF059669) : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(partnerAppState.isOnline ? 'Online' : 'Offline',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _showNotifications(),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.gold,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text('${partnerAppState.newJobs.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    final newJobs = partnerAppState.newJobs;
    if (newJobs.isEmpty) {
      showNotificationsPanel(context, [
        NotificationItem(
          icon: Icons.notifications_none,
          color: Colors.grey,
          content: const Text('No new job requests right now', style: TextStyle(fontSize: 12)),
          onTap: null,
        ),
      ]);
      return;
    }
    showNotificationsPanel(
      context,
      newJobs
          .map((job) => NotificationItem(
                icon: Icons.notifications,
                color: AppTheme.saffron,
                content: Text('New job request: ${job.customer} (${job.service})', style: const TextStyle(fontSize: 12)),
                onTap: () => openJobDetailsSheet(context, job.id),
              ))
          .toList(),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navTab('🏠', 'Home', 0),
            _navTab('📋', 'Bookings', 1),
            _navTab('💰', 'Earnings', 2),
            _navTab('🗺️', 'Map', 3),
            _navTab('🏢', 'Society', 4),
            _navTab('👤', 'Profile', 5),
          ],
        ),
      ),
    );
  }

  Widget _navTab(String emoji, String label, int idx) {
    final active = _selectedTab == idx;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = idx),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active ? AppTheme.saffron : Colors.grey.shade600,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
