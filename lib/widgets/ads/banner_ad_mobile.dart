// banner_ad_mobile.dart — only compiled on Android/iOS
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Widget buildAdWidget(dynamic ad) => AdWidget(ad: ad as BannerAd);
