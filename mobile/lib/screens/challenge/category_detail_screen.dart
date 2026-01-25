import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/category.dart';
import '../../providers/challenge_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/neon_button.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/gradient_progress_bar.dart';

class CategoryDetailScreen extends StatefulWidget {
  final Category category;

  const CategoryDetailScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize challenge session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChallengeProvider>().startSession(widget.category);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChallengeProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with category header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.deepSpace,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _CategoryHeader(category: widget.category),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats card (if user has stats)
                  if (widget.category.userStats != null)
                    _UserStatsCard(stats: widget.category.userStats!),

                  const SizedBox(height: 24),

                  // Difficulty section
                  Text(
                    'Select Difficulty',
                    style: AppTypography.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Higher difficulty = more points, tougher questions',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 16),

                  // Difficulty options
                  _DifficultySelector(
                    selectedDifficulty: provider.selectedDifficulty,
                    onSelect: (tier) => provider.setDifficulty(tier),
                    isUnlocked: provider.isDifficultyUnlocked,
                    getUnlockRequirement: provider.getUnlockRequirementText,
                    getUnlockProgress: provider.getUnlockProgress,
                  ),

                  const SizedBox(height: 32),

                  // Challenge info
                  _ChallengeInfoCard(
                    difficulty: provider.selectedDifficulty,
                  ),

                  const SizedBox(height: 32),

                  // Start button
                  SizedBox(
                    width: double.infinity,
                    child: NeonButton(
                      text: 'Start Challenge',
                      icon: Icons.play_arrow_rounded,
                      isLoading: provider.isLoading,
                      onPressed: provider.isLoading
                          ? null
                          : () => _startChallenge(context),
                    ),
                  ),

                  // Error message
                  if (provider.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              provider.error!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startChallenge(BuildContext context) async {
    final provider = context.read<ChallengeProvider>();
    final success = await provider.fetchChallenges();

    if (success && mounted) {
      context.push('/challenge');
    }
  }
}

/// Category header with icon and gradient background
class _CategoryHeader extends StatelessWidget {
  final Category category;

  const _CategoryHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _parseColor(category.colorPrimary).withOpacity(0.4),
            _parseColor(category.colorSecondary).withOpacity(0.2),
            AppColors.deepSpace,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CategoryIcon.fromCategory(
                    iconType: category.iconType,
                    colorPrimary: category.colorPrimary,
                    colorSecondary: category.colorSecondary,
                    size: 56,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: AppTypography.headlineLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (category.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            category.description!,
                            style: AppTypography.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}

/// User stats card
class _UserStatsCard extends StatelessWidget {
  final CategoryUserStats stats;

  const _UserStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: AppTypography.labelMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Points',
                  value: '${stats.points}',
                  icon: Icons.stars_rounded,
                  color: AppColors.electricCyan,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Rank',
                  value: stats.rank != null ? '#${stats.rank}' : '--',
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.vividViolet,
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Streak',
                  value: '${stats.streakDays}',
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.magentaPop,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GradientProgressBar(
            progress: stats.masteryPercentage / 100,
            height: 8,
            label: 'Mastery',
            showPercentage: true,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.mono.copyWith(color: color),
        ),
        Text(
          label,
          style: AppTypography.labelSmall,
        ),
      ],
    );
  }
}

/// Difficulty selector
class _DifficultySelector extends StatelessWidget {
  final int selectedDifficulty;
  final ValueChanged<int> onSelect;
  final bool Function(int) isUnlocked;
  final String Function(int) getUnlockRequirement;
  final double Function(int) getUnlockProgress;

  const _DifficultySelector({
    required this.selectedDifficulty,
    required this.onSelect,
    required this.isUnlocked,
    required this.getUnlockRequirement,
    required this.getUnlockProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int tier = 1; tier <= 5; tier++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _DifficultyOption(
              tier: tier,
              isSelected: selectedDifficulty == tier,
              isLocked: !isUnlocked(tier),
              onTap: () => onSelect(tier),
              unlockRequirement: getUnlockRequirement(tier),
              unlockProgress: getUnlockProgress(tier),
            ),
          ),
      ],
    );
  }
}

class _DifficultyOption extends StatelessWidget {
  final int tier;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;
  final String? unlockRequirement;
  final double unlockProgress;

  const _DifficultyOption({
    required this.tier,
    required this.isSelected,
    required this.isLocked,
    required this.onTap,
    this.unlockRequirement,
    this.unlockProgress = 0.0,
  });

  String get _label {
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

  String get _description {
    switch (tier) {
      case 1:
        return '1x points • Basic questions';
      case 2:
        return '1.5x points • Moderate difficulty';
      case 3:
        return '2x points • Challenging questions';
      case 4:
        return '3x points • Expert-level knowledge';
      case 5:
        return '5x points • Only for true masters';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tierColor = AppColors.getTierColor(tier);

    return GestureDetector(
      onTap: isLocked
          ? () => _showLockedDialog(context)
          : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? tierColor.withOpacity(0.15)
              : isLocked
                  ? AppColors.cardBackground.withOpacity(0.5)
                  : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? tierColor : AppColors.ghostBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: tierColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Tier indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isLocked
                        ? AppColors.cardBackground
                        : tierColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: isLocked
                        ? Icon(
                            Icons.lock_outline,
                            color: AppColors.textTertiary,
                            size: 20,
                          )
                        : Text(
                            '$tier',
                            style: AppTypography.headlineSmall.copyWith(
                              color: tierColor,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Label and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _label,
                        style: AppTypography.labelLarge.copyWith(
                          color: isLocked
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isLocked ? 'Locked' : _description,
                        style: AppTypography.labelSmall.copyWith(
                          color: isLocked
                              ? AppColors.textTertiary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Selection indicator or lock icon
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: tierColor,
                    size: 24,
                  )
                else if (isLocked)
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                    size: 24,
                  ),
              ],
            ),
            // Unlock progress bar for locked tiers
            if (isLocked && unlockProgress > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: unlockProgress,
                  backgroundColor: AppColors.ghostBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    tierColor.withOpacity(0.5),
                  ),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(unlockProgress * 100).toInt()}% progress',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: AppColors.vividViolet,
            ),
            const SizedBox(width: 12),
            Text(
              '$_label Locked',
              style: AppTypography.headlineSmall,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              unlockRequirement ?? 'Complete previous difficulty to unlock.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (unlockProgress > 0) ...[
              const SizedBox(height: 16),
              Text(
                'Your progress: ${(unlockProgress * 100).toInt()}%',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.electricCyan,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: unlockProgress,
                  backgroundColor: AppColors.ghostBorder,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.electricCyan,
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.electricCyan,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Challenge info card
class _ChallengeInfoCard extends StatelessWidget {
  final int difficulty;

  const _ChallengeInfoCard({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final tierColor = AppColors.getTierColor(difficulty);
    final timeLimit = _getTimeLimit(difficulty);
    final questionCount = 10; // Matches fetchChallenges default limit

    return GlassmorphicCard(
      borderColor: tierColor.withOpacity(0.3),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: tierColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Challenge Details',
                style: AppTypography.labelLarge.copyWith(color: tierColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Questions',
                  value: '$questionCount',
                ),
              ),
              Expanded(
                child: _InfoItem(
                  icon: Icons.timer_outlined,
                  label: 'Time each',
                  value: '${timeLimit}s',
                ),
              ),
              Expanded(
                child: _InfoItem(
                  icon: Icons.stars_outlined,
                  label: 'Multiplier',
                  value: '${_getMultiplier(difficulty)}x',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getTimeLimit(int tier) {
    switch (tier) {
      case 1:
        return 30;
      case 2:
        return 25;
      case 3:
        return 20;
      case 4:
        return 15;
      case 5:
        return 10;
      default:
        return 30;
    }
  }

  String _getMultiplier(int tier) {
    switch (tier) {
      case 1:
        return '1';
      case 2:
        return '1.5';
      case 3:
        return '2';
      case 4:
        return '3';
      case 5:
        return '5';
      default:
        return '1';
    }
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.mono.copyWith(
            color: AppColors.electricCyan,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: AppTypography.labelSmall,
        ),
      ],
    );
  }
}
