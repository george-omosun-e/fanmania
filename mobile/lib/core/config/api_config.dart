class ApiConfig {
  // Base URL - Production
  static const String baseUrl = 'https://fanmania-production.up.railway.app';

  // API version
  static const String apiVersion = 'v1';
  
  // Full API URL
  static String get apiUrl => '$baseUrl/$apiVersion';
  
  // Endpoints
  static const String auth = '/auth';
  static const String users = '/users';
  static const String categories = '/categories';
  static const String challenges = '/challenges';
  static const String leaderboards = '/leaderboards';
  static const String notifications = '/notifications';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String usernameKey = 'username';
}

class AppConstants {
  // App info
  static const String appName = 'Fanmania';
  static const String appVersion = '1.0.0';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxChallengesPerLoad = 10;
  
  // Cache duration
  static const Duration categoryCacheDuration = Duration(hours: 24);
  static const Duration leaderboardCacheDuration = Duration(minutes: 5);
  
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Challenge timer
  static const int challengeWarningTimeSeconds = 10;
  
  // Streak settings
  static const int streakMilestones = 7; // Days to celebrate
  
  // Points display
  static const String pointsSymbol = '⭐';
}
