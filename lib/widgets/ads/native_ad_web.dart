// native_ad_web.dart — web only stub
import 'package:flutter/widgets.dart';

dynamic buildNativeListener({
  required VoidCallback onLoaded,
  required void Function(dynamic ad) onFailed,
}) => null;

Widget buildNativeAdWidget(dynamic ad) => const SizedBox.shrink();
