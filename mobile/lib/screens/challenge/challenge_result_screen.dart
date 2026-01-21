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

    // Refresh user data to get updated points/rank
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshUser();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Consumer<ChallengeProvider>(
            builder: (context, provider, _) {
              final result = provider.lastResult;
              final hasMore = provider.hasMoreChallenges;

              if (result == null) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.electricCyan,
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Spacer(),

                    // Result icon with animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: _ResultIcon(isCorrect: result.isCorrect),
                    ),

                    const SizedBox(height: 32),

                    // Result text
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            result.isCorrect ? 'Correct!' : 'Wrong!',
                            style: AppTypography.displayMedium.copyWith(
                              color: result.isCorrect
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            result.isCorrect
                                ? 'Great job! Keep it up!'
                                : 'Better luck next time!',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Stats cards
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _StatsSection(result: result),
                    ),

                    // Explanation (if available)
                    if (result.explanation != null) ...[
                      const SizedBox(height: 24),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _ExplanationCard(
                          explanation: result.explanation!,
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Action buttons
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          if (hasMore) ...[
                            SizedBox(
                              width: double.infinity,
                              child: NeonButton(
                                text: 'Next Question',
                                icon: Icons.arrow_forward_rounded,
                                onPressed: () => _nextQuestion(context),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: hasMore
                                ? NeonButton(
                                    text: 'End Session',
                                    isOutlined: true,
                                    onPressed: () => _endSession(context),
                                  )
                                : NeonButton(
                                    text: 'Complete',
                                    icon: Icons.check_circle_outline,
                                    onPressed: () => _endSession(context),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _nextQuestion(BuildContext context) {
    final provider = context.read<ChallengeProvider>();
    provider.nextChallenge();
    context.go('/challenge');
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

/// Stats section showing points and streak
class _StatsSection extends StatelessWidget {
  final ChallengeResult result;

  const _StatsSection({required this.result});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Points',
            value: result.isCorrect
                ? '+${result.pointsEarned}'
                : '${result.pointsEarned}',
            icon: Icons.stars_rounded,
            color: result.isCorrect ? AppColors.success : AppColors.error,
            isPositive: result.isCorrect,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Total',
            value: _formatNumber(result.newTotalPoints),
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.electricCyan,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Streak',
            value: '${result.streakDays}',
            icon: Icons.local_fire_department_rounded,
            color: result.streakUpdated
                ? AppColors.magentaPop
                : AppColors.textTertiary,
            suffix: result.streakUpdated ? '!' : '',
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
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
