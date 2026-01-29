import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/challenge.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/neon_button.dart';

class ChallengeResultScreen extends StatefulWidget {
  const ChallengeResultScreen({super.key});

  @override
  State<ChallengeResultScreen> createState() => _ChallengeResultScreenState();
}

class _ChallengeResultScreenState extends State<ChallengeResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Cache session data to prevent losing it if provider resets
  int _correctCount = 0;
  int _totalAnswered = 0;
  int _totalPoints = 0;
  int _accuracy = 0;
  int? _newTotalPoints;
  String? _categoryId;
  String? _categoryName;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Refresh user data after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshUser();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache session data on first dependency resolution (before first build completes)
    if (!_dataLoaded) {
      _cacheSessionData();
    }
  }

  void _cacheSessionData() {
    final provider = context.read<ChallengeProvider>();
    _correctCount = provider.sessionCorrectCount;
    _totalAnswered = provider.sessionQuestionsAnswered;
    _totalPoints = provider.sessionTotalPoints;
    _accuracy = provider.sessionAccuracy;
    _newTotalPoints = provider.lastResult?.newTotalPoints;
    _categoryId = provider.currentCategory?.id;
    _categoryName = provider.currentCategory?.name;
    // Always mark as loaded - show whatever data we have
    _dataLoaded = true;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading only if data hasn't been cached yet
    if (!_dataLoaded) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.electricCyan,
            ),
          ),
        ),
      );
    }

    final isGoodResult = _accuracy >= 50;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),

                // Result icon with animation
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: _ResultIcon(isCorrect: isGoodResult),
                ),

                const SizedBox(height: 32),

                // Result text
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'Session Complete!',
                        style: AppTypography.displayMedium.copyWith(
                          color: AppColors.electricCyan,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isGoodResult
                            ? 'Great job! Keep it up!'
                            : 'Keep practicing!',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Session stats cards
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _SessionStatsSection(
                    correctCount: _correctCount,
                    totalAnswered: _totalAnswered,
                    totalPoints: _totalPoints,
                    accuracy: _accuracy,
                  ),
                ),

                const SizedBox(height: 24),

                // New total points
                if (_newTotalPoints != null)
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: GlassmorphicCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppColors.electricCyan,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Total Points: ',
                            style: AppTypography.labelLarge,
                          ),
                          Text(
                            '$_newTotalPoints',
                            style: AppTypography.monoLarge.copyWith(
                              color: AppColors.electricCyan,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const Spacer(),

                // Action buttons
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: NeonButton(
                          text: 'Play Again',
                          icon: Icons.replay_rounded,
                          onPressed: () => _playAgain(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: NeonButton(
                          text: 'Back to Home',
                          isOutlined: true,
                          onPressed: () => _endSession(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _playAgain(BuildContext context) {
    if (_categoryId != null && _categoryId!.isNotEmpty) {
      // Go to home first, then push category for proper back-swipe support
      context.go('/home');
      context.push('/category/$_categoryId');
    } else {
      // Try to get category from provider as fallback
      final provider = context.read<ChallengeProvider>();
      final category = provider.currentCategory;
      if (category != null) {
        context.go('/home');
        context.push('/category/${category.id}');
      } else {
        context.go('/home');
      }
    }
  }

  void _endSession(BuildContext context) {
    context.read<ChallengeProvider>().endSession();
    context.go('/home');
  }
}

/// Animated result icon
class _ResultIcon extends StatelessWidget {
  final bool isCorrect;

  const _ResultIcon({required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.success : AppColors.error;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.3),
          ),
          child: Icon(
            isCorrect ? Icons.check_rounded : Icons.close_rounded,
            size: 48,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Session stats section
class _SessionStatsSection extends StatelessWidget {
  final int correctCount;
  final int totalAnswered;
  final int totalPoints;
  final int accuracy;

  const _SessionStatsSection({
    required this.correctCount,
    required this.totalAnswered,
    required this.totalPoints,
    required this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Correct',
            value: '$correctCount/$totalAnswered',
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Accuracy',
            value: '$accuracy%',
            icon: Icons.analytics_rounded,
            color: accuracy >= 50 ? AppColors.electricCyan : AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Points',
            value: totalPoints >= 0 ? '+$totalPoints' : '$totalPoints',
            icon: Icons.stars_rounded,
            color: totalPoints >= 0 ? AppColors.success : AppColors.error,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isPositive;
  final String suffix;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isPositive = true,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: AppTypography.monoLarge.copyWith(
                  color: color,
                  fontSize: 20,
                ),
              ),
              if (suffix.isNotEmpty)
                Text(
                  suffix,
                  style: AppTypography.bodySmall.copyWith(
                    color: color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.labelSmall,
          ),
        ],
      ),
    );
  }
}

/// Explanation card
class _ExplanationCard extends StatelessWidget {
  final String explanation;

  const _ExplanationCard({required this.explanation});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.electricCyan.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.electricCyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Explanation',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.electricCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            explanation,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Session summary shown at the end
class _SessionSummary extends StatelessWidget {
  final int totalQuestions;
  final int correctAnswers;
  final int totalPoints;

  const _SessionSummary({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.totalPoints,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = totalQuestions > 0
        ? (correctAnswers / totalQuestions * 100).toInt()
        : 0;

    return GlassmorphicCard(
      padding: const EdgeInsets.all(20),
      enableGlow: true,
      glowColor: AppColors.vividViolet,
      child: Column(
        children: [
          Text(
            'Session Complete!',
            style: AppTypography.headlineMedium,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SummaryItem(
                label: 'Correct',
                value: '$correctAnswers/$totalQuestions',
              ),
              _SummaryItem(
                label: 'Accuracy',
                value: '$accuracy%',
              ),
              _SummaryItem(
                label: 'Points',
                value: '+$totalPoints',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.monoLarge.copyWith(
            color: AppColors.electricCyan,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall,
        ),
      ],
    );
  }
}
