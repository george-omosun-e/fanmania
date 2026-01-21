import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/challenge.dart';
import '../../providers/challenge_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/gradient_progress_bar.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  String? _selectedAnswer;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _startTimer();

    // Shake animation for wrong answers
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    final provider = context.read<ChallengeProvider>();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final currentSeconds = provider.remainingSeconds;
      if (currentSeconds > 0 && provider.timerActive) {
        provider.updateTimer(currentSeconds - 1);
      } else if (currentSeconds <= 0 && provider.timerActive) {
        timer.cancel();
        _onTimeUp();
      }
    });
  }

  void _onTimeUp() async {
    final provider = context.read<ChallengeProvider>();
    await provider.onTimeExpired();
    if (mounted) {
      context.push('/challenge/result');
    }
  }

  void _selectAnswer(String answerId) {
    if (_selectedAnswer != null) return; // Already selected

    setState(() {
      _selectedAnswer = answerId;
    });
  }

  Future<void> _submitAnswer() async {
    if (_selectedAnswer == null) return;

    final provider = context.read<ChallengeProvider>();
    _timer?.cancel();

    final success = await provider.submitAnswer(_selectedAnswer!);

    if (success && mounted) {
      context.push('/challenge/result');
    }
  }

  void _onBackPressed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Quit Challenge?', style: AppTypography.headlineMedium),
        content: Text(
          'Your progress will be lost.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChallengeProvider>().endSession();
              context.go('/home');
            },
            child: Text(
              'Quit',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) _onBackPressed();
      },
      child: Scaffold(
        body: SafeArea(
          child: Consumer<ChallengeProvider>(
            builder: (context, provider, _) {
              final challenge = provider.currentChallenge;

              if (challenge == null) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.electricCyan,
                  ),
                );
              }

              return Column(
                children: [
                  // Header
                  _ChallengeHeader(
                    currentIndex: provider.currentChallengeIndex + 1,
                    totalCount: provider.totalChallenges,
                    remainingSeconds: provider.remainingSeconds,
                    totalSeconds: challenge.timeLimitSeconds ?? 60,
                    difficulty: challenge.difficultyTier,
                    onClose: _onBackPressed,
                  ),

                  // Question and answers
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Question card
                          _QuestionCard(
                            question: challenge.questionData.question,
                            title: challenge.title,
                          ),

                          const SizedBox(height: 24),

                          // Answer options
                          ...challenge.questionData.options.map(
                            (option) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _AnswerOption(
                                option: option,
                                isSelected: _selectedAnswer == option.id,
                                onTap: () => _selectAnswer(option.id),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Submit button
                  _SubmitSection(
                    isEnabled: _selectedAnswer != null,
                    isLoading: provider.isSubmitting,
                    onSubmit: _submitAnswer,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Challenge header with progress and timer
class _ChallengeHeader extends StatelessWidget {
  final int currentIndex;
  final int totalCount;
  final int remainingSeconds;
  final int totalSeconds;
  final int difficulty;
  final VoidCallback onClose;

  const _ChallengeHeader({
    required this.currentIndex,
    required this.totalCount,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.difficulty,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentIndex / totalCount;
    final tierColor = AppColors.getTierColor(difficulty);
    final timerProgress = remainingSeconds / totalSeconds;
    final isTimeLow = timerProgress < 0.25;
    final isTimeCritical = timerProgress < 0.1;

    Color timerColor = AppColors.electricCyan;
    if (isTimeCritical) {
      timerColor = AppColors.error;
    } else if (isTimeLow) {
      timerColor = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
          bottom: BorderSide(color: AppColors.ghostBorder),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Close button
              GestureDetector(
                onTap: onClose,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Progress indicator
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question $currentIndex of $totalCount',
                          style: AppTypography.labelMedium,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: tierColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getDifficultyLabel(difficulty),
                            style: AppTypography.labelSmall.copyWith(
                              color: tierColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GradientProgressBar(
                      progress: progress,
                      height: 6,
                      showGlow: false,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.timer_outlined,
                color: timerColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _formatTime(remainingSeconds),
                style: AppTypography.monoLarge.copyWith(
                  color: timerColor,
                  fontWeight: isTimeCritical ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Timer progress bar
          TimerProgressBar(
            remainingSeconds: remainingSeconds,
            totalSeconds: totalSeconds,
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _getDifficultyLabel(int tier) {
    switch (tier) {
      case 1:
        return 'Easy';
      case 2:
        return 'Medium';
      case 3:
        return 'Hard';
      case 4:
        return 'Expert';
      case 5:
        return 'Master';
      default:
        return '';
    }
  }
}

/// Question card
class _QuestionCard extends StatelessWidget {
  final String question;
  final String title;

  const _QuestionCard({
    required this.question,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.electricCyan,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            question,
            style: AppTypography.headlineMedium.copyWith(
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Answer option button
class _AnswerOption extends StatelessWidget {
  final QuestionOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.electricCyan.withOpacity(0.15)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.electricCyan : AppColors.ghostBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.electricCyan.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Option indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.electricCyan
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.electricCyan
                      : AppColors.textTertiary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: AppColors.deepSpace,
                      size: 18,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Option text
            Expanded(
              child: Text(
                option.text,
                style: AppTypography.bodyLarge.copyWith(
                  color: isSelected
                      ? AppColors.electricCyan
                      : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Submit section
class _SubmitSection extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _SubmitSection({
    required this.isEnabled,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
          top: BorderSide(color: AppColors.ghostBorder),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isEnabled && !isLoading ? onSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled
                  ? AppColors.electricCyan
                  : AppColors.ghostBorder,
              foregroundColor: AppColors.deepSpace,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: isEnabled ? 4 : 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.deepSpace,
                    ),
                  )
                : Text(
                    'Submit Answer',
                    style: AppTypography.labelLarge.copyWith(
                      color: isEnabled
                          ? AppColors.deepSpace
                          : AppColors.textTertiary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
