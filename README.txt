# PromptReel AI — Web Fix Package

## Files in this ZIP and where to put them:

### frontend/lib/theme/
- app_theme.dart  → fixes CardThemeData, TabBarThemeData, DialogThemeData

### frontend/lib/services/
- ad_service.dart         → web-safe with all methods (loadInterstitial, loadRewarded etc)
- ad_service_mobile.dart  → mobile AdMob implementation
- ad_service_web.dart     → web stubs (no-ops)

### frontend/lib/widgets/ads/
- banner_ad_widget.dart   → web-safe banner widgets
- banner_ad_mobile.dart   → mobile AdWidget helper
- banner_ad_web.dart      → web stub
- native_ad_card.dart     → web-safe native ad
- native_ad_mobile.dart   → mobile native ad helper
- native_ad_web.dart      → web stub
- rewarded_export_gate.dart → web-safe (free export on web)

### frontend/web/
- index.html    → fixes deprecated loadEntrypoint warning
- manifest.json → PWA manifest

### frontend/
- netlify.toml  → Netlify build config

## Errors Fixed:
1. CardTheme      → CardThemeData   (app_theme.dart line 271)
2. TabBarTheme    → TabBarThemeData (app_theme.dart line 367)
3. DialogTheme    → DialogThemeData (app_theme.dart line 374)
4. loadInterstitial() missing on AdService → added
5. loadRewarded()   missing on AdService → added
6. createNativeAd() missing on AdService → added
7. google_mobile_ads dart:io on web → conditional imports fix
8. Deprecated loadEntrypoint → replaced with load()

## After pushing to GitHub:
Netlify will auto-redeploy and build will succeed!
