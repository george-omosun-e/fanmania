import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/leaderboard.dart';
import '../../models/category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../widgets/glassmorphic_card.dart';

class LeaderboardTab extends StatefulWidget {
  const LeaderboardTab({super.key});

  @override
  State<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<LeaderboardTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaderboardProvider>().fetchGlobalLeaderboard();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final provider = context.read<LeaderboardProvider>();
      if (_tabController.index == 0) {
        provider.fetchGlobalLeaderboard();
      } else if (_selectedCategoryId != null) {
        provider.fetchCategoryLeaderboard(categoryId: _selectedCategoryId!);
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Row(
            children: [
              Text(
                'Leaderboards',
                style: AppTypography.headlineLarge,
              ),
            ],
          ),
        ),

        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.electricCyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: AppColors.electricCyan,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: AppTypography.labelLarge,
            tabs: const [
              Tab(text: 'Global'),
              Tab(text: 'By Category'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Time scope selector
        _TimeScopeSelector(),

        const SizedBox(height: 16),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _GlobalLeaderboardView(),
              _CategoryLeaderboardView(
                selectedCategoryId: _selectedCategoryId,
                onCategorySelected: (categoryId) {
                  setState(() => _selectedCategoryId = categoryId);
                  context.read<LeaderboardProvider>().fetchCategoryLeaderboard(
                        categoryId: categoryId,
                      );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Time scope selector
class _TimeScopeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LeaderboardProvider>();
    final scopes = ['weekly', 'monthly', 'all_time'];
    final scopeLabels = {'weekly': 'Weekly', 'monthly': 'Monthly', 'all_time': 'All Time'};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: scopes.map((scope) {
          final isSelected = provider.currentScope == scope;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => provider.setScope(scope),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.vividViolet.withOpacity(0.2)
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.vividViolet : AppColors.ghostBorder,
                  ),
                ),
                child: Text(
                  scopeLabels[scope]!,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? AppColors.vividViolet : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Global leaderboard view
class _GlobalLeaderboardView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LeaderboardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.globalLeaderboard == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.electricCyan),
          );
        }

        if (provider.error != null && provider.globalLeaderboard == null) {
          return _ErrorState(
            message: provider.error!,
            onRetry: () => provider.fetchGlobalLeaderboard(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchGlobalLeaderboard(),
          color: AppColors.electricCyan,
          backgroundColor: AppColors.surfaceElevated,
          child: _LeaderboardList(
            entries: provider.currentEntries,
            userRank: provider.userRank,
            totalUsers: provider.totalUsers,
          ),
        );
      },
    );
  }
}

/// Category leaderboard view
class _CategoryLeaderboardView extends StatelessWidget {
  final String? selectedCategoryId;
  final ValueChanged<String> onCategorySelected;

  const _CategoryLeaderboardView({
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    if (selectedCategoryId == null || selectedCategoryId!.isEmpty) {
      return _CategorySelector(
        categories: categories,
        onCategorySelected: onCategorySelected,
      );
    }

    return Consumer<LeaderboardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.categoryLeaderboard == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.electricCyan),
          );
        }

        if (provider.error != null && provider.categoryLeaderboard == null) {
          return _ErrorState(
            message: provider.error!,
            onRetry: () => provider.fetchCategoryLeaderboard(
              categoryId: selectedCategoryId!,
            ),
          );
        }

        final category = categories.firstWhere(
          (c) => c.id == selectedCategoryId,
          orElse: () => categories.first,
        );

        return Column(
          children: [
            // Category selector chip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => onCategorySelected(''),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.ghostBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category.name,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.fetchCategoryLeaderboard(
                  categoryId: selectedCategoryId!,
                ),
                color: AppColors.electricCyan,
                backgroundColor: AppColors.surfaceElevated,
                child: _LeaderboardList(
                  entries: provider.currentEntries,
                  userRank: provider.userRank,
                  totalUsers: provider.totalUsers,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Category selector grid
class _CategorySelector extends StatelessWidget {
  final List<Category> categories;
  final ValueChanged<String> onCategorySelected;

  const _CategorySelector({
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Center(
        child: Text(
          'No categories available',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassmorphicCardAnimated(
            onTap: () => onCategorySelected(category.id),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _parseColor(category.colorPrimary).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: _parseColor(category.colorPrimary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: AppTypography.labelLarge,
                      ),
                      if (category.description != null)
                        Text(
                          category.description!,
                          style: AppTypography.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}

/// Leaderboard list
class _LeaderboardList extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final int? userRank;
  final int totalUsers;

  const _LeaderboardList({
    required this.entries,
    this.userRank,
    required this.totalUsers,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No rankings yet',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to compete!',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final currentUserId = context.read<AuthProvider>().currentUser?.id;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: entries.length + (userRank != null ? 1 : 0),
      itemBuilder: (context, index) {
        // Show user's rank at the bottom if they're not in top
        if (userRank != null && index == entries.length) {
          final userEntry = entries.where((e) => e.userId == currentUserId).firstOrNull;
          if (userEntry == null) {
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 20),
              child: Column(
                children: [
                  const Divider(color: AppColors.ghostBorder),
                  const SizedBox(height: 16),
                  Text(
                    'Your Rank: #$userRank of $totalUsers',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.electricCyan,
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final entry = entries[index];
        final isCurrentUser = entry.userId == currentUserId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _LeaderboardEntryTile(
            entry: entry,
            isCurrentUser: isCurrentUser,
          ),
        );
      },
    );
  }
}

/// Individual leaderboard entry tile
class _LeaderboardEntryTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _LeaderboardEntryTile({
    required this.entry,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      borderColor: isCurrentUser ? AppColors.electricCyan.withOpacity(0.5) : null,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 40,
            child: _RankBadge(rank: entry.rank),
          ),
          const SizedBox(width: 12),
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isCurrentUser ? AppColors.primaryGradient : null,
              color: isCurrentUser ? null : AppColors.surfaceElevated,
              border: Border.all(
                color: isCurrentUser ? AppColors.electricCyan : AppColors.ghostBorder,
                width: isCurrentUser ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                entry.displayNameOrUsername.substring(0, 1).toUpperCase(),
                style: AppTypography.labelLarge.copyWith(
                  color: isCurrentUser ? AppColors.deepSpace : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayNameOrUsername,
                  style: AppTypography.labelMedium.copyWith(
                    color: isCurrentUser ? AppColors.electricCyan : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '@${entry.username}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatPoints(entry.points),
                style: AppTypography.mono.copyWith(
                  color: AppColors.electricCyan,
                  fontSize: 16,
                ),
              ),
              Text(
                'pts',
                style: AppTypography.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPoints(int points) {
    if (points >= 1000000) {
      return '${(points / 1000000).toStringAsFixed(1)}M';
    } else if (points >= 1000) {
      return '${(points / 1000).toStringAsFixed(1)}K';
    }
    return points.toString();
  }
}

/// Rank badge with special styling for top 3
class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank <= 3) {
      final colors = [
        const Color(0xFFFFD700), // Gold
        const Color(0xFFC0C0C0), // Silver
        const Color(0xFFCD7F32), // Bronze
      ];
      final icons = [
        Icons.looks_one_rounded,
        Icons.looks_two_rounded,
        Icons.looks_3_rounded,
      ];

      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors[rank - 1].withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icons[rank - 1],
          color: colors[rank - 1],
          size: 24,
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '#$rank',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Error state widget
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load leaderboard',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
