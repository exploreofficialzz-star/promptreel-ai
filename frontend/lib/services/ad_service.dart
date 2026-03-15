import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';

/// Central AdMob service — call AdService.instance everywhere.
/// Ads are ONLY shown to free-plan users. Paid users see nothing.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // ── Ad unit IDs (platform-aware) ─────────────────────────────────────────
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
              loadInterstitial(); // Pre-load next
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
    if (user?.isPaid ?? false) return; // Never show to paid users
    if (_interstitialAd == null) {
      await loadInterstitial();
      return;
    }
    await _interstitialAd!.show();
  }

  // ── Rewarded ──────────────────────────────────────────────────────────────
  RewardedAd? _rewardedAd;

  Future<void> loadRewarded() async {
    await RewardedAd.load(
      adUnitId: _rewardedAdUnit,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
            },
          );
        },
        onAdFailedToLoad: (error) => debugPrint('Rewarded failed: $error'),
      ),
    );
  }

  /// Show rewarded ad. Returns true if user earned the reward.
  Future<bool> showRewarded(UserModel? user) async {
    if (user?.isPaid ?? false) return true; // Paid users always get reward
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
    return BannerAd(
      adUnitId: _bannerAdUnit,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner failed: $error');
        },
      ),
    );
  }

  // ── Native ────────────────────────────────────────────────────────────────
  NativeAd? createNativeAd({required NativeAdListener listener}) {
    if (kIsWeb) return null;
    return NativeAd(
      adUnitId: _nativeAdUnit,
      factoryId: 'listTile', // Matches native ad factory registered in MainActivity
      request: const AdRequest(),
      listener: listener,
    );
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
