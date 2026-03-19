import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';

// Only import AdWidget on mobile
import 'banner_ad_mobile.dart'
    if (dart.library.html) 'banner_ad_web.dart';

// ─── Inline Banner Ad ─────────────────────────────────────────────────────────
class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  dynamic _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadAd());
    }
  }

  void _loadAd() {
    final user = ref.read(currentUserProvider);
    if (user?.isPaid ?? false) return;
    final ad = AdService.instance.createBannerAd();
    if (ad == null) return;
    if (mounted) setState(() { _ad = ad; _loaded = true; });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    final user = ref.watch(currentUserProvider);
    if (user?.isPaid ?? false) return const SizedBox.shrink();
    if (!_loaded || _ad == null) return const SizedBox.shrink();

    return Container(
      height: _ad.size.height.toDouble(),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          top:    BorderSide(color: AppColors.border, width: 0.5),
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: buildAdWidget(_ad),
    );
  }
}

// ─── Sticky Bottom Banner ─────────────────────────────────────────────────────
class StickyBannerAd extends ConsumerStatefulWidget {
  final Widget child;
  const StickyBannerAd({super.key, required this.child});

  @override
  ConsumerState<StickyBannerAd> createState() => _StickyBannerAdState();
}

class _StickyBannerAdState extends ConsumerState<StickyBannerAd> {
  dynamic _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  void _load() {
    final user = ref.read(currentUserProvider);
    if (user?.isPaid ?? false) return;
    final ad = AdService.instance.createBannerAd();
    if (ad == null) return;
    if (mounted) setState(() { _ad = ad; _loaded = true; });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user   = ref.watch(currentUserProvider);
    final showAd = !kIsWeb && !(user?.isPaid ?? false) && _loaded && _ad != null;

    return Column(
      children: [
        Expanded(child: widget.child),
        if (showAd)
          Container(
            color: AppColors.surface,
            height: _ad.size.height.toDouble() + 1,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: buildAdWidget(_ad),
          ),
      ],
    );
  }
}

// ─── Large Banner Ad ──────────────────────────────────────────────────────────
class LargeBannerAd extends ConsumerStatefulWidget {
  const LargeBannerAd({super.key});

  @override
  ConsumerState<LargeBannerAd> createState() => _LargeBannerAdState();
}

class _LargeBannerAdState extends ConsumerState<LargeBannerAd> {
  dynamic _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  void _load() {
    final user = ref.read(currentUserProvider);
    if (user?.isPaid ?? false) return;
    final ad = AdService.instance.createBanner2Ad();
    if (ad == null) return;
    if (mounted) setState(() { _ad = ad; _loaded = true; });
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();
    final user = ref.watch(currentUserProvider);
    if (user?.isPaid ?? false) return const SizedBox.shrink();
    if (!_loaded || _ad == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: _ad.size.height.toDouble(),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: buildAdWidget(_ad),
    );
  }
}
