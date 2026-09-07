class KycBackendConfig {
  /// Base URL for all vendor-side PHP endpoints (send-vendor-otp,
  /// verify-vendor-otp, register-vendor, DigiLocker verification, bank
  /// penny-drop verification, service categories, selfie upload).
  ///
  /// This is the SAME folder the consumer (MAHAMAINTAINPRO) app's backend
  /// already lives in and is proven reachable - see server/README.md for
  /// which files from this app's server/ folder need uploading there.
  static const String backendBaseUrl = 'https://digitrixmedia.com/mahamaintainpro/api';
}
