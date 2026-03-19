import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/connectivity_service.dart';

/// Wrap any screen body with this to get an automatic offline banner.
///
/// Usage:
/// ```dart
/// Scaffold(
///   body: NetworkBanner(
///     child: YourScreenContent(),
///   ),
/// )
/// ```
class NetworkBanner extends ConsumerWidget {
  final Widget child;
  const NetworkBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider);
    final isOffline = status == NetworkStatus.offline;

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: child,
          ),
          child: isOffline
              ? _OfflineBanner(key: const ValueKey('offline'))
              : const SizedBox.shrink(key: ValueKey('online')),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: const Color(0xFFFF4444),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.white, size: 14),
          SizedBox(width: 8),
          Text(
            'No internet connection',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
