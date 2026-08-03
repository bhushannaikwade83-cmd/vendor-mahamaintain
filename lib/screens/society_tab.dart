import 'package:flutter/material.dart';
import '../models/job_models.dart';

class SocietyTab extends StatefulWidget {
  const SocietyTab({Key? key}) : super(key: key);

  @override
  State<SocietyTab> createState() => _SocietyTabState();
}

class _SocietyTabState extends State<SocietyTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = societyData
        .where((s) => s.name.toLowerCase().contains(_search.toLowerCase()) || s.area.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Society Directory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Gated communities in your service zone', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Search societies…',
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
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
                      Text('Registered', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      SizedBox(height: 4),
                      Text('24', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
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
                      Text('Active Jobs', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      SizedBox(height: 4),
                      Text('7', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
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
                      Text('AMC Contracts', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      SizedBox(height: 4),
                      Text('5', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...filtered.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (s.phase.isNotEmpty)
                                Text(s.phase, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: s.amc ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(s.amc ? 'AMC' : 'No AMC',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: s.amc ? const Color(0xFF1E40AF) : Colors.grey.shade500,
                                  )),
                            ),
                            const SizedBox(height: 2),
                            Text('★ ${s.rating}', style: const TextStyle(fontSize: 10, color: Color(0xFFF59E0B))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${s.units} units', style: const TextStyle(fontSize: 10)),
                        Text('${s.activeJobs} active', style: const TextStyle(fontSize: 10, color: Color(0xFF059669))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('📍 ${s.area}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text('🔑 ${s.access}', style: const TextStyle(fontSize: 10, color: Color(0xFFF97316))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Calling ${s.contact}...')),
                            ),
                            icon: const Icon(Icons.phone, size: 14),
                            label: const Text('Call', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Navigating to ${s.name}...')),
                            ),
                            icon: const Icon(Icons.location_on, size: 14),
                            label: const Text('Navigate', style: TextStyle(fontSize: 11)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
