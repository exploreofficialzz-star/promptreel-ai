import 'package:flutter/foundation.dart';
// Only import mobile ads and dart:io on non-web platforms
import '../config/app_config.dart';
import '../models/user_model.dart';

// ── Conditional imports ───────────────────────────────────────────────────────
// These imports only load on mobile — not on web
import 'ad_service_mobile.dart'
    if (dart.library.html) 'ad_service_web.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;

  // ── Initialize ─────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (kIsWeb) return; // ← Skip entirely on web
    if (_initialized) return;
    await initializeAds();
    _initialized = true;
    debugPrint('✅ AdMob initialized');
  }

  // ── Show Interstitial after generation ────────────────────────────────────
  Future<void> showInterstitial(UserModel? user) async {
    if (kIsWeb) return;
    if (user?.isPaid ?? false) return;
    await showInterstitialAd();
  }

  // ── Show Interstitial when opening saved project ──────────────────────────
  Future<void> showProjectViewInterstitial(UserModel? user) async {
    if (kIsWeb) return;
    if (user?.isPaid ?? false) return;
    await showInterstitial2Ad();
  }

  // ── Show Rewarded for export ──────────────────────────────────────────────
  Future<bool> showRewarded(UserModel? user) async {
    if (kIsWeb) return true; // ← Allow export on web freely
    if (user?.isPaid ?? false) return true;
    return showRewardedAd();
  }

  // ── Create Banner 1 ───────────────────────────────────────────────────────
  dynamic createBannerAd() {
    if (kIsWeb) return null;
    return createBanner1();
  }

  // ── Create Banner 2 ───────────────────────────────────────────────────────
  dynamic createBanner2Ad() {
    if (kIsWeb) return null;
    return createBanner2();
  }

  // ── Dispose ───────────────────────────────────────────────────────────────
  void dispose() {
    if (kIsWeb) return;
    disposeAds();
  }
}
