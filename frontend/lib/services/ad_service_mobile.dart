// ad_service_mobile.dart
// Only compiled on Android/iOS — never on web
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/app_config.dart';

// ── Ad Unit IDs ───────────────────────────────────────────────────────────────
String get _bannerAdUnit => Platform.isAndroid
    ? AppConfig.bannerAdUnitAndroid
    : AppConfig.bannerAdUnitIos;

String get _interstitialAdUnit => Platform.isAndroid
    ? AppConfig.interstitialAdUnitAndroid
    : AppConfig.interstitialAdUnitIos;

String get _interstitial2AdUnit => Platform.isAndroid
    ? AppConfig.interstitial2AdUnitAndroid
    : AppConfig.interstitial2AdUnitIos;

String get _rewardedAdUnit => Platform.isAndroid
    ? AppConfig.rewardedAdUnitAndroid
    : AppConfig.rewardedAdUnitIos;

String get _banner2AdUnit => Platform.isAndroid
    ? AppConfig.banner2AdUnitAndroid
    : AppConfig.banner2AdUnitIos;

// ── Ad instances ──────────────────────────────────────────────────────────────
InterstitialAd? _interstitialAd;
InterstitialAd? _interstitial2Ad;
RewardedAd?     _rewardedAd;

bool _interstitialLoading  = false;
bool _interstitial2Loading = false;
bool _rewardedLoading      = false;

// ── Initialize ────────────────────────────────────────────────────────────────
Future<void> initializeAds() async {
  await MobileAds.instance.initialize();
  await Future.wait([
    _loadInterstitial(),
    _loadInterstitial2(),
    _loadRewarded(),
  ]);
}

// ── Interstitial 1 ────────────────────────────────────────────────────────────
Future<void> _loadInterstitial() async {
  if (_interstitialLoading || _interstitialAd != null) return;
  _interstitialLoading = true;
  await InterstitialAd.load(
    adUnitId: _interstitialAdUnit,
    request: const AdRequest(),
    adLoadCallback: InterstitialAdLoadCallback(
      onAdLoaded: (ad) {
        _interstitialAd    = ad;
        _interstitialLoading = false;
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _interstitialAd = null;
            _loadInterstitial();
          },
          onAdFailedToShowFullScreenContent: (ad, _) {
            ad.dispose();
            _interstitialAd = null;
          },
        );
      },
      onAdFailedToLoad: (error) {
        _interstitialLoading = false;
        debugPrint('Interstitial failed: $error');
      },
    ),
  );
}

Future<void> showInterstitialAd() async {
  if (_interstitialAd == null) {
    await _loadInterstitial();
    return;
  }
  await _interstitialAd!.show();
}

// ── Interstitial 2 ────────────────────────────────────────────────────────────
Future<void> _loadInterstitial2() async {
  if (_interstitial2Loading || _interstitial2Ad != null) return;
  _interstitial2Loading = true;
  await InterstitialAd.load(
    adUnitId: _interstitial2AdUnit,
    request: const AdRequest(),
    adLoadCallback: InterstitialAdLoadCallback(
      onAdLoaded: (ad) {
        _interstitial2Ad    = ad;
        _interstitial2Loading = false;
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _interstitial2Ad = null;
            _loadInterstitial2();
          },
          onAdFailedToShowFullScreenContent: (ad, _) {
            ad.dispose();
            _interstitial2Ad = null;
          },
        );
      },
      onAdFailedToLoad: (error) {
        _interstitial2Loading = false;
        debugPrint('Interstitial2 failed: $error');
      },
    ),
  );
}

Future<void> showInterstitial2Ad() async {
  if (_interstitial2Ad == null) {
    await _loadInterstitial2();
    return;
  }
  await _interstitial2Ad!.show();
}

// ── Rewarded ──────────────────────────────────────────────────────────────────
Future<void> _loadRewarded() async {
  if (_rewardedLoading || _rewardedAd != null) return;
  _rewardedLoading = true;
  await RewardedAd.load(
    adUnitId: _rewardedAdUnit,
    request: const AdRequest(),
    rewardedAdLoadCallback: RewardedAdLoadCallback(
      onAdLoaded: (ad) {
        _rewardedAd     = ad;
        _rewardedLoading = false;
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _rewardedAd = null;
          },
          onAdFailedToShowFullScreenContent: (ad, _) {
            ad.dispose();
            _rewardedAd = null;
            _rewardedLoading = false;
          },
        );
      },
      onAdFailedToLoad: (error) {
        _rewardedLoading = false;
        debugPrint('Rewarded failed: $error');
      },
    ),
  );
}

Future<bool> showRewardedAd() async {
  if (_rewardedAd == null) {
    await _loadRewarded();
    return false;
  }
  bool rewarded = false;
  await _rewardedAd!.show(
    onUserEarnedReward: (_, __) => rewarded = true,
  );
  return rewarded;
}

// ── Banners ───────────────────────────────────────────────────────────────────
BannerAd createBanner1() {
  final banner = BannerAd(
    adUnitId: _bannerAdUnit,
    size: AdSize.banner,
    request: const AdRequest(),
    listener: BannerAdListener(
      onAdLoaded: (_) => debugPrint('✅ Banner loaded'),
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
        debugPrint('Banner failed: $error');
      },
    ),
  );
  banner.load();
  return banner;
}

BannerAd createBanner2() {
  final banner = BannerAd(
    adUnitId: _banner2AdUnit,
    size: AdSize.largeBanner,
    request: const AdRequest(),
    listener: BannerAdListener(
      onAdLoaded: (_) => debugPrint('✅ Banner2 loaded'),
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
        debugPrint('Banner2 failed: $error');
      },
    ),
  );
  banner.load();
  return banner;
}

// ── Dispose ───────────────────────────────────────────────────────────────────
void disposeAds() {
  _interstitialAd?.dispose();
  _interstitial2Ad?.dispose();
  _rewardedAd?.dispose();
}

