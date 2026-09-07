import 'package:flutter/material.dart';
import '../utils/error_messages.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/society_model.dart';
import '../repositories/society_repository.dart';

class SocietyTab extends StatefulWidget {
  const SocietyTab({Key? key}) : super(key: key);

  @override
  State<SocietyTab> createState() => _SocietyTabState();
}

class _SocietyTabState extends State<SocietyTab> {
  final _repository = SocietyRepository();
  String _search = '';
  bool _loading = true;
  String? _error;
  List<Society> _societies = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final societies = await _repository.fetchSocieties();
      if (!mounted) return;
      setState(() {
        _societies = societies;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _call(Society s) async {
    final phone = s.contactPhone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No contact number on file')));
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open dialer')));
    }
  }

  Future<void> _navigate(Society s) async {
    final query = (s.latitude != null && s.longitude != null)
        ? '${s.latitude},${s.longitude}'
        : Uri.encodeComponent('${s.name}, ${s.area}');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open maps')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _societies
        .where((s) =>
            s.name.toLowerCase().contains(_search.toLowerCase()) || s.area.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    final amcCount = _societies.where((s) => s.hasAmc).length;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                      children: [
                        const Text('Registered', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Text('${_societies.length}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
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
                        const Text('AMC Contracts', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Text('$amcCount',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.red)),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _load, child: const Text('Try again')),
                  ],
                ),
              )
            else if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No societies found', style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
              )
            else
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
                                  if ((s.phase ?? '').isNotEmpty)
                                    Text(s.phase!, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: s.hasAmc ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(s.hasAmc ? 'AMC' : 'No AMC',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: s.hasAmc ? const Color(0xFF1E40AF) : Colors.grey.shade500,
                                  )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${s.units} units', style: const TextStyle(fontSize: 10)),
                        const SizedBox(height: 8),
                        Text('📍 ${s.area}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        if ((s.accessNotes ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('🔑 ${s.accessNotes}', style: const TextStyle(fontSize: 10, color: Color(0xFFF97316))),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _call(s),
                                icon: const Icon(Icons.phone, size: 14),
                                label: const Text('Call', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _navigate(s),
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
      ),
    );
  }
}
