import 'package:flutter/material.dart';
import '../utils/error_messages.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/job_models.dart';
import '../state/partner_app_state.dart';
import '../widgets/job_card.dart';

class MapTab extends StatefulWidget {
  final Function(int) onJobTap;
  const MapTab({required this.onJobTap, Key? key}) : super(key: key);

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  Position? _currentPosition;
  String? _locationError;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() {
          _locationError = 'Location services are off. Enable them to see nearby jobs on the map.';
          _loadingLocation = false;
        });
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = 'Location permission denied. Enable it in app settings to see nearby jobs.';
          _loadingLocation = false;
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _loadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = friendlyErrorMessage(e);
        _loadingLocation = false;
      });
    }
  }

  String _formatDistance(Job job) {
    if (_currentPosition == null || job.latitude == null || job.longitude == null) return '';
    final meters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      job.latitude!,
      job.longitude!,
    );
    return meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km' : '${meters.round()} m';
  }

  @override
  Widget build(BuildContext context) {
    final jobsWithLocation = partnerAppState.newJobs.where((j) => j.latitude != null && j.longitude != null).toList();
    final nearby = partnerAppState.newJobs.take(4).toList();

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
                children: [
                  const Text('Nearby Jobs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${partnerAppState.newJobs.length} open requests',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF059669))),
                ],
              ),
              IconButton(
                onPressed: _loadLocation,
                icon: const Icon(Icons.my_location, size: 20),
                tooltip: 'Refresh my location',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMap(jobsWithLocation),
          const SizedBox(height: 16),
          const Text('OPEN REQUESTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          if (nearby.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No open job requests right now', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ),
          ...nearby.map((job) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NearbyJobRow(
                job: job,
                distanceOverride: _formatDistance(job),
                onTap: () => widget.onJobTap(job.id),
                onAccept: () async {
                  try {
                    await partnerAppState.acceptJob(job.id);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${job.service} job accepted!')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMap(List<Job> jobsWithLocation) {
    if (_loadingLocation) {
      return Container(
        height: 240,
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(24)),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (_locationError != null || _currentPosition == null) {
      return Container(
        height: 240,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(24)),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 32, color: Color(0xFF64748B)),
            const SizedBox(height: 8),
            Text(_locationError ?? 'Location unavailable',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            TextButton(onPressed: _loadLocation, child: const Text('Try again')),
          ],
        ),
      );
    }

    final me = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('me'),
        position: me,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'You'),
      ),
      ...jobsWithLocation.map((job) => Marker(
            markerId: MarkerId('job_${job.id}'),
            position: LatLng(job.latitude!, job.longitude!),
            infoWindow: InfoWindow(title: job.customer, snippet: '${job.service} • ₹${job.amount}'),
            onTap: () => widget.onJobTap(job.id),
          )),
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 240,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: me, zoom: 13),
          markers: markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }
}
