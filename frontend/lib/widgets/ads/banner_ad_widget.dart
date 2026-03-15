import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';

/// Inline banner ad — auto-hides for paid users.
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAd());
  }

  void _loadAd() {
    final user = ref.read(currentUserProvider);
    if (user?.isPaid ?? false) return; // Skip for paid users
    final ad = AdService.instance.createBannerAd();
    if (ad == null) return;
    ad.load().then((_) {
      if (mounted) setState(() { _ad = ad; _loaded = true; });
    });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user?.isPaid ?? false) return const SizedBox.shrink();
    if (!_loaded || _ad == null) return const SizedBox.shrink();

    return Container(
      height: _ad!.size.height.toDouble(),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: AdWidget(ad: _ad!),
    );
  }
}

/// Sticky bottom banner — shown in footer for free users.
class StickyBannerAd extends ConsumerStatefulWidget {
  final Widget child;
  const StickyBannerAd({super.key, required this.child});

  @override
  ConsumerState<StickyBannerAd> createState() => _StickyBannerAdState();
}

class _StickyBannerAdState extends ConsumerState<StickyBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final user = ref.read(currentUserProvider);
    if (user?.isPaid ?? false) return;
    final ad = AdService.instance.createBannerAd();
    if (ad == null) return;
    ad.load().then((_) {
      if (mounted) setState(() { _ad = ad; _loaded = true; });
    });
  }

  @override
  void dispose() { _ad?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final showAd = !(user?.isPaid ?? false) && _loaded && _ad != null;

    return Column(
      children: [
        Expanded(child: widget.child),
        if (showAd)
          Container(
            color: AppColors.surface,
            height: _ad!.size.height.toDouble() + 1,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: AdWidget(ad: _ad!),
          ),
      ],
    );
  }
}
