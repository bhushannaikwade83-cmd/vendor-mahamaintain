import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/job_models.dart';
import '../state/partner_app_state.dart';
import '../widgets/job_card.dart';

class HomeTab extends StatelessWidget {
  final Function(int) onJobTap;
  const HomeTab({required this.onJobTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Good afternoon,', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  SizedBox(height: 2),
                  Text('Suresh Patil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Top Rated Partner • 4.92', style: TextStyle(fontSize: 11, color: Color(0xFF059669))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text("Today's Target", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  SizedBox(height: 2),
                  Text('₹4,500', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                ],
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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Today's Earnings", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      Text('₹${partnerAppState.todayEarnings}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                      const SizedBox(height: 4),
                      const Text('+32% from yesterday', style: TextStyle(fontSize: 10, color: Color(0xFF059669))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Jobs Today', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      const Text('5 / 8', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('4 Completed', style: TextStyle(fontSize: 10, color: Color(0xFF059669))),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('New Job Requests', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE3D1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${partnerAppState.newJobs.length}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.saffronDark)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...partnerAppState.newJobs.take(3).map((job) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NewJobCard(
                job: job,
                onTap: () => onJobTap(job.id),
                onAccept: () {
                  partnerAppState.acceptJob(job.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Job accepted! ${job.customer}')),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text('Upcoming Today', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...partnerAppState.upcomingJobs.map((job) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: UpcomingJobRow(job: job, onTap: () => onJobTap(job.id)),
            );
          }),
        ],
      ),
    );
  }
}
