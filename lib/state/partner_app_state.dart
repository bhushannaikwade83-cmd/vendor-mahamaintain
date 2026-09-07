import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/earnings_model.dart';
import '../models/job_models.dart';
import '../repositories/jobs_repository.dart';

/// Shared app state for the Partner app — real jobs/earnings data fetched
/// from the backend, plus online status.
class PartnerAppState extends ChangeNotifier {
  static const _keyOnboardingCompleted = 'onboarding_completed';
  static const _keyDigilockerStepDone = 'digilocker_step_done';
  static const _keyCategoriesStepDone = 'categories_step_done';
  static const _keySelfieStepDone = 'selfie_step_done';
  static const _keyIsOnline = 'is_online';

  final JobsRepository _jobsRepository = JobsRepository();

  String? vendorId;

  List<Job> newJobs = [];
  List<Job> jobs = []; // "my jobs" - anything this vendor has claimed, any status
  bool jobsLoading = false;
  VendorEarnings? earnings;
  bool earningsLoading = false;

  int get walletBalance => (earnings?.walletBalance ?? 0).round();
  int get todayEarnings => (earnings?.todayEarnings ?? 0).round();

  bool isOnline = true;

  bool onboardingCompleted = false;

  // Each step is tracked independently - completing one never implies the
  // others are done. Onboarding progress is derived from how many of these
  // are actually true, each only ever set after the backend confirms that
  // specific step (DigiLocker connected, categories saved, selfie
  // approved) - never optimistically.
  bool digilockerStepDone = false;
  bool categoriesStepDone = false;
  bool selfieStepDone = false;

  int get onboardingProgress {
    final done = [digilockerStepDone, categoriesStepDone, selfieStepDone].where((d) => d).length;
    return (done * 100 / 3).round();
  }

  Job? jobById(int id) {
    try {
      return newJobs.firstWhere((j) => j.id == id);
    } catch (_) {
      try {
        return jobs.firstWhere((j) => j.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  List<Job> get upcomingJobs =>
      jobs.where((j) => j.status == JobStatus.accepted || j.status == JobStatus.inProgress).toList();

  void setVendorId(String? id) {
    vendorId = id;
    if (id == null) {
      newJobs = [];
      jobs = [];
      earnings = null;
      notifyListeners();
    } else {
      refreshJobs();
      refreshEarnings();
      // Keep the backend's online flag in sync with what this device last
      // showed - so a vendor who was offline when they closed the app
      // doesn't silently start getting matched to jobs again.
      _jobsRepository.setOnlineStatus(id, isOnline).catchError((_) {});
    }
  }

  /// Throws [JobActionException] if the backend update fails - the toggle
  /// stays at its previous value so the UI doesn't claim "online" when the
  /// backend never actually got the update (which would silently hide new
  /// job requests from this vendor without them knowing why).
  Future<void> toggleOnline() async {
    final id = vendorId;
    final next = !isOnline;
    if (id == null) {
      isOnline = next;
      notifyListeners();
      return;
    }
    await _jobsRepository.setOnlineStatus(id, next);
    isOnline = next;
    await _persistOnline();
    notifyListeners();
    await refreshJobs();
  }

  Future<void> _persistOnline() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsOnline, isOnline);
  }

  Future<void> refreshJobs() async {
    final id = vendorId;
    if (id == null) return;
    jobsLoading = true;
    notifyListeners();
    try {
      final snapshot = await _jobsRepository.fetchJobs(id);
      newJobs = snapshot.newJobs;
      jobs = snapshot.myJobs;
    } finally {
      jobsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshEarnings() async {
    final id = vendorId;
    if (id == null) return;
    earningsLoading = true;
    notifyListeners();
    try {
      earnings = await _jobsRepository.fetchEarnings(id);
    } finally {
      earningsLoading = false;
      notifyListeners();
    }
  }

  /// Throws [JobActionException] on failure (e.g. another vendor already
  /// claimed it) - caller should catch and show the message.
  Future<void> acceptJob(int jobId) async {
    final id = vendorId;
    if (id == null) throw JobActionException('Not logged in');
    await _jobsRepository.respondToJob(id, jobId, accept: true);
    await refreshJobs();
  }

  Future<void> rejectJob(int jobId) async {
    final id = vendorId;
    if (id == null) throw JobActionException('Not logged in');
    await _jobsRepository.respondToJob(id, jobId, accept: false);
    await refreshJobs();
  }

  Future<void> startJob(int jobId, {File? beforePhoto}) async {
    final id = vendorId;
    if (id == null) throw JobActionException('Not logged in');
    await _jobsRepository.startJob(id, jobId, beforePhoto: beforePhoto);
    await refreshJobs();
  }

  /// Returns the completed job's amount (for the "₹X added" toast) on success.
  Future<int> completeJob(int jobId, String otp, {File? afterPhoto}) async {
    final id = vendorId;
    if (id == null) throw JobActionException('Not logged in');
    final job = jobById(jobId);
    await _jobsRepository.completeJob(id, jobId, otp, afterPhoto: afterPhoto);
    await refreshJobs();
    await refreshEarnings();
    return job?.amount ?? 0;
  }

  Future<void> cancelJob(int jobId) async {
    final id = vendorId;
    if (id == null) throw JobActionException('Not logged in');
    await _jobsRepository.cancelJob(id, jobId);
    await refreshJobs();
  }

  void rateJob(int jobId, int rating) {
    final job = jobById(jobId);
    if (job == null) return;
    job.rating = rating;
    notifyListeners();
  }

  Future<void> withdraw(int amount) async {
    final id = vendorId;
    if (id == null) throw JobActionException('Not logged in');
    await _jobsRepository.withdraw(id, amount.toDouble());
    await refreshEarnings();
  }

  /// Loads persisted onboarding progress, if any. Call once at app startup
  /// before the router is built, so a vendor who restarts the app mid- (or
  /// post-) onboarding doesn't lose that progress.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    onboardingCompleted = prefs.getBool(_keyOnboardingCompleted) ?? false;
    digilockerStepDone = prefs.getBool(_keyDigilockerStepDone) ?? false;
    categoriesStepDone = prefs.getBool(_keyCategoriesStepDone) ?? false;
    selfieStepDone = prefs.getBool(_keySelfieStepDone) ?? false;
    isOnline = prefs.getBool(_keyIsOnline) ?? true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, onboardingCompleted);
    await prefs.setBool(_keyDigilockerStepDone, digilockerStepDone);
    await prefs.setBool(_keyCategoriesStepDone, categoriesStepDone);
    await prefs.setBool(_keySelfieStepDone, selfieStepDone);
  }

  // Bank account verification is not part of onboarding - it's gated behind
  // the first withdrawal instead (see EarningsTab), so vendors can onboard
  // and start getting matched to jobs immediately without waiting on
  // RazorpayX approval.
  void completeOnboardingStep(int step) {
    switch (step) {
      case 1: // Identity & PAN (DigiLocker)
        digilockerStepDone = true;
        break;
      case 2: // Service Categories
        categoriesStepDone = true;
        break;
      case 3: // Live Selfie Verification
        selfieStepDone = true;
        break;
    }
    notifyListeners();
    _persist();
  }

  void finishOnboarding() {
    onboardingCompleted = true;
    notifyListeners();
    _persist();
  }

  /// Called on logout so the next login starts from a clean slate instead
  /// of remembering this session's onboarding progress.
  void resetSession() {
    onboardingCompleted = false;
    digilockerStepDone = false;
    categoriesStepDone = false;
    selfieStepDone = false;
    vendorId = null;
    newJobs = [];
    jobs = [];
    earnings = null;
    isOnline = true;
    notifyListeners();
    _persist();
    _persistOnline();
  }
}

/// Single shared instance for the whole app session, mirroring the JS globals.
final partnerAppState = PartnerAppState();
