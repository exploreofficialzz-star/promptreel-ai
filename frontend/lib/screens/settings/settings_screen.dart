import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go('/home'),
                ),
                title: Text('Settings', style: AppTypography.headlineMedium),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Profile card
                    _ProfileCard(user: user),
                    const SizedBox(height: AppSpacing.md),

                    // Plan card
                    _PlanCard(user: user),
                    const SizedBox(height: AppSpacing.md),

                    // Menu items
                    _SettingsGroup(
                      title: 'Account',
                      items: [
                        _SettingsItem(
                          icon: Icons.person_outline,
                          label: 'Edit Profile',
                          onTap: () {},
                        ),
                        _SettingsItem(
                          icon: Icons.lock_outline,
                          label: 'Change Password',
                          onTap: () {},
                        ),
                        _SettingsItem(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    _SettingsGroup(
                      title: 'App',
                      items: [
                        _SettingsItem(
                          icon: Icons.smart_toy_outlined,
                          label: 'AI Models',
                          trailing: 'GPT-4o · Claude · Grok',
                          onTap: () => context.go('/settings/ai-models'),
                        ),
                        _SettingsItem(
                          icon: Icons.build_outlined,
                          label: 'Recommended Tools',
                          onTap: () => context.go('/tools'),
                        ),
                        _SettingsItem(
                          icon: Icons.help_outline,
                          label: 'Help & FAQ',
                          onTap: () => launchUrl(Uri.parse('https://promptreel.ai/help')),
                        ),
                        _SettingsItem(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy Policy',
                          onTap: () => launchUrl(Uri.parse('https://promptreel.ai/privacy')),
                        ),
                        _SettingsItem(
                          icon: Icons.description_outlined,
                          label: 'Terms of Service',
                          onTap: () => launchUrl(Uri.parse('https://promptreel.ai/terms')),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppCard(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text('Are you sure you want to sign out?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) context.go('/login');
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: 12),
                          Text('Sign Out', style: AppTypography.titleMedium.copyWith(color: AppColors.error)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Center(
                      child: Column(
                        children: [
                          Text('PromptReel AI v1.0.0', style: AppTypography.bodySmall),
                          const SizedBox(height: 4),
                          Text('Made with ❤️ by chAs Tech Group', style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                  ].map((w) => w is SizedBox ? w : w).toList()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                style: AppTypography.displaySmall.copyWith(color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? 'Loading...', style: AppTypography.titleLarge),
                Text(user?.email ?? '', style: AppTypography.bodySmall),
                const SizedBox(height: 4),
                Text(
                  '${user?.totalPlansGenerated ?? 0} plans generated',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _PlanCard extends StatelessWidget {
  final user;
  const _PlanCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isPaid = user?.isPaid ?? false;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: isPaid
            ? const LinearGradient(colors: [Color(0xFF1A2A1A), Color(0xFF0A1A0A)])
            : AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isPaid ? AppColors.success.withOpacity(0.4) : AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isPaid ? '⭐ ${user?.plan?.toUpperCase() ?? ''} PLAN' : '🔮 FREE PLAN',
                style: AppTypography.labelMedium.copyWith(
                  color: isPaid ? AppColors.success : AppColors.primary,
                ),
              ),
              const Spacer(),
              if (!isPaid)
                GestureDetector(
                  onTap: () => context.go('/settings/plans'),
                  child: Text('Upgrade →', style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPaid
                ? 'Unlimited plans • No ads • Full export'
                : '${user?.plansRemaining ?? 3} plans remaining today • ${user?.maxDurationMinutes ?? 5}min max',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
          ),
          if (!isPaid) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Upgrade to Creator — \$15/mo',
              onPressed: () => context.go('/settings/plans'),
              fullWidth: true,
              height: 42,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsItem> items;

  const _SettingsGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: AppTypography.labelMedium),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((e) {
              return Column(
                children: [
                  e.value,
                  if (e.key < items.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;

  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppTypography.titleMedium)),
            if (trailing != null)
              Text(trailing!, style: AppTypography.bodySmall.copyWith(color: AppColors.primary)),
            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
