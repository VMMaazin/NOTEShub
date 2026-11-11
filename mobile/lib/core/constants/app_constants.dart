class AppConstants {
  static const String appName = 'NOTEShub';
  static const String appTagline = 'Curated Academic Notes & Resources';
  
  // Academic Structure
  static const int currentSemester = 5;
  static const int totalSubjectsPerSemester = 8;
  static const int totalModulesPerSubject = 5;

  // Categories
  static const String categoryNotes = 'notes';
  static const String categoryQbank = 'qbank';
  static const String categoryExtra = 'extra';

  // Cloudinary Config (Identical to existing Next.js web application)
  static const String cloudinaryCloudName = 'debfdnujc';
  static const String cloudinaryUploadPreset = 'college_notes';
  static const String cloudinaryRawUploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/raw/upload';

  // Storage Limits
  static const int maxUploadSizeBytes = 50 * 1024 * 1024; // 50 MB

  // Responsive Breakpoints & Width Constraints
  static const double maxContentWidth = 720.0;
  static const double maxWideContentWidth = 1080.0;
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  // App Version Information
  static const String appVersion = '1.0.1';
  static const int appVersionCode = 2;

  // Android APK Download URL
  static const String androidApkDownloadUrl =
      'https://github.com/VMMaazin/NOTEShub/releases/latest/download/NOTEShub-v1.0.1.apk';

  // In-App Update Configuration
  static const String updateMetadataUrl =
      'https://raw.githubusercontent.com/VMMaazin/NOTEShub/main/mobile/version.json';
  static const Duration updateCheckTimeout = Duration(seconds: 5);
  static const Duration updateCacheDuration = Duration(hours: 6);
  static const String updateLastCheckedPrefKey = 'noteshub_update_last_checked_ms';
  static const String updateCachedMetadataPrefKey = 'noteshub_update_cached_metadata';
}

