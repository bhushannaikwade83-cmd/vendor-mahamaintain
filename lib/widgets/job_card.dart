import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/job_models.dart';

const Color kEmerald = Color(0xFF059669);
const Color kEmeraldBg = Color(0xFFD1FAE5);
const Color kSlateText = Color(0xFF64748B);
const Color kSlateBorder = Color(0xFFF1F5F9);

Widget statusBadge(JobStatus status) {
  late Color bg;
  late Color fg;
  late String label;
  switch (status) {
    case JobStatus.newJob:
      bg = const Color(0xFFFFE3D1);
      fg = AppTheme.saffronDark;
      label = 'NEW REQUEST';
      break;
    case JobStatus.accepted:
      bg = kEmeraldBg;
      fg = kEmerald;
      label = 'ACCEPTED';
      break;
    case JobStatus.inProgress:
      bg = const Color(0xFFFFF3EC);
      fg = AppTheme.saffron;
      label = 'IN PROGRESS';
      break;
    case JobStatus.completed:
      bg = const Color(0xFFE2E8F0);
      fg = const Color(0xFF475569);
      label = 'COMPLETED';
      break;
    case JobStatus.cancelled:
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
      label = 'CANCELLED';
      break;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(color: fg, fontSize: 9.5, fontWeight: FontWeight.w700)),
  );
}

/// New job request card (Home screen).
class NewJobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  const NewJobCard({required this.job, required this.onTap, required this.onAccept, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFFFE3D1)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(job.customer,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFE3D1), borderRadius: BorderRadius.circular(20)),
                        child: Text(job.service,
                            style: TextStyle(color: AppTheme.saffronDark, fontSize: 9.5, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(job.addressShort,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: kSlateText, fontSize: 11)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('₹${job.amount}',
                          style: const TextStyle(color: kEmerald, fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: Colors.grey.shade400)),
                      const SizedBox(width: 8),
                      Text(job.timeShort, style: const TextStyle(color: kSlateText, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text('ACCEPT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 4),
                Text(job.distance, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact upcoming job row (Home screen).
class UpcomingJobRow extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  const UpcomingJobRow({required this.job, required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kSlateBorder),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(job.customer, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(width: 8),
                      statusBadge(job.status),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(job.type, style: const TextStyle(color: kSlateText, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${job.amount}',
                    style: const TextStyle(color: kEmerald, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(job.timeShort, style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full booking card (Bookings screen).
class BookingCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  const BookingCard({required this.job, required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.customer, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(job.address, style: const TextStyle(color: kSlateText, fontSize: 11)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${job.amount}',
                        style: const TextStyle(color: kEmerald, fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 4),
                    statusBadge(job.status),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                      children: [
                        TextSpan(text: job.service, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const TextSpan(text: '  •  '),
                        TextSpan(text: job.type, style: const TextStyle(color: kSlateText)),
                      ],
                    ),
                  ),
                ),
                Text(job.time, style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: kSlateBorder),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: kEmerald),
                    const SizedBox(width: 4),
                    Text(job.distance, style: const TextStyle(color: kEmerald, fontSize: 11)),
                  ],
                ),
                Row(
                  children: [
                    Text('View details', style: TextStyle(color: AppTheme.saffron, fontSize: 11, fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right, size: 14, color: AppTheme.saffron),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Nearby job row (Map screen).
class NearbyJobRow extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final String? distanceOverride;
  const NearbyJobRow(
      {required this.job, required this.onTap, required this.onAccept, this.distanceOverride, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: kSlateBorder),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.customer, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(job.type,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kSlateText, fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                        decoration: BoxDecoration(color: kEmeraldBg, borderRadius: BorderRadius.circular(4)),
                        child: Text('₹${job.amount}',
                            style: const TextStyle(color: kEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      if ((distanceOverride ?? job.distance).isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(distanceOverride ?? job.distance, style: TextStyle(color: AppTheme.saffronDark, fontSize: 11)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.saffron,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
              child: const Text('ACCEPT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
