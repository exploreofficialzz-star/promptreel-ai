import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/user_model.dart';

import 'ad_service_mobile.dart'
    if (dart.library.html) 'ad_service_web.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();
  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb) return;
    if (_initialized) return;
    await initializeAds();
    _initialized = true;
    debugPrint('✅ AdMob initialized');
  }

  Future<void> loadInterstitial() async {
    if (kIsWeb) return;
    await preloadInterstitial();
  }

  Future<void> loadInterstitial2() async {
    if (kIsWeb) return;
    await preloadInterstitial2();
  }

  Future<void> loadRewarded() async {
    if (kIsWeb) return;
    await preloadRewarded();
  }

  Future<void> showInterstitial(UserModel? user) async {
    if (kIsWeb) return;
    if (user?.isPaid ?? false) return;
    await showInterstitialAd();
  }

  Future<void> showProjectViewInterstitial(UserModel? user) async {
    if (kIsWeb) return;
    if (user?.isPaid ?? false) return;
    await showInterstitial2Ad();
  }

  Future<bool> showRewarded(UserModel? user) async {
    if (kIsWeb) return true;
    if (user?.isPaid ?? false) return true;
    return showRewardedAd();
  }

  dynamic createBannerAd() {
    if (kIsWeb) return null;
    return createBanner1();
  }

  dynamic createBanner2Ad() {
    if (kIsWeb) return null;
    return createBanner2();
  }

  dynamic createNativeAd({required dynamic listener}) {
    if (kIsWeb) return null;
    return createNativeAdMobile(listener: listener);
  }

  void dispose() {
    if (kIsWeb) return;
    disposeAds();
  }
}
