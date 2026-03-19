import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;  // ← FIXED
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';

/// AdMob ad service.
/// All methods are no-ops on web (kIsWeb guard at every entry point).
/// On Android/iOS the normal AdMob flow runs unchanged.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;

  // ── Initialize ────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (kIsWeb) return;          // AdMob does NOT run on web
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    debugPrint('✅ AdMob initialized');
    // Pre-load full-screen ads in background
    await Future.wait([
      loadInterstitial(),
      loadInterstitial2(),
      loadRewarded(),
    ]);
  }

  // ── Ad Unit ID Getters ────────────────────────────────────────────────────
  String get _bannerAdUnit => kIsWeb || !_isPlatformSupported
      ? ''
      : _isAndroid
          ? AppConfig.bannerAdUnitAndroid
          : AppConfig.bannerAdUnitIos;

  String get _interstitialAdUnit => kIsWeb || !_isPlatformSupported
      ? ''
      : _isAndroid
          ? AppConfig.interstitialAdUnitAndroid
          : AppConfig.interstitialAdUnitIos;

  String get _interstitial2AdUnit => kIsWeb || !_isPlatformSupported
      ? ''
      : _isAndroid
          ? AppConfig.interstitial2AdUnitAndroid
          : AppConfig.interstitial2AdUnitIos;

  String get _rewardedAdUnit => kIsWeb || !_isPlatformSupported
      ? ''
      : _isAndroid
          ? AppConfig.rewardedAdUnitAndroid
          : AppConfig.rewardedAdUnitIos;

  String get _nativeAdUnit => kIsWeb || !_isPlatformSupported
      ? ''
      : _isAndroid
          ? AppConfig.nativeAdUnitAndroid
          : AppConfig.nativeAdUnitIos;

  String get _banner2AdUnit => kIsWeb || !_isPlatformSupported
      ? ''
      : _isAndroid
          ? AppConfig.banner2AdUnitAndroid
          : AppConfig.banner2AdUnitIos;

  // Use defaultTargetPlatform (web-safe) instead of dart:io Platform
  bool get _isAndroid =>
      defaultTargetPlatform == TargetPlatform.android;

  bool get _isPlatformSupported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  // ── Interstitial 1 (shown after generation) ───────────────────────────────
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  Future<void> loadInterstitial() async {
    if (kIsWeb || !_isPlatformSupported) return;
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;
    await InterstitialAd.load(
      adUnitId: _interstitialAdUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _interstitialAd = null;
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          debugPrint('Interstitial failed: $error');
        },
      ),
    );
  }

  Future<void> showInterstitial(UserModel? user) async {
    if (kIsWeb || !_isPlatformSupported) return;
    if (user?.isPaid ?? false) return;
    if (_interstitialAd == null) {
      await loadInterstitial();
      return;
    }
    await _interstitialAd!.show();
  }

  // ── Interstitial 2 (when opening saved project) ───────────────────────────
  InterstitialAd? _interstitial2Ad;
  bool _isInterstitial2Loading = false;

  Future<void> loadInterstitial2() async {
    if (kIsWeb || !_isPlatformSupported) return;
    if (_isInterstitial2Loading || _interstitial2Ad != null) return;
    _isInterstitial2Loading = true;
    await InterstitialAd.load(
      adUnitId: _interstitial2AdUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial2Ad = ad;
          _isInterstitial2Loading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitial2Ad = null;
              loadInterstitial2();
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _interstitial2Ad = null;
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitial2Loading = false;
          debugPrint('Interstitial2 failed: $error');
        },
      ),
    );
  }

  Future<void> showProjectViewInterstitial(UserModel? user) async {
    if (kIsWeb || !_isPlatformSupported) return;
    if (user?.isPaid ?? false) return;
    if (_interstitial2Ad == null) {
      await loadInterstitial2();
      return;
    }
    await _interstitial2Ad!.show();
  }

  // ── Rewarded (export gate) ────────────────────────────────────────────────
  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  Future<void> loadRewarded() async {
    if (kIsWeb || !_isPlatformSupported) return;
    if (_isRewardedLoading || _rewardedAd != null) return;
    _isRewardedLoading = true;
    await RewardedAd.load(
      adUnitId: _rewardedAdUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedLoading = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isRewardedLoading = false;
          debugPrint('Rewarded failed: $error');
        },
      ),
    );
  }

  /// Returns true if the user earned the reward (or is on paid plan / web).
  Future<bool> showRewarded(UserModel? user) async {
    if (kIsWeb || !_isPlatformSupported) return true; // web: always allow
    if (user?.isPaid ?? false) return true;
    if (_rewardedAd == null) {
      await loadRewarded();
      return false;
    }
    bool rewarded = false;
    await _rewardedAd!.show(onUserEarnedReward: (_, __) => rewarded = true);
    return rewarded;
  }

  // ── Banner 1 (sticky bottom) ──────────────────────────────────────────────
  BannerAd? createBannerAd() {
    if (kIsWeb || !_isPlatformSupported) return null;
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

  // ── Banner 2 (large — settings screen) ───────────────────────────────────
  BannerAd? createBanner2Ad() {
    if (kIsWeb || !_isPlatformSupported) return null;
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

  // ── Native ────────────────────────────────────────────────────────────────
  NativeAd? createNativeAd({required NativeAdListener listener}) {
    if (kIsWeb || !_isPlatformSupported) return null;
    return NativeAd(
      adUnitId: _nativeAdUnit,
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: listener,
    );
  }

  // ── Dispose ───────────────────────────────────────────────────────────────
  void dispose() {
    _interstitialAd?.dispose();
    _interstitial2Ad?.dispose();
    _rewardedAd?.dispose();
  }
}
