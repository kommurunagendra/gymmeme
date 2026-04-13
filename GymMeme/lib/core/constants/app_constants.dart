class AppConstants {
  AppConstants._();

  // Hive box names
  static const String userPrefsBox = 'user_prefs';
  static const String archetypeCacheBox = 'archetype_cache';

  // Hive keys
  static const String archetypeResultKey = 'archetype_result';
  static const String archetypeScoresKey = 'archetype_scores';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String streakDaysKey = 'streak_days';
  static const String lastActiveDateKey = 'last_active_date';
  static const String isPremiumKey = 'is_premium';

  // AdMob IDs (test IDs — replace with real IDs before release)
  static const String bannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111'; // test
  static const String interstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712'; // test
  static const String rewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917'; // test

  // Firestore collections
  static const String usersCollection = 'users';
  static const String memesCollection = 'memes';
  static const String reportsCollection = 'reports';
  static const String archetypesCollection = 'archetypes';

  // Storage paths
  static const String memesStoragePath = 'memes';

  // Limits
  static const int freeCaptureSuggestions = 5;
  static const int premiumCaptureSuggestions = 25;
  static const int reportThreshold = 3;
  static const int maxImageSizeKb = 1024; // 1MB after compression
}
