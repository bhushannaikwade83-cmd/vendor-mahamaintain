import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../models/job_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}

class ActiveJobTrackingScreen extends StatefulWidget {
  final Job job;
  final VoidCallback onComplete;

  const ActiveJobTrackingScreen({
    required this.job,
    required this.onComplete,
    Key? key,
  }) : super(key: key);

  @override
  State<ActiveJobTrackingScreen> createState() => _ActiveJobTrackingScreenState();
}

class _ActiveJobTrackingScreenState extends State<ActiveJobTrackingScreen> {
  late Timer _locationTimer;
  bool _isTracking = false;
  bool _isLoading = false;
  double? _currentLat;
  double? _currentLng;
  String _statusMessage = 'Ready to start sharing location';

  @override
  void initState() {
    super.initState();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) => _updateLocation());
  }

  Future<void> _updateLocation() async {
    if (!_isTracking) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
      });

      final prefs = await SharedPreferences.getInstance();
      final vendorId = prefs.getInt('vendorId');

      if (vendorId != null) {
        await http.post(
          Uri.parse('https://digitrixmedia.com/mahamaintainpro/api/vendor/update-vendor-location.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'request_id': widget.job.id,
            'vendor_id': vendorId,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'speed': position.speed,
            'accuracy': position.accuracy,
          }),
        ).timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _startTracking() async {
    setState(() => _isLoading = true);

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission required to share location')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _isTracking = true;
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _statusMessage = 'Sharing location with customer...';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _stopTracking() async {
    setState(() => _isTracking = false);
    _statusMessage = 'Location tracking stopped';
  }

  Future<void> _completeJob() async {
    await _stopTracking();
    widget.onComplete();
  }

  @override
  void dispose() {
    _locationTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.canvas,
      appBar: AppBar(
        backgroundColor: _AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 62,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: _AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _AppColors.line),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 18, color: _AppColors.ink),
            ),
          ),
        ),
        title: const Text('Active Job',
            style: TextStyle(
                color: _AppColors.ink,
                fontSize: 19,
                fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _jobDetailsCard(),
            const SizedBox(height: 16),
            _trackingStatusCard(),
            const SizedBox(height: 16),
            _locationCard(),
            const SizedBox(height: 16),
            _customerInfoCard(),
          ],
        ),
      ),
      bottomNavigationBar: _actionButtons(),
    );
  }

  Widget _jobDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.line),
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
                    Text(widget.job.service,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _AppColors.ink)),
                    const SizedBox(height: 4),
                    Text(widget.job.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: _AppColors.inkSoft)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('₹${widget.job.amount}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _AppColors.brandDeep)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: _AppColors.line, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoChip('Booking', widget.job.bookingType == BookingType.instant ? 'INSTANT' : 'SLOT'),
              _infoChip('Status', widget.job.status == JobStatus.inProgress ? 'RUNNING' : 'READY'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _AppColors.inkSoft)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _AppColors.ink)),
      ],
    );
  }

  Widget _trackingStatusCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isTracking
            ? _AppColors.success.withOpacity(0.1)
            : _AppColors.brandSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isTracking ? _AppColors.success : _AppColors.brand,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isTracking ? _AppColors.success : _AppColors.brand,
            ),
            child: Icon(
              _isTracking ? Icons.location_on_rounded : Icons.location_off_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isTracking ? 'Location Sharing' : 'Location Tracking',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isTracking ? _AppColors.success : _AppColors.brand)),
                Text(_statusMessage,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _AppColors.ink)),
              ],
            ),
          ),
          if (_isTracking)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _AppColors.success,
              ),
            ),
        ],
      ),
    );
  }

  Widget _locationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Location',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _AppColors.inkSoft)),
          const SizedBox(height: 10),
          if (_currentLat != null && _currentLng != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _locationDetail('Latitude', _currentLat!.toStringAsFixed(6)),
                _locationDetail('Longitude', _currentLng!.toStringAsFixed(6)),
              ],
            )
          else
            const Text('Enable location sharing to see coordinates',
                style: TextStyle(fontSize: 12, color: _AppColors.inkSoft)),
        ],
      ),
    );
  }

  Widget _locationDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _AppColors.inkSoft)),
          Text(value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _AppColors.ink)),
        ],
      ),
    );
  }

  Widget _customerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer Details',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _AppColors.inkSoft)),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _AppColors.brandSoft,
                ),
                child: const Icon(Icons.person_rounded, color: _AppColors.brand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.job.customer,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _AppColors.ink)),
                    Text(widget.job.phone,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _AppColors.inkSoft)),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _AppColors.brandSoft,
                ),
                child: const Icon(Icons.call_rounded, color: _AppColors.brand, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isTracking)
            ElevatedButton(
              onPressed: _isLoading ? null : _startTracking,
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.success,
                disabledBackgroundColor: _AppColors.line,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                  : const Text('Start Sharing Location',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: _stopTracking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _AppColors.brandDeep,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Stop Sharing Location',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _completeJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Complete Job',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
