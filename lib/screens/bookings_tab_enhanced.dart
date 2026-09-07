import 'package:flutter/material.dart';
import '../models/job_models.dart';
import '../state/partner_app_state.dart';
import '../widgets/job_card.dart';

class _AppColors {
  static const brand = Color(0xFFFF9A4D);
  static const brandDeep = Color(0xFFF2762B);
  static const brandSoft = Color(0xFFFFF1E4);
  static const canvas = Color(0xFFFFF9F4);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFF0DFD0);
  static const ink = Color(0xFF2B1B10);
  static const inkSoft = Color(0xFF8A7361);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
}

class BookingsTabEnhanced extends StatefulWidget {
  final Function(int) onJobTap;
  const BookingsTabEnhanced({required this.onJobTap, Key? key}) : super(key: key);

  @override
  State<BookingsTabEnhanced> createState() => _BookingsTabEnhancedState();
}

class _BookingsTabEnhancedState extends State<BookingsTabEnhanced> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allJobs = [...partnerAppState.newJobs, ...partnerAppState.jobs];
    final instantJobs = allJobs.where((j) => j.bookingType == BookingType.instant).toList();
    final slotJobs = allJobs.where((j) => j.bookingType == BookingType.slot).toList();

    return RefreshIndicator(
      onRefresh: () => partnerAppState.refreshJobs(),
      child: Column(
        children: [
          // Tab Bar
          Container(
            color: _AppColors.card,
            child: TabBar(
              controller: _tabController,
              labelColor: _AppColors.brandDeep,
              unselectedLabelColor: _AppColors.inkSoft,
              indicatorColor: _AppColors.brand,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flash_on_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('Instant (${instantJobs.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('Slot (${slotJobs.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _instantJobsTab(instantJobs),
                _slotJobsTab(slotJobs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _instantJobsTab(List<Job> jobs) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: _AppColors.line),
            const SizedBox(height: 12),
            const Text('No instant jobs available'),
            const SizedBox(height: 4),
            Text('New jobs will appear here', style: TextStyle(fontSize: 12, color: _AppColors.inkSoft)),
          ],
        ),
      );
    }

    // Sort by: new first, then by distance (closest first)
    final sortedJobs = jobs..sort((a, b) {
      if (a.status != b.status) {
        return a.status == JobStatus.newJob ? -1 : 1;
      }
      return 0;
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statusChip('All (${sortedJobs.length})'),
                const SizedBox(width: 8),
                _statusChip('New (${sortedJobs.where((j) => j.status == JobStatus.newJob).length})', highlight: true),
                const SizedBox(width: 8),
                _statusChip('Active (${sortedJobs.where((j) => j.status == JobStatus.accepted || j.status == JobStatus.inProgress).length})'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Jobs List
          ...sortedJobs.map((job) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InstantJobCard(
                job: job,
                onTap: () => widget.onJobTap(job.id),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _slotJobsTab(List<Job> jobs) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_rounded, size: 48, color: _AppColors.line),
            const SizedBox(height: 12),
            const Text('No slot bookings scheduled'),
            const SizedBox(height: 4),
            Text('Scheduled jobs will appear here', style: TextStyle(fontSize: 12, color: _AppColors.inkSoft)),
          ],
        ),
      );
    }

    // Group jobs by date
    final Map<String, List<Job>> jobsByDate = {};
    for (var job in jobs) {
      final date = job.time.split(' ')[0];
      jobsByDate.putIfAbsent(date, () => []).add(job);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date-wise grouping
          ...jobsByDate.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dateHeader(entry.key),
                const SizedBox(height: 8),
                ...entry.value.map((job) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SlotJobCard(
                      job: job,
                      onTap: () => widget.onJobTap(job.id),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _statusChip(String label, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? _AppColors.brandSoft : _AppColors.card,
        border: Border.all(color: highlight ? _AppColors.brand : _AppColors.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: highlight ? _AppColors.brandDeep : _AppColors.inkSoft,
        ),
      ),
    );
  }

  Widget _dateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        date,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _AppColors.ink,
        ),
      ),
    );
  }
}

class _InstantJobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const _InstantJobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isNew = job.status == JobStatus.newJob;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isNew ? _AppColors.brand : _AppColors.line),
          boxShadow: isNew
              ? [BoxShadow(color: _AppColors.brand.withOpacity(0.2), blurRadius: 8, spreadRadius: 1)]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Service + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.service,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _AppColors.ink)),
                      Text(job.customer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: _AppColors.inkSoft)),
                    ],
                  ),
                ),
                _statusBadge(),
              ],
            ),
            const SizedBox(height: 10),
            // Location + Distance
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 14, color: _AppColors.brand),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(job.addressShort,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: _AppColors.inkSoft)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('${job.distance} km',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _AppColors.brand)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Customer Rating + Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: _AppColors.warning),
                    const SizedBox(width: 2),
                    Text('${job.customerRating ?? 4.5}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _AppColors.ink)),
                  ],
                ),
                Text('₹${job.amount}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _AppColors.ink)),
              ],
            ),
            const SizedBox(height: 10),
            // Action Button
            if (job.status == JobStatus.newJob)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _AppColors.brandDeep,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Accept Job',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge() {
    final (color, icon, text) = switch (job.status) {
      JobStatus.newJob => (_AppColors.warning, Icons.new_label_rounded, 'NEW'),
      JobStatus.accepted => (_AppColors.brand, Icons.check_rounded, 'ACCEPTED'),
      JobStatus.inProgress => (_AppColors.success, Icons.construction_rounded, 'IN PROGRESS'),
      JobStatus.completed => (_AppColors.success, Icons.task_alt_rounded, 'DONE'),
      _ => (_AppColors.line, Icons.cancel_rounded, 'CANCEL'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _SlotJobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const _SlotJobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service + Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.service,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _AppColors.ink)),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 12, color: _AppColors.brand),
                          const SizedBox(width: 4),
                          Text(job.timeShort,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _AppColors.brand)),
                        ],
                      ),
                    ],
                  ),
                ),
                _slotStatusBadge(),
              ],
            ),
            const SizedBox(height: 10),
            // Customer
            Row(
              children: [
                Icon(Icons.person_rounded, size: 14, color: _AppColors.inkSoft),
                const SizedBox(width: 4),
                Text(job.customer,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _AppColors.ink)),
              ],
            ),
            const SizedBox(height: 6),
            // Location
            Row(
              children: [
                Icon(Icons.location_on_rounded, size: 14, color: _AppColors.inkSoft),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(job.addressShort,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _AppColors.inkSoft)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Amount + Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹${job.amount}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _AppColors.ink)),
                if (job.status == JobStatus.assigned)
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Start Service',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _slotStatusBadge() {
    final (color, text) = switch (job.status) {
      JobStatus.assigned => (_AppColors.success, 'READY'),
      JobStatus.inProgress => (_AppColors.brand, 'IN PROGRESS'),
      JobStatus.completed => (_AppColors.success, 'DONE'),
      _ => (_AppColors.line, 'PENDING'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
