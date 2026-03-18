import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/ad_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Initialize AdMob in background while splash shows
    AdService.instance.initialize();

    // Minimum splash duration
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;

    // Check auth and navigate
    final isLoggedIn =
        await ref.read(apiServiceProvider).isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D0D1A),
              Color(0xFF0A0A0F),
              Color(0xFF0D0D1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ── App Icon ──────────────────────────────────────────────────
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9B59B6).withOpacity(0.5),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                    BoxShadow(
                      color: const Color(0xFF3498DB).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      // Fallback if image not found
                      return Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF9B59B6),
                              Color(0xFF3498DB),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.movie_filter_rounded,
                          size: 65,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.3, 0.3),
                    end: const Offset(1.0, 1.0),
                    duration: 800.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 500.ms),

              const SizedBox(height: 32),

              // ── App Name ──────────────────────────────────────────────────
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Text(
                  'PromptReel AI',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              )
                  .animate(delay: 400.ms)
                  .fadeIn(duration: 700.ms)
                  .slideY(begin: 0.4, end: 0,
                      curve: Curves.easeOutCubic),

              const SizedBox(height: 12),

              // ── Tagline ───────────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Turn simple ideas into complete\nAI video production plans.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.55),
                    height: 1.6,
                    letterSpacing: 0.3,
                  ),
                ),
              )
                  .animate(delay: 600.ms)
                  .fadeIn(duration: 700.ms)
                  .slideY(begin: 0.3, end: 0),

              const Spacer(flex: 3),

              // ── Loading Bar ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 80),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    backgroundColor:
                        Colors.white.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ).animate(delay: 900.ms).fadeIn(duration: 500.ms),

              const SizedBox(height: 28),

              // ── Footer ────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Made with ',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.3),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Text(
                    '❤️',
                    style: TextStyle(fontSize: 13),
                  ),
                  Text(
                    ' by chAs Tech Group',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.3),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              )
                  .animate(delay: 1000.ms)
                  .fadeIn(duration: 700.ms),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}
