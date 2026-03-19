// ad_service_mobile.dart — compiled ONLY on Android/iOS
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/app_config.dart';

String get _bannerAdUnit => Platform.isAndroid
    ? AppConfig.bannerAdUnitAndroid : AppConfig.bannerAdUnitIos;
String get _interstitialAdUnit => Platform.isAndroid
    ? AppConfig.interstitialAdUnitAndroid : AppConfig.interstitialAdUnitIos;
String get _interstitial2AdUnit => Platform.isAndroid
    ? AppConfig.interstitial2AdUnitAndroid : AppConfig.interstitial2AdUnitIos;
String get _rewardedAdUnit => Platform.isAndroid
    ? AppConfig.rewardedAdUnitAndroid : AppConfig.rewardedAdUnitIos;
String get _banner2AdUnit => Platform.isAndroid
    ? AppConfig.banner2AdUnitAndroid : AppConfig.banner2AdUnitIos;

InterstitialAd? _interstitialAd;
InterstitialAd? _interstitial2Ad;
RewardedAd?     _rewardedAd;
bool _iLoading = false, _i2Loading = false, _rLoading = false;

Future<void> initializeAds() async {
  await MobileAds.instance.initialize();
  await Future.wait([
    preloadInterstitial(), preloadInterstitial2(), preloadRewarded(),
  ]);
}

Future<void> preloadInterstitial() async {
  if (_iLoading || _interstitialAd != null) return;
  _iLoading = true;
  await InterstitialAd.load(
    adUnitId: _interstitialAdUnit,
    request: const AdRequest(),
    adLoadCallback: InterstitialAdLoadCallback(
      onAdLoaded: (ad) {
        _interstitialAd = ad; _iLoading = false;
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose(); _interstitialAd = null; preloadInterstitial();
          },
          onAdFailedToShowFullScreenContent: (ad, _) {
            ad.dispose(); _interstitialAd = null;
          },
        );
      },
      onAdFailedToLoad: (e) { _iLoading = false; debugPrint('Int failed: $e'); },
    ),
  );
}

Future<void> showInterstitialAd() async {
  if (_interstitialAd == null) { await preloadInterstitial(); return; }
  await _interstitialAd!.show();
}

Future<void> preloadInterstitial2() async {
  if (_i2Loading || _interstitial2Ad != null) return;
  _i2Loading = true;
  await InterstitialAd.load(
    adUnitId: _interstitial2AdUnit,
    request: const AdRequest(),
    adLoadCallback: InterstitialAdLoadCallback(
      onAdLoaded: (ad) {
        _interstitial2Ad = ad; _i2Loading = false;
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose(); _interstitial2Ad = null; preloadInterstitial2();
          },
          onAdFailedToShowFullScreenContent: (ad, _) {
            ad.dispose(); _interstitial2Ad = null;
          },
        );
      },
      onAdFailedToLoad: (e) { _i2Loading = false; debugPrint('Int2 failed: $e'); },
    ),
  );
}

Future<void> showInterstitial2Ad() async {
  if (_interstitial2Ad == null) { await preloadInterstitial2(); return; }
  await _interstitial2Ad!.show();
}

Future<void> preloadRewarded() async {
  if (_rLoading || _rewardedAd != null) return;
  _rLoading = true;
  await RewardedAd.load(
    adUnitId: _rewardedAdUnit,
    request: const AdRequest(),
    rewardedAdLoadCallback: RewardedAdLoadCallback(
      onAdLoaded: (ad) {
        _rewardedAd = ad; _rLoading = false;
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) { ad.dispose(); _rewardedAd = null; },
          onAdFailedToShowFullScreenContent: (ad, _) {
            ad.dispose(); _rewardedAd = null; _rLoading = false;
          },
        );
      },
      onAdFailedToLoad: (e) { _rLoading = false; debugPrint('Rewarded failed: $e'); },
    ),
  );
}

Future<bool> showRewardedAd() async {
  if (_rewardedAd == null) { await preloadRewarded(); return false; }
  bool rewarded = false;
  await _rewardedAd!.show(onUserEarnedReward: (_, __) => rewarded = true);
  return rewarded;
}

BannerAd createBanner1() {
  final b = BannerAd(
    adUnitId: _bannerAdUnit, size: AdSize.banner, request: const AdRequest(),
    listener: BannerAdListener(
      onAdLoaded: (_) => debugPrint('✅ Banner loaded'),
      onAdFailedToLoad: (ad, e) { ad.dispose(); },
    ),
  )..load();
  return b;
}

BannerAd createBanner2() {
  final b = BannerAd(
    adUnitId: _banner2AdUnit, size: AdSize.largeBanner, request: const AdRequest(),
    listener: BannerAdListener(
      onAdLoaded: (_) => debugPrint('✅ Banner2 loaded'),
      onAdFailedToLoad: (ad, e) { ad.dispose(); },
    ),
  )..load();
  return b;
}

dynamic createNativeAdMobile({required dynamic listener}) {
  return NativeAd(
    adUnitId: Platform.isAndroid
        ? AppConfig.nativeAdUnitAndroid
        : AppConfig.nativeAdUnitIos,
    factoryId: 'listTile',
    request: const AdRequest(),
    listener: listener as NativeAdListener,
  );
}

void disposeAds() {
  _interstitialAd?.dispose();
  _interstitial2Ad?.dispose();
  _rewardedAd?.dispose();
}
