import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/challenge_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'providers/notification_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API service
  final apiService = ApiService();

  // Try to load tokens (don't crash if it fails)
  try {
    await apiService.loadTokens();
  } catch (e) {
    debugPrint('Token load warning: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ChallengeProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => LeaderboardProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(apiService),
        ),
      ],
      child: const FanmaniaApp(),
    ),
  );
}
