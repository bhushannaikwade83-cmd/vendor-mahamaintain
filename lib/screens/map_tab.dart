import 'package:flutter/material.dart';
import '../state/partner_app_state.dart';
import '../widgets/job_card.dart';

class MapTab extends StatelessWidget {
  final Function(int) onJobTap;
  const MapTab({required this.onJobTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nearby = partnerAppState.newJobs.take(4).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nearby Jobs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('📍 Mira Road East, Mumbai • 12 requests',
                  style: TextStyle(fontSize: 11, color: Color(0xFF059669))),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FA),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Color(0xFFB3E5FC)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map, size: 48, color: Color(0xFF0277BD)),
                      const SizedBox(height: 8),
                      const Text('Google Maps • Live View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                ..._buildMapPins(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('HOT REQUESTS NEAR YOU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          ...nearby.map((job) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NearbyJobRow(
                job: job,
                onTap: () => onJobTap(job.id),
                onAccept: () {
                  partnerAppState.acceptJob(job.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${job.service} job accepted!')),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Widget> _buildMapPins() {
    return [
      Positioned(
        top: 60,
        left: 40,
        child: Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.shade200, width: 4),
              ),
            ),
            const SizedBox(height: 4),
            const Text('₹450 • 0.8km', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      Positioned(
        top: 120,
        right: 50,
        child: Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.shade200, width: 4),
              ),
            ),
            const SizedBox(height: 4),
            const Text('₹890 • 1.4km', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      Positioned(
        bottom: 40,
        left: 60,
        child: Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.shade200, width: 4),
              ),
            ),
            const SizedBox(height: 4),
            const Text('₹320 • 2.1km', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      Positioned(
        bottom: 80,
        right: 60,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF1E40AF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFBFDBFE), width: 3),
          ),
        ),
      ),
    ];
  }
}
