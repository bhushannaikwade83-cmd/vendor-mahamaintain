import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/available_job_model.dart';
import '../models/vendor_profile_model.dart';
import '../repositories/job_matching_repository.dart';
import 'partner_app_state.dart';

final jobMatchingRepositoryProvider = Provider((ref) {
  return JobMatchingRepository();
});

/// Provider for fetching vendor's profile
final vendorProfileProvider =
    FutureProvider.family<VendorProfile?, String>((ref, vendorId) async {
  final repository = ref.watch(jobMatchingRepositoryProvider);
  return repository.getVendorProfile(vendorId);
});

/// Provider for fetching available jobs for current vendor
final availableJobsProvider = FutureProvider<List<AvailableJob>>((ref) async {
  final vendorId = ref.watch(currentVendorIdProvider);

  if (vendorId == null) {
    return [];
  }

  final repository = ref.watch(jobMatchingRepositoryProvider);
  final vendorProfile = await ref.watch(vendorProfileProvider(vendorId).future);

  if (vendorProfile == null) {
    return [];
  }

  // Check if vendor is verified (only show jobs to verified vendors)
  if (!vendorProfile.isKycVerified || !vendorProfile.isBankVerified) {
    return [];
  }

  return repository.getAvailableJobsForVendor(vendorProfile);
});

/// Provider for a single available job
final availableJobProvider =
    FutureProvider.family<AvailableJob?, int>((ref, jobId) async {
  final repository = ref.watch(jobMatchingRepositoryProvider);
  return repository.getAvailableJob(jobId);
});

/// Provider for accepting a job
final acceptJobProvider =
    FutureProvider.family<bool, int>((ref, jobId) async {
  final vendorId = ref.watch(currentVendorIdProvider);
  if (vendorId == null) return false;

  final repository = ref.watch(jobMatchingRepositoryProvider);
  final result = await repository.acceptJob(jobId, vendorId, null);

  // Refresh available jobs after accepting
  if (result) {
    ref.refresh(availableJobsProvider);
  }

  return result;
});

/// State for managing job acceptance
class JobAcceptanceState {
  final bool isLoading;
  final String? error;
  final int? acceptedJobId;

  JobAcceptanceState({
    this.isLoading = false,
    this.error,
    this.acceptedJobId,
  });

  JobAcceptanceState copyWith({
    bool? isLoading,
    String? error,
    int? acceptedJobId,
  }) {
    return JobAcceptanceState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      acceptedJobId: acceptedJobId ?? this.acceptedJobId,
    );
  }
}

final jobAcceptanceNotifierProvider =
    StateNotifierProvider<JobAcceptanceNotifier, JobAcceptanceState>((ref) {
  return JobAcceptanceNotifier(ref);
});

class JobAcceptanceNotifier extends StateNotifier<JobAcceptanceState> {
  final Ref ref;

  JobAcceptanceNotifier(this.ref) : super(JobAcceptanceState());

  Future<bool> acceptJob(int jobId) async {
    state = state.copyWith(isLoading: true);

    try {
      final vendorId = ref.read(currentVendorIdProvider);
      if (vendorId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Vendor not authenticated',
        );
        return false;
      }

      final repository = ref.read(jobMatchingRepositoryProvider);
      final result = await repository.acceptJob(jobId, vendorId, null);

      if (result) {
        state = state.copyWith(
          isLoading: false,
          acceptedJobId: jobId,
          error: null,
        );
        // Refresh available jobs
        ref.refresh(availableJobsProvider);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to accept job',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> rejectJob(int jobId) async {
    try {
      final vendorId = ref.read(currentVendorIdProvider);
      if (vendorId == null) return false;

      final repository = ref.read(jobMatchingRepositoryProvider);
      final result = await repository.rejectJob(jobId, vendorId);

      if (result) {
        // Refresh available jobs
        ref.refresh(availableJobsProvider);
      }

      return result;
    } catch (e) {
      return false;
    }
  }

  void clearState() {
    state = JobAcceptanceState();
  }
}

// Helper provider to get current vendor ID (add this to your partner_app_state.dart)
final currentVendorIdProvider = StateProvider<String?>((ref) {
  // This should be set from your auth state
  return null;
});
