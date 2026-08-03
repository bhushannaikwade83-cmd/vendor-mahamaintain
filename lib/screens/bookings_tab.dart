import 'package:flutter/material.dart';
import '../models/job_models.dart';
import '../state/partner_app_state.dart';
import '../widgets/job_card.dart';

class BookingsTab extends StatefulWidget {
  final Function(int) onJobTap;
  const BookingsTab({required this.onJobTap, Key? key}) : super(key: key);

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  JobStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == null ? partnerAppState.jobs : partnerAppState.jobs.where((j) => j.status == _filter).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', null),
                const SizedBox(width: 8),
                _filterChip('New (${partnerAppState.newJobs.length})', JobStatus.newJob),
                const SizedBox(width: 8),
                _filterChip('Accepted', JobStatus.accepted),
                const SizedBox(width: 8),
                _filterChip('In Progress', JobStatus.inProgress),
                const SizedBox(width: 8),
                _filterChip('Completed', JobStatus.completed),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...filtered.map((job) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BookingCard(job: job, onTap: () => widget.onJobTap(job.id)),
            );
          }),
        ],
      ),
    );
  }

  Widget _filterChip(String label, JobStatus? status) {
    final active = _filter == status;
    return InkWell(
      onTap: () => setState(() => _filter = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1E40AF) : Colors.white,
          border: Border.all(color: active ? Colors.transparent : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
