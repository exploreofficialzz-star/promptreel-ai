import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';

// Only import AdWidget/NativeAdListener on mobile
import 'native_ad_mobile.dart'
    if (dart.library.html) 'native_ad_web.dart';

class NativeAdCard extends ConsumerStatefulWidget {
  const NativeAdCard({super.key});

  @override
  ConsumerState<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends ConsumerState<NativeAdCard> {
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

    final ad = AdService.instance.createNativeAd(
      listener: buildNativeListener(
        onLoaded: () { if (mounted) setState(() => _loaded = true); },
        onFailed: (ad) { ad?.dispose(); },
      ),
    );
    if (ad == null) return;
    _ad = ad..load();
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
          buildNativeAdWidget(_ad),
          Positioned(
            top: 4, right: 6,
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

class NativeAdInjector {
  static List<Widget> buildList<T>({
    required List<T> items,
    required Widget Function(T item, int index) builder,
    int frequency = 8,
    bool isPaidUser = false,
  }) {
    if (isPaidUser || kIsWeb) {
      return items.asMap().entries.map((e) => builder(e.value, e.key)).toList();
    }
    final widgets = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      widgets.add(builder(items[i], i));
      if ((i + 1) % frequency == 0 && i < items.length - 1) {
        widgets.add(const NativeAdCard());
      }
    }
    return widgets;
  }
}
