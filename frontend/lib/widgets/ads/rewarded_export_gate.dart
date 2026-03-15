import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';
import '../common/app_button.dart';

/// Shows a rewarded ad before allowing free users to export.
/// Paid users bypass entirely.
class RewardedExportGate extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;
  final String exportLabel;

  const RewardedExportGate({
    super.key,
    required this.onUnlocked,
    this.exportLabel = 'Download ZIP Package',
  });

  @override
  ConsumerState<RewardedExportGate> createState() => _RewardedExportGateState();
}

class _RewardedExportGateState extends ConsumerState<RewardedExportGate> {
  bool _loading = false;

  Future<void> _watchAd() async {
    setState(() => _loading = true);
    final user = ref.read(currentUserProvider);
    final rewarded = await AdService.instance.showRewarded(user);
    setState(() => _loading = false);
    if (rewarded || (user?.isPaid ?? false)) {
      widget.onUnlocked();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Watch the full ad to unlock your export.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    // Paid users: show button directly, no gate
    if (user?.isPaid ?? false) {
      return AppButton(
        label: '⬇  ${widget.exportLabel}',
        onPressed: widget.onUnlocked,
        fullWidth: true,
      );
    }

    // Free users: watch ad to unlock
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎬', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unlock Export', style: AppTypography.titleMedium),
                    Text(
                      'Watch a short ad to download your full package — or upgrade for instant access.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: _loading ? 'Loading ad...' : '▶  Watch Ad & Download',
            onPressed: _loading ? null : _watchAd,
            fullWidth: true,
            isLoading: _loading,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: '⭐  Upgrade for Instant Export',
            onPressed: () => Navigator.of(context).pushNamed('/settings/plans'),
            fullWidth: true,
            variant: AppButtonVariant.outline,
          ),
        ],
      ),
    );
  }
}
