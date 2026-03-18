import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;

  // ── Initialize ────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    debugPrint('✅ AdMob initialized');
    // Pre-load all ad types
    await Future.wait([
      loadInterstitial(),
      loadInterstitial2(),
      loadRewarded(),
    ]);
  }

  // ── Ad Unit ID Getters ────────────────────────────────────────────────────
  String get _bannerAdUnit => kIsWeb
      ? '' : Platform.isAndroid
          ? AppConfig.bannerAdUnitAndroid
          : AppConfig.bannerAdUnitIos;

  String get _interstitialAdUnit => kIsWeb
      ? '' : Platform.isAndroid
          ? AppConfig.interstitialAdUnitAndroid
          : AppConfig.interstitialAdUnitIos;

  String get _interstitial2AdUnit => kIsWeb
      ? '' : Platform.isAndroid
          ? AppConfig.interstitial2AdUnitAndroid
          : AppConfig.interstitial2AdUnitIos;

  String get _rewardedAdUnit => kIsWeb
      ? '' : Platform.isAndroid
          ? AppConfig.rewardedAdUnitAndroid
          : AppConfig.rewardedAdUnitIos;

  String get _nativeAdUnit => kIsWeb
      ? '' : Platform.isAndroid
          ? AppConfig.nativeAdUnitAndroid
          : AppConfig.nativeAdUnitIos;

  String get _banner2AdUnit => kIsWeb
      ? '' : Platform.isAndroid
          ? AppConfig.banner2AdUnitAndroid
          : AppConfig.banner2AdUnitIos;

  // ── Interstitial 1 (after generation) ────────────────────────────────────
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  Future<void> loadInterstitial() async {
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
            onAdFailedToShowFullScreenContent: (ad, error) {
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
            onAdFailedToShowFullScreenContent: (ad, error) {
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

  /// Show when free user opens a saved project
  Future<void> showProjectViewInterstitial(UserModel? user) async {
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
            onAdFailedToShowFullScreenContent: (ad, error) {
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

  Future<bool> showRewarded(UserModel? user) async {
    if (user?.isPaid ?? false) return true;
    if (_rewardedAd == null) {
      await loadRewarded();
      return false;
    }
    bool rewarded = false;
    await _rewardedAd!.show(
      onUserEarnedReward: (_, __) => rewarded = true,
    );
    return rewarded;
  }

  // ── Banner 1 (sticky bottom) ──────────────────────────────────────────────
  BannerAd? createBannerAd() {
    if (kIsWeb) return null;
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
    if (kIsWeb) return null;
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
    if (kIsWeb) return null;
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
