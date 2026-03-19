import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../models/user_model.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart'
    if (dart.library.html) 'ad_stub.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();
  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb) return;
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    debugPrint('✅ AdMob initialized');
  }

  Future<void> loadInterstitial() async {}
  Future<void> loadInterstitial2() async {}
  Future<void> loadRewarded() async {}
  Future<void> showInterstitial(UserModel? user) async {
    if (kIsWeb || (user?.isPaid ?? false)) return;
  }
  Future<void> showProjectViewInterstitial(UserModel? user) async {
    if (kIsWeb || (user?.isPaid ?? false)) return;
  }
  Future<bool> showRewarded(UserModel? user) async {
    if (kIsWeb || (user?.isPaid ?? false)) return true;
    return false;
  }
  dynamic createBannerAd() => null;
  dynamic createBanner2Ad() => null;
  dynamic createNativeAd({required dynamic listener}) => null;
  dynamic createNativeAdMobile({required dynamic listener}) => null;
  void dispose() {}
}
