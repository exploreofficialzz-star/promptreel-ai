import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';

/// Native ad that looks like a content card — blends into scene/prompt lists.
/// Appears every N items. Auto-hides for paid users.
class NativeAdCard extends ConsumerStatefulWidget {
  const NativeAdCard({super.key});

  @override
  ConsumerState<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends ConsumerState<NativeAdCard> {
  NativeAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final user = ref.read(currentUserProvider);
    if (user?.isPaid ?? false) return;

    final ad = AdService.instance.createNativeAd(
      listener: NativeAdListener(
        onAdLoaded: (_) { if (mounted) setState(() => _loaded = true); },
        onAdFailedToLoad: (ad, error) { ad.dispose(); },
      ),
    );
    if (ad == null) return;
    _ad = ad..load();
  }

  @override
  void dispose() { _ad?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user?.isPaid ?? false) return const SizedBox.shrink();
    if (!_loaded || _ad == null) return const SizedBox.shrink();

    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          AdWidget(ad: _ad!),
          // "Ad" label
          Positioned(
            top: 4,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: AppColors.border),
              ),
              child: Text('Ad', style: AppTypography.labelSmall),
            ),
          ),
        ],
      ),
    );
  }
}

/// Injects a native ad every [frequency] items into a list.
/// Usage: use NativeAdInjector.buildList(items, builder, frequency: 8)
class NativeAdInjector {
  static List<Widget> buildList<T>({
    required List<T> items,
    required Widget Function(T item, int index) builder,
    int frequency = 8,
    bool isPaidUser = false,
  }) {
    if (isPaidUser) {
      return items.asMap().entries.map((e) => builder(e.value, e.key)).toList();
    }

    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      widgets.add(builder(items[i], i));
      // Insert ad after every [frequency] items (starting from [frequency-1])
      if (!isPaidUser && (i + 1) % frequency == 0 && i < items.length - 1) {
        widgets.add(const NativeAdCard());
      }
    }
    return widgets;
  }
}
