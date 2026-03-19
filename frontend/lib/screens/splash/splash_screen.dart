import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
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

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Initialize controller for both web and mobile
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..addListener(() {
        if (mounted) {
          setState(() => _progress = _progressController.value);
        }
      });
    
    _init();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    // Start animation
    _progressController.forward();
    
    // Wait for animation + loading
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // Check auth
    try {
      final isLoggedIn = await ref
          .read(apiServiceProvider)
          .isLoggedIn()
          .timeout(const Duration(seconds: 5));
      
      if (!mounted) return;
      context.go(isLoggedIn ? '/home' : '/login');
    } catch (e) {
      debugPrint('Splash auth error: $e');
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Web: FULL ANIMATED SPLASH (not minimal) ───────────────────────────
    if (kIsWeb) {
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.movie_filter_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: 800.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 600.ms),

                const SizedBox(height: 32),

                // App Name with gradient
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: const Text(
                    'PromptReel AI',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                )
                .animate(delay: 300.ms)
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 12),

                // Tagline
                Text(
                  'AI Video Production Platform',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                    letterSpacing: 0.5,
                  ),
                )
                .animate(delay: 500.ms)
                .fadeIn(duration: 600.ms),

                const SizedBox(height: 48),

                // Progress bar (web-sized)
                SizedBox(
                  width: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                )
                .animate(delay: 700.ms)
                .fadeIn(duration: 400.ms),

                const SizedBox(height: 16),

                // Loading text
                Text(
                  _progress < 0.3
                      ? 'Initializing...'
                      : _progress < 0.6
                          ? 'Loading...'
                          : _progress < 0.9
                              ? 'Almost ready...'
                              : 'Welcome! 🎬',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.4),
                  ),
                )
                .animate(delay: 800.ms)
                .fadeIn(duration: 400.ms),

                const SizedBox(height: 48),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Made with ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    const Text('❤️', style: TextStyle(fontSize: 12)),
                    Text(
                      ' by chAs Tech Group',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ],
                )
                .animate(delay: 1000.ms)
                .fadeIn(duration: 600.ms),
              ],
            ),
          ),
        ),
      );
    }

    // ── Mobile: full splash (keep your existing mobile code) ──────────────
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
          child: Stack(
            children: [
              // Background glow
              Positioned(
                top: -100, left: 0, right: 0,
                child: Center(
                  child: Container(
                    width: 400, height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              Column(
                children: [
                  const Spacer(flex: 3),

                  // ── App Icon ─────────────────────────────────────────
                  Container(
                    width: 130, height: 130,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 50, spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.movie_filter_rounded,
                      size: 65, 
                      color: Colors.white,
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

                  // ── App Name ─────────────────────────────────────────
                  ShaderMask(
                    shaderCallback: (b) =>
                        AppColors.primaryGradient.createShader(b),
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
                  .slideY(
                    begin: 0.4, 
                    end: 0,
                    curve: Curves.easeOutCubic,
                  ),

                  const SizedBox(height: 12),

                  // ── Tagline ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
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

                  const SizedBox(height: 24),

                  // ── Version badge ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14, 
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      'v1.0.0 · Powered by 9 AI Providers',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ).animate(delay: 700.ms).fadeIn(duration: 500.ms),

                  const Spacer(flex: 3),

                  // ── Progress bar ──────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 3,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _progress < 0.4
                              ? 'Initializing...'
                              : _progress < 0.7
                                  ? 'Loading AI models...'
                                  : _progress < 0.95
                                      ? 'Almost ready...'
                                      : 'Welcome! 🎬',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.3),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 900.ms).fadeIn(duration: 500.ms),

                  const SizedBox(height: 32),

                  // ── Footer ────────────────────────────────────────────
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
                      const Text('❤️', style: TextStyle(fontSize: 13)),
                      Text(
                        ' by chAs Tech Group',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.3),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ).animate(delay: 1000.ms).fadeIn(duration: 700.ms),

                  const SizedBox(height: 36),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
