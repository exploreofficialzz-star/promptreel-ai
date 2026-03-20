import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';
import '../common/app_button.dart';

/// Shows a rewarded ad before allowing free users to export.
/// Paid users bypass entirely.
/// Web users bypass entirely (AdMob not supported on web).
class RewardedExportGate extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;
  final String exportLabel;

  const RewardedExportGate({
    super.key,
    required this.onUnlocked,
    this.exportLabel = 'Download ZIP Package',
  });

  @override
  ConsumerState<RewardedExportGate> createState() =>
      _RewardedExportGateState();
}

class _RewardedExportGateState extends ConsumerState<RewardedExportGate> {
  bool _loading = false;
  bool _adReady = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _preloadAd();
  }

  Future<void> _preloadAd() async {
    // ✅ Skip on web — AdMob not supported
    if (kIsWeb) return;

    final user = ref.read(currentUserProvider);
    if (user?.isPaid ?? false) return;

    try {
      await AdService.instance.loadRewarded();
      if (mounted) setState(() => _adReady = true);
      debugPrint('✅ Rewarded ad preloaded');
    } catch (e) {
      debugPrint('⚠️ Failed to preload rewarded ad: $e');
    }
  }

  Future<void> _watchAd() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _statusMessage = '';
    });

    final user = ref.read(currentUserProvider);

    // ✅ Web or paid users — unlock directly
    if (kIsWeb || (user?.isPaid ?? false)) {
      if (mounted) setState(() => _loading = false);
      widget.onUnlocked();
      return;
    }

    try {
      // ✅ FIX: Reload ad if not ready before showing
      if (!_adReady) {
        if (mounted) {
          setState(() => _statusMessage = 'Loading ad, please wait...');
        }
        await AdService.instance.loadRewarded();
        // Wait a moment for ad to fully load
        await Future.delayed(const Duration(seconds: 2));
      }

      final rewarded = await AdService.instance.showRewarded(user);

      if (mounted) {
        setState(() {
          _loading = false;
          _adReady = false; // ✅ Reset — ad was consumed
          _statusMessage = '';
        });
      }

      if (rewarded) {
        // ✅ Ad watched — unlock export
        widget.onUnlocked();
        // ✅ Preload next ad immediately for next time
        _preloadAd();
      } else {
        // ✅ FIX: Better message explaining what happened
        if (mounted) {
          setState(() => _statusMessage =
              'Ad not available yet. Please try again in a moment.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '⚠️ Ad not available. Please try again or upgrade to export instantly.',
              ),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Upgrade',
                textColor: Colors.black,
                onPressed: () => context.go('/settings/plans'),
              ),
            ),
          );
          // ✅ Preload ad for next attempt
          _preloadAd();
        }
      }
    } catch (e) {
      debugPrint('❌ Rewarded ad error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _statusMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                '❌ Could not load ad. Please check your connection and try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Upgrade',
              textColor: Colors.white,
              onPressed: () => context.go('/settings/plans'),
            ),
          ),
        );
        // ✅ Retry preload after error
        _preloadAd();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isPaid = user?.isPaid ?? false;

    // ✅ Paid users or web: show button directly — no gate
    if (isPaid || kIsWeb) {
      return AppButton(
        label: '⬇  ${widget.exportLabel}',
        onPressed: widget.onUnlocked,
        fullWidth: true,
      );
    }

    // ✅ Free users on mobile: watch ad to unlock
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
                    Text('Unlock Export',
                        style: AppTypography.titleMedium),
                    Text(
                      'Watch a short ad to download your full package — or upgrade for instant access.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ✅ Ad ready indicator
          if (_adReady && !_loading) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 12, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  'Ad ready',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.success),
                ),
              ],
            ),
          ],

          // ✅ Status message
          if (_statusMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.warning),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          AppButton(
            label: _loading
                ? 'Loading ad...'
                : _adReady
                    ? '▶  Watch Ad & Download'
                    : '▶  Load & Watch Ad',
            onPressed: _loading ? null : _watchAd,
            fullWidth: true,
            isLoading: _loading,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: '⭐  Upgrade for Instant Export',
            onPressed: () => context.go('/settings/plans'),
            fullWidth: true,
            variant: AppButtonVariant.outline,
          ),
        ],
      ),
    );
  }
}
