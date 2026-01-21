import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../models/category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/gradient_progress_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch categories when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentNavIndex,
          children: const [
            _HomeTab(),
            _LeaderboardTab(),
            _ProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
          top: BorderSide(
            color: AppColors.ghostBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: _currentNavIndex == 0,
                onTap: () => setState(() => _currentNavIndex = 0),
              ),
              _NavItem(
                icon: Icons.leaderboard_rounded,
                label: 'Rankings',
                isSelected: _currentNavIndex == 1,
                onTap: () => setState(() => _currentNavIndex = 1),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: _currentNavIndex == 2,
                onTap: () => setState(() => _currentNavIndex = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navigation item widget
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.electricCyan.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.electricCyan : AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.electricCyan : AppColors.textTertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Home Tab - Main content
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<CategoryProvider>().refresh();
      },
      color: AppColors.electricCyan,
      backgroundColor: AppColors.surfaceElevated,
      child: CustomScrollView(
        slivers: [
          // Header with user stats
          SliverToBoxAdapter(
            child: _UserStatsHeader(),
          ),

          // Section title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Text(
                'Choose Your Arena',
                style: AppTypography.headlineMedium,
              ),
            ),
          ),

          // Category grid
          const _CategoryGrid(),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }
}

/// User stats header
class _UserStatsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.vividViolet.withOpacity(0.2),
            AppColors.deepSpace,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting row
          Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.electricCyan.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    user?.username.substring(0, 1).toUpperCase() ?? 'F',
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.deepSpace,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Greeting text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      user?.displayNameOrUsername ?? 'Fan',
                      style: AppTypography.headlineLarge,
                    ),
                  ],
                ),
              ),
              // Notification bell
              IconButton(
                onPressed: () {
                  // TODO: Navigate to notifications
                },
                icon: Stack(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textSecondary,
                      size: 28,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.magentaPop,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Points',
                  value: _formatNumber(user?.totalPoints ?? 0),
                  icon: Icons.stars_rounded,
                  color: AppColors.electricCyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Global Rank',
                  value: user?.globalRank != null ? '#${user!.globalRank}' : '--',
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.vividViolet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Streak',
                  value: '0', // TODO: Get from user stats
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.magentaPop,
                  suffix: ' days',
                ),
              ),
            ],
          ),
        ],
      ),
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

/// Individual stat card
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? suffix;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: AppTypography.mono.copyWith(
                  color: color,
                  fontSize: 18,
                ),
              ),
              if (suffix != null)
                Text(
                  suffix!,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
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

/// Category grid
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && !provider.hasCategories) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: CircularProgressIndicator(
                  color: AppColors.electricCyan,
                ),
              ),
            ),
          );
        }

        if (provider.error != null && !provider.hasCategories) {
          return SliverToBoxAdapter(
            child: _ErrorState(
              message: provider.error!,
              onRetry: () => provider.fetchCategories(),
            ),
          );
        }

        if (!provider.hasCategories) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'No categories available',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = provider.categories[index];
                return _CategoryCard(category: category);
              },
              childCount: provider.categories.length,
            ),
          ),
        );
      },
    );
  }
}

/// Individual category card
class _CategoryCard extends StatelessWidget {
  final Category category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCardAnimated(
      onTap: () {
        context.read<CategoryProvider>().selectCategory(category);
        context.push('/category/${category.id}', extra: category);
      },
      accentColor: _parseColor(category.colorPrimary),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category icon
          CategoryIcon.fromCategory(
            iconType: category.iconType,
            colorPrimary: category.colorPrimary,
            colorSecondary: category.colorSecondary,
            size: 48,
          ),

          const Spacer(),

          // Category name
          Text(
            category.name,
            style: AppTypography.headlineSmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // User stats (if available)
          if (category.userStats != null) ...[
            GradientProgressBar(
              progress: category.userStats!.masteryPercentage / 100,
              height: 4,
              showGlow: false,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${category.userStats!.masteryPercentage.toStringAsFixed(0)}% mastery',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                if (category.userStats!.rank != null)
                  Text(
                    '#${category.userStats!.rank}',
                    style: AppTypography.rank.copyWith(fontSize: 12),
                  ),
              ],
            ),
          ] else
            Text(
              'Tap to start',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.electricCyan,
              ),
            ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
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
              'Failed to load categories',
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

/// Placeholder for Leaderboard tab
class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_rounded,
            size: 64,
            color: AppColors.vividViolet.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Leaderboards',
            style: AppTypography.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder for Profile tab
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: AppColors.cyanGlow,
            ),
            child: Center(
              child: Text(
                user?.username.substring(0, 1).toUpperCase() ?? 'F',
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.deepSpace,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            user?.displayNameOrUsername ?? 'Fan',
            style: AppTypography.headlineLarge,
          ),
          Text(
            '@${user?.username ?? 'username'}',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 40),

          // Stats cards
          GlassmorphicCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _ProfileStatRow(
                  label: 'Total Points',
                  value: '${user?.totalPoints ?? 0}',
                  icon: Icons.stars_rounded,
                ),
                const Divider(color: AppColors.ghostBorder, height: 24),
                _ProfileStatRow(
                  label: 'Global Rank',
                  value: user?.globalRank != null ? '#${user!.globalRank}' : 'Unranked',
                  icon: Icons.emoji_events_rounded,
                ),
                const Divider(color: AppColors.ghostBorder, height: 24),
                _ProfileStatRow(
                  label: 'Member Since',
                  value: _formatDate(user?.createdAt),
                  icon: Icons.calendar_today_rounded,
                ),
              ],
            ),
          ),

          const Spacer(),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await authProvider.logout();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ProfileStatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileStatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textTertiary, size: 20),
        const SizedBox(width: 12),
        Text(label, style: AppTypography.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: AppTypography.mono.copyWith(
            color: AppColors.electricCyan,
          ),
        ),
      ],
    );
  }
}
