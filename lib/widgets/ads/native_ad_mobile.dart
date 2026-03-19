// native_ad_mobile.dart — Android/iOS only
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

dynamic buildNativeListener({
  required VoidCallback onLoaded,
  required void Function(dynamic ad) onFailed,
}) {
  return NativeAdListener(
    onAdLoaded: (_) => onLoaded(),
    onAdFailedToLoad: (ad, error) => onFailed(ad),
  );
}

Widget buildNativeAdWidget(dynamic ad) => AdWidget(ad: ad as NativeAd);
