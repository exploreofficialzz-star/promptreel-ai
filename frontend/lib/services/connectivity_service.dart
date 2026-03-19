import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Connectivity State ────────────────────────────────────────────────────────
enum NetworkStatus { online, offline, unknown }

// ── Provider ──────────────────────────────────────────────────────────────────
final networkStatusProvider =
    StateNotifierProvider<NetworkStatusNotifier, NetworkStatus>(
  (ref) => NetworkStatusNotifier(),
);

class NetworkStatusNotifier extends StateNotifier<NetworkStatus> {
  StreamSubscription<List<ConnectivityResult>>? _sub;

  NetworkStatusNotifier() : super(NetworkStatus.unknown) {
    _init();
  }

  Future<void> _init() async {
    // On web, we assume online unless proven otherwise
    if (kIsWeb) {
      state = NetworkStatus.online;
      return;
    }

    // Check current status immediately
    final result = await Connectivity().checkConnectivity();
    state = _fromResult(result);

    // Then listen for changes
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      state = _fromResult(results);
    });
  }

  NetworkStatus _fromResult(List<ConnectivityResult> results) {
    if (results.isEmpty) return NetworkStatus.offline;
    if (results.contains(ConnectivityResult.none)) return NetworkStatus.offline;
    return NetworkStatus.online;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
