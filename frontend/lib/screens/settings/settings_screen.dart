import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/ads/banner_ad_widget.dart';

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
                    _ProfileCard(user: user),
                    const SizedBox(height: AppSpacing.md),
                    _PlanCard(user: user),
                    const SizedBox(height: AppSpacing.md),

                    // ── Large Banner Ad (mobile free users only) ───────────
                    const LargeBannerAd(),
                    const SizedBox(height: AppSpacing.md),

                    _SettingsGroup(
                      title: 'Account',
                      items: [
                        _SettingsItem(
                          icon: Icons.person_outline,
                          label: 'Edit Profile',
                          onTap: () =>
                              _showEditProfileSheet(context, ref, user),
                        ),
                        _SettingsItem(
                          icon: Icons.lock_outline,
                          label: 'Change Password',
                          onTap: () =>
                              _showChangePasswordSheet(context, ref),
                        ),
                        _SettingsItem(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          onTap: () =>
                              _showNotificationsSheet(context, ref),
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
                          onTap: () =>
                              context.go('/settings/ai-models'),
                        ),
                        _SettingsItem(
                          icon: Icons.build_outlined,
                          label: 'Recommended Tools',
                          onTap: () => context.go('/tools'),
                        ),
                        _SettingsItem(
                          icon: Icons.help_outline,
                          label: 'Help & FAQ',
                          onTap: () => launchUrl(
                              Uri.parse('https://promptreel.ai/help')),
                        ),
                        // ── FIX: Privacy & Terms use in-app routes on web ──
                        _SettingsItem(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy Policy',
                          onTap: () => kIsWeb
                              ? context.go('/privacy')
                              : launchUrl(Uri.parse(
                                  'https://promptreel.ai/privacy')),
                        ),
                        _SettingsItem(
                          icon: Icons.description_outlined,
                          label: 'Terms of Service',
                          onTap: () => kIsWeb
                              ? context.go('/terms')
                              : launchUrl(Uri.parse(
                                  'https://promptreel.ai/terms')),
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
                            content: const Text(
                                'Are you sure you want to sign out?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, true),
                                child: const Text('Sign Out',
                                    style: TextStyle(
                                        color: AppColors.error)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref
                              .read(authProvider.notifier)
                              .logout();
                          if (context.mounted)
                            context.go('/login');
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.logout_rounded,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 12),
                          Text('Sign Out',
                              style: AppTypography.titleMedium
                                  .copyWith(color: AppColors.error)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: Column(
                        children: [
                          Text('PromptReel AI v1.0.0',
                              style: AppTypography.bodySmall),
                          const SizedBox(height: 4),
                          Text('Made with ❤️ by chAs Tech Group',
                              style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileSheet(
      BuildContext context, WidgetRef ref, dynamic user) {
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final formKey  = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Edit Profile',
                  style: AppTypography.headlineMedium),
              const SizedBox(height: 4),
              Text('Update your display name',
                  style: AppTypography.bodySmall),
              const SizedBox(height: 24),
              TextFormField(
                controller: nameCtrl,
                style: AppTypography.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: user?.email ?? '',
                readOnly: true,
                style: AppTypography.bodyLarge
                    .copyWith(color: AppColors.textMuted),
                decoration: const InputDecoration(
                  labelText: 'Email (cannot be changed)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 24),
              _SubmitButton(
                label: 'Save Changes',
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  try {
                    await ref
                        .read(apiServiceProvider)
                        .updateProfile(
                          name: nameCtrl.text.trim(),
                        );
                    await ref
                        .read(authProvider.notifier)
                        .refreshUser();
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      _showSnack(context, '✅ Profile updated!');
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      _showSnack(
                          context, ApiService.extractError(e),
                          isError: true);
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordSheet(
      BuildContext context, WidgetRef ref) {
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey     = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          bool showCurrent = false;
          bool showNew     = false;

          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Change Password',
                      style: AppTypography.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                      'Enter your current password then set a new one',
                      style: AppTypography.bodySmall),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: currentCtrl,
                    obscureText: !showCurrent,
                    style: AppTypography.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon:
                          const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(showCurrent
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(
                            () => showCurrent = !showCurrent),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Enter your current password'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newCtrl,
                    obscureText: !showNew,
                    style: AppTypography.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon:
                          const Icon(Icons.lock_reset_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(showNew
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => showNew = !showNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: true,
                    style: AppTypography.bodyLarge,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon:
                          Icon(Icons.check_circle_outline),
                    ),
                    validator: (v) => v != newCtrl.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  _SubmitButton(
                    label: 'Update Password',
                    onPressed: () async {
                      if (!formKey.currentState!.validate())
                        return;
                      try {
                        await ref
                            .read(apiServiceProvider)
                            .updateProfile(
                              currentPassword: currentCtrl.text,
                              newPassword: newCtrl.text,
                            );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _showSnack(context,
                              '✅ Password updated successfully!');
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          _showSnack(context,
                              ApiService.extractError(e),
                              isError: true);
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNotificationsSheet(
      BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _NotificationsSheet(),
    );
  }

  void _showSnack(BuildContext context, String msg,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Notifications Sheet ───────────────────────────────────────────────────────
class _NotificationsSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NotificationsSheet> createState() =>
      _NotificationsSheetState();
}

class _NotificationsSheetState
    extends ConsumerState<_NotificationsSheet> {
  bool _generationComplete = true;
  bool _dailyReminder      = false;
  bool _productUpdates     = true;
  bool _promotions         = false;
  bool _isSaving           = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await ref
          .read(apiServiceProvider)
          .getNotificationPreferences();
      if (mounted) {
        setState(() {
          _generationComplete =
              prefs['generation_complete'] ?? true;
          _dailyReminder  = prefs['daily_reminder'] ?? false;
          _productUpdates = prefs['product_updates'] ?? true;
          _promotions     = prefs['promotions'] ?? false;
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(apiServiceProvider)
          .updateNotificationPreferences({
        'generation_complete': _generationComplete,
        'daily_reminder':      _dailyReminder,
        'product_updates':     _productUpdates,
        'promotions':          _promotions,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notification preferences saved!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiService.extractError(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Notifications',
              style: AppTypography.headlineMedium),
          const SizedBox(height: 4),
          Text('Choose what you want to be notified about',
              style: AppTypography.bodySmall),
          const SizedBox(height: 20),
          _NotifToggle(
            label: 'Generation Complete',
            subtitle: 'When your video plan is ready',
            value: _generationComplete,
            onChanged: (v) =>
                setState(() => _generationComplete = v),
          ),
          _NotifToggle(
            label: 'Daily Reminder',
            subtitle: 'Remind me to create a video plan today',
            value: _dailyReminder,
            onChanged: (v) =>
                setState(() => _dailyReminder = v),
          ),
          _NotifToggle(
            label: 'Product Updates',
            subtitle: 'New features and improvements',
            value: _productUpdates,
            onChanged: (v) =>
                setState(() => _productUpdates = v),
          ),
          _NotifToggle(
            label: 'Promotions',
            subtitle: 'Special offers and discounts',
            value: _promotions,
            onChanged: (v) =>
                setState(() => _promotions = v),
          ),
          const SizedBox(height: 24),
          _SubmitButton(
            label: _isSaving ? 'Saving...' : 'Save Preferences',
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _NotifToggle extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.titleMedium),
                Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

// ── Submit Button ─────────────────────────────────────────────────────────────
class _SubmitButton extends StatefulWidget {
  final String label;
  final Future<void> Function()? onPressed;

  const _SubmitButton(
      {required this.label, required this.onPressed});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: _loading ? 'Please wait...' : widget.label,
      isLoading: _loading,
      fullWidth: true,
      height: 50,
      onPressed: widget.onPressed == null
          ? null
          : () async {
              setState(() => _loading = true);
              try {
                await widget.onPressed!();
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final dynamic user;
  const _ProfileCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                style: AppTypography.displaySmall
                    .copyWith(color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? 'Loading...',
                    style: AppTypography.titleLarge),
                Text(user?.email ?? '',
                    style: AppTypography.bodySmall),
                const SizedBox(height: 4),
                Text(
                  '${user?.totalPlansGenerated ?? 0} plans generated',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

// ── Plan Card ─────────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final dynamic user;
  const _PlanCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isPaid = user?.isPaid ?? false;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: isPaid
            ? const LinearGradient(colors: [
                Color(0xFF1A2A1A),
                Color(0xFF0A1A0A),
              ])
            : AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isPaid
              ? AppColors.success.withOpacity(0.4)
              : AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isPaid
                    ? '⭐ ${user?.plan?.toUpperCase() ?? ''} PLAN'
                    : '🔮 FREE PLAN',
                style: AppTypography.labelMedium.copyWith(
                  color: isPaid
                      ? AppColors.success
                      : AppColors.primary,
                ),
              ),
              const Spacer(),
              if (!isPaid)
                GestureDetector(
                  onTap: () => context.go('/settings/plans'),
                  child: Text('Upgrade →',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.primary)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPaid
                ? 'Unlimited plans • No ads • Full export'
                : '${user?.plansRemaining ?? 3} plans remaining today • ${user?.maxDurationMinutes ?? 5}min max',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textPrimary),
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

// ── Settings Group ────────────────────────────────────────────────────────────
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
                  if (e.key < items.length - 1)
                    const Divider(
                        height: 1, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Settings Item ─────────────────────────────────────────────────────────────
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
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: AppTypography.titleMedium)),
            if (trailing != null)
              Text(trailing!,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.primary)),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
