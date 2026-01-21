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
          ],
          redirect: (context, state) {
            final isAuthenticated = auth.isAuthenticated;
            final isLoginRoute = state.matchedLocation == '/login';

            // Redirect to login if not authenticated (except for login page)
            if (!isAuthenticated && !isLoginRoute) {
              return '/login';
            }

            // Redirect to home if authenticated and on login page
            if (isAuthenticated && isLoginRoute) {
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
