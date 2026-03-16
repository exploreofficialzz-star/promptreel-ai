import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    debugPrint('✅ AdMob initialized');
    await loadInterstitial();
  }

  String get _bannerAdUnit => kIsWeb
      ? ''
      : Platform.isAndroid
          ? AppConfig.bannerAdUnitAndroid
          : AppConfig.bannerAdUnitIos;

  String get _interstitialAdUnit => kIsWeb
      ? ''
      : Platform.isAndroid
          ? AppConfig.interstitialAdUnitAndroid
          : AppConfig.interstitialAdUnitIos;

  String get _rewardedAdUnit => kIsWeb
      ? ''
      : Platform.isAndroid
          ? AppConfig.rewardedAdUnitAndroid
          : AppConfig.rewardedAdUnitIos;

  String get _nativeAdUnit => kIsWeb
      ? ''
      : Platform.isAndroid
          ? AppConfig.nativeAdUnitAndroid
          : AppConfig.nativeAdUnitIos;

  // ── Interstitial ──────────────────────────────────────────────────────────
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

  // ── Rewarded ──────────────────────────────────────────────────────────────
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

  // ── Banner ────────────────────────────────────────────────────────────────
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

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
