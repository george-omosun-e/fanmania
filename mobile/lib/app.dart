import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'models/category.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/challenge_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/challenge/category_detail_screen.dart';
import 'screens/challenge/challenge_screen.dart';
import 'screens/challenge/challenge_result_screen.dart';

class FanmaniaApp extends StatelessWidget {
  const FanmaniaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for immersive experience
    SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlayStyle);

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final router = GoRouter(
          initialLocation: auth.isAuthenticated ? '/home' : '/login',
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
            final isAuthenticated = auth.isAuthenticated;
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

            return null;
          },
        );

        return MaterialApp.router(
          title: 'Fanmania',
          theme: AppTheme.darkTheme,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
