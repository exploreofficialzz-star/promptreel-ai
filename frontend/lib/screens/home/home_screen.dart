import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/projects_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../widgets/affiliate/affiliate_tab.dart';
import '../../config/app_config.dart';
import '../../models/project_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectsProvider.notifier).load();
      ref.read(projectsProvider.notifier).loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final projectsState = ref.watch(projectsProvider);

    return Scaffold(
      body: StickyBannerAd(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
              child: CustomScrollView(
          slivers: [
            _buildAppBar(user),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHero(user),
                  const SizedBox(height: AppSpacing.lg),
                  _buildStatsRow(projectsState),
                  const SizedBox(height: AppSpacing.lg),
                  _buildQuickCreate(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildRecentProjects(projectsState),
                  const SizedBox(height: AppSpacing.lg),
                  _buildRecommendedTools(),
                  const SizedBox(height: AppSpacing.md),
                  _buildFooter(),
                ]),
              ),
            ),
            // Floating affiliate banner — rotates every 6s, dismissible
            const FloatingAffiliateBanner(),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(user) {
    return SliverAppBar(
      floating: true,
      backgroundColor: AppColors.background.withOpacity(0.95),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.movie_filter_rounded, size: 18, color: Colors.black),
          ),
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
            child: Text(
              AppConfig.appName,
              style: AppTypography.headlineMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      actions: [
        if (user != null && user.isFree)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => context.go('/settings/plans'),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.15),
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              child: const Text('Upgrade ✦'),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.go('/settings'),
          color: AppColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildHero(user) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF12121A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user?.plan.toUpperCase() ?? 'FREE' + ' PLAN',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hello, ${user?.name.split(' ').first ?? 'Creator'} 👋',
                      style: AppTypography.displaySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConfig.tagline,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: '✦  Create Video Plan',
            onPressed: () => context.go('/create'),
            fullWidth: true,
            height: 52,
            fontSize: 15,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildStatsRow(projectsState) {
    final stats = projectsState.stats;
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: 'Total Plans',
            value: '${stats['total_projects'] ?? 0}',
            icon: const Icon(Icons.movie_outlined, size: 16, color: AppColors.primary),
            accentColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Today',
            value: '${stats['today_count'] ?? 0}',
            icon: const Icon(Icons.today_outlined, size: 16, color: AppColors.secondary),
            accentColor: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            label: 'Remaining',
            value: stats['daily_limit'] == -1
                ? '∞'
                : '${(stats['daily_limit'] ?? 3) - (stats['today_count'] ?? 0)}',
            icon: const Icon(Icons.bolt_outlined, size: 16, color: AppColors.warning),
            accentColor: AppColors.warning,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildQuickCreate() {
    final quickIdeas = [
      {'emoji': '🐍', 'text': 'Top 10 Deadliest Snakes'},
      {'emoji': '🌍', 'text': 'Dark History of Ancient Civilizations'},
      {'emoji': '💰', 'text': 'How to Make \$5K/Month Online'},
      {'emoji': '👻', 'text': 'Scariest Abandoned Places on Earth'},
      {'emoji': '🚀', 'text': 'Future Technology That Will Change Everything'},
      {'emoji': '🧠', 'text': 'Mind-Blowing Psychology Facts'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Quick Ideas', style: AppTypography.headlineMedium),
            GestureDetector(
              onTap: () => context.go('/create'),
              child: Text('Custom →', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: quickIdeas.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    context.go('/create', extra: e.value['text']);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Text(e.value['emoji']!, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(e.value['text']!, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ).animate(delay: Duration(milliseconds: e.key * 60)).fadeIn().slideX(begin: 0.1);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentProjects(projectsState) {
    final projects = projectsState.projects.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Projects', style: AppTypography.headlineMedium),
            GestureDetector(
              onTap: () => context.go('/projects'),
              child: Text('View all →', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (projectsState.isLoading)
          ...List.generate(3, (_) => const _ShimmerCard())
        else if (projects.isEmpty)
          _buildEmptyProjects()
        else
          ...projects.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ProjectTile(project: e.value),
              ).animate(delay: Duration(milliseconds: e.key * 80)).fadeIn().slideY(begin: 0.1)),
      ],
    );
  }

  Widget _buildEmptyProjects() {
    return AppCard(
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.movie_creation_outlined, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No projects yet', style: AppTypography.titleMedium),
          const SizedBox(height: 4),
          Text('Create your first video plan to get started', style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Create Your First Plan',
            onPressed: () => context.go('/create'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildRecommendedTools() {
    return const AffiliateToolsRow(title: 'Recommended Tools');
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        AppConfig.footerCredit,
        style: AppTypography.bodySmall,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final ProjectModel project;
  const _ProjectTile({required this.project});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go('/results/${project.id}'),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Text(
                _getPlatformEmoji(project.platform),
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  style: AppTypography.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _Chip(project.platform),
                    const SizedBox(width: 6),
                    _Chip('${project.durationMinutes}min'),
                    const SizedBox(width: 6),
                    _Chip('${project.totalScenes} scenes'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusBadge(project.status),
        ],
      ),
    );
  }

  String _getPlatformEmoji(String platform) {
    switch (platform) {
      case 'YouTube': return '▶️';
      case 'TikTok': return '🎵';
      case 'Instagram': return '📸';
      default: return '📱';
    }
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(text, style: AppTypography.labelSmall),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'completed': color = AppColors.success; break;
      case 'failed': color = AppColors.error; break;
      default: color = AppColors.warning;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}
