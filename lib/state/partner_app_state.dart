import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/job_models.dart';

enum GpsErrorFrequency { low, medium, high }

/// Shared in-memory app state for the Partner app demo — jobs, wallet,
/// online status and GPS-error simulation config. Mirrors the single
/// global JS state object from the reference HTML mockup.
class PartnerAppState extends ChangeNotifier {
  List<Job> jobs = sampleJobs();
  bool isOnline = true;
  int walletBalance = 14280;
  int todayEarnings = 2850;
  GpsErrorFrequency errorFrequency = GpsErrorFrequency.low;
  final List<TrackingError> activeTrackingErrors = [];

  bool onboardingCompleted = false;
  int onboardingProgress = 65;

  final Random _random = Random();

  Job? jobById(int id) {
    try {
      return jobs.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Job> get newJobs => jobs.where((j) => j.status == JobStatus.newJob).toList();
  List<Job> get upcomingJobs =>
      jobs.where((j) => j.status == JobStatus.accepted || j.status == JobStatus.inProgress).toList();

  void toggleOnline() {
    isOnline = !isOnline;
    notifyListeners();
  }

  bool acceptJob(int jobId) {
    final job = jobById(jobId);
    if (job == null || job.status != JobStatus.newJob) return false;
    job.status = JobStatus.accepted;
    notifyListeners();
    return true;
  }

  void rejectJob(int jobId) {
    final job = jobById(jobId);
    if (job == null) return;
    job.status = JobStatus.cancelled;
    notifyListeners();
  }

  void startJob(int jobId) {
    final job = jobById(jobId);
    if (job == null) return;
    job.status = JobStatus.inProgress;
    notifyListeners();
  }

  void setBeforePhoto(int jobId, String url) {
    final job = jobById(jobId);
    if (job == null) return;
    job.beforePhoto = url;
    notifyListeners();
  }

  void setAfterPhoto(int jobId, String url) {
    final job = jobById(jobId);
    if (job == null) return;
    job.afterPhoto = url;
    notifyListeners();
  }

  /// Returns true if OTP accepted and job completed.
  bool completeJob(int jobId, String otp) {
    final job = jobById(jobId);
    if (job == null) return false;
    if (otp.trim().length != 6) return false;
    job.status = JobStatus.completed;
    job.otp = otp.trim();
    todayEarnings += job.amount;
    walletBalance += job.amount;
    notifyListeners();
    return true;
  }

  void rateJob(int jobId, int rating) {
    final job = jobById(jobId);
    if (job == null) return;
    job.rating = rating;
    notifyListeners();
  }

  bool withdraw(int amount) {
    if (amount < 100 || amount > walletBalance) return false;
    walletBalance -= amount;
    notifyListeners();
    return true;
  }

  void setErrorFrequency(GpsErrorFrequency freq) {
    errorFrequency = freq;
    notifyListeners();
  }

  void recordTrackingError(int jobId, String service, String errorType) {
    activeTrackingErrors.add(TrackingError(
      jobId: jobId,
      service: service,
      errorType: errorType,
      timestamp: DateTime.now().toIso8601String(),
    ));
  }

  void clearTrackingErrors() {
    activeTrackingErrors.clear();
    notifyListeners();
  }

  /// Returns a random GPS error to surface, or null if none should fire this tick.
  GpsErrorType? maybeSimulateGpsError(int jobId) {
    final job = jobById(jobId);
    if (job == null || job.status != JobStatus.inProgress) return null;

    double chance = switch (errorFrequency) {
      GpsErrorFrequency.low => 0.15,
      GpsErrorFrequency.medium => 0.35,
      GpsErrorFrequency.high => 0.65,
    };
    if (job.service == 'Water Purifier') chance += 0.25;

    if (_random.nextDouble() > chance) return null;

    final err = gpsErrorTypes[_random.nextInt(gpsErrorTypes.length)];
    recordTrackingError(jobId, job.service, err.type);
    return err;
  }

  void completeOnboardingStep(int step) {
    switch (step) {
      case 1:
        onboardingProgress = max(onboardingProgress, 80);
        break;
      case 2:
        onboardingProgress = max(onboardingProgress, 90);
        break;
      case 3:
        onboardingProgress = max(onboardingProgress, 95);
        break;
      case 4:
        onboardingProgress = 100;
        break;
    }
    notifyListeners();
  }

  void finishOnboarding() {
    onboardingCompleted = true;
    notifyListeners();
  }
}

/// Single shared instance for the whole app session, mirroring the JS globals.
final partnerAppState = PartnerAppState();
