import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'services/connectivity_service.dart';
import 'theme/app_theme.dart';
import 'widgets/common/network_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Portrait lock (mobile only) ────────────────────────────────────────
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // ── Status bar / navigation bar styling (mobile only) ─────────────────
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  // ── iOS App Tracking Transparency ─────────────────────────────────────
  // Only runs on iOS physical/simulator. kIsWeb + platform guard keeps it safe.
  // The ATT prompt is triggered via the app_tracking_transparency plugin
  // AFTER the splash screen renders (handled in SplashScreen.initState).
  // We do nothing here to avoid blocking startup.

  runApp(
    const ProviderScope(
      child: PromptReelApp(),
    ),
  );
}

class PromptReelApp extends ConsumerWidget {
  const PromptReelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Initialize connectivity monitoring (reads the provider, starts the stream)
    ref.watch(networkStatusProvider);

    return MaterialApp.router(
      title: 'PromptReel AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
      builder: (context, child) {
        final content = child ?? const SizedBox();
        return MediaQuery(
          // Clamp text scale to prevent layout breaks on accessibility settings
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: NetworkBanner(child: content),
        );
      },
    );
  }
}
