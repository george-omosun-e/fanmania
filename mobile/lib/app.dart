import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'models/category.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/challenge/category_detail_screen.dart';
import 'screens/challenge/challenge_screen.dart';
import 'screens/challenge/challenge_result_screen.dart';

class FanmaniaApp extends StatefulWidget {
  const FanmaniaApp({super.key});

  @override
  State<FanmaniaApp> createState() => _FanmaniaAppState();
}

class _FanmaniaAppState extends State<FanmaniaApp> {
  GoRouter? _router;

  GoRouter _createRouter(AuthProvider auth) {
    return GoRouter(
      initialLocation: auth.isAuthenticated ? '/home' : '/login',
      refreshListenable: auth, // Listen to auth changes for redirects only
      routes: [
        // Auth routes
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),

        // Main app routes
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),

        // Challenge flow routes
        GoRoute(
          path: '/category/:categoryId',
          builder: (context, state) {
            // Get category from provider or extra
            final categoryId = state.pathParameters['categoryId']!;
            final category = state.extra as Category? ??
                context
                    .read<CategoryProvider>()
                    .getCategoryById(categoryId);

            if (category == null) {
              // Fallback to home if category not found
              return const HomeScreen();
            }

            return CategoryDetailScreen(category: category);
          },
        ),
        GoRoute(
          path: '/challenge',
          builder: (context, state) => const ChallengeScreen(),
        ),
        GoRoute(
          path: '/challenge/result',
          builder: (context, state) => const ChallengeResultScreen(),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
      redirect: (context, state) {
        final authProvider = context.read<AuthProvider>();
        final isAuthenticated = authProvider.isAuthenticated;
        final isAuthRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        // Redirect to login if not authenticated (except for auth pages)
        if (!isAuthenticated && !isAuthRoute) {
          return '/login';
        }

        // Redirect to home if authenticated and on auth page
        if (isAuthenticated && isAuthRoute) {
          return '/home';
        }

        // IMPORTANT: Don't redirect away from other routes just because auth state changed
        // This allows the result screen to persist
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for immersive experience
    SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlayStyle);

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Show splash screen while checking auth status
        if (!auth.isInitialized) {
          return MaterialApp(
            title: 'Fanmania',
            theme: AppTheme.darkTheme,
            debugShowCheckedModeBanner: false,
            home: const _SplashScreen(),
          );
        }

        // Create router only once after auth is initialized
        _router ??= _createRouter(auth);

        return MaterialApp.router(
          title: 'Fanmania',
          theme: AppTheme.darkTheme,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

/// Splash screen shown while checking authentication status
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepSpace,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.electricCyan,
                    AppColors.vividViolet,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.electricCyan.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.sports_esports_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Fanmania',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.electricCyan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
