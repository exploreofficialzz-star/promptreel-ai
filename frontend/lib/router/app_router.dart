import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/create/create_screen.dart';
import '../screens/results/results_screen.dart';
import '../screens/projects/projects_screen.dart';
import '../screens/tools/tools_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/plans_screen.dart';
import '../screens/settings/ai_models_screen.dart';
import '../screens/landing/landing_screen.dart';
import '../screens/legal/legal_screens.dart';
import '../models/project_model.dart';

// ── Public paths — no auth redirect ───────────────────────────────────────────
const _publicPaths = {
  '/', '/splash', '/landing',
  '/login', '/register',
  '/privacy', '/terms',
};

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    // ── Web starts at landing, mobile starts at splash ──────────────────────
    initialLocation: kIsWeb ? '/' : '/splash',
    debugLogDiagnostics: false,

    redirect: (context, state) {
      final isLoggedIn  = authState.isLoggedIn;
      final isLoading   = authState.isLoading;
      final currentPath = state.matchedLocation;

      // Never redirect public pages
      if (_publicPaths.contains(currentPath)) return null;

      // Wait for auth to load
      if (isLoading) return null;

      // Not logged in → go to login
      if (!isLoggedIn) return '/login';

      // Already logged in → skip login
      if (isLoggedIn && currentPath == '/login') return '/home';

      return null;
    },

    routes: [

      // ── Landing page — website home & mobile splash handler ───────────────
      GoRoute(
        path: '/',
        name: 'root',
        // Web → shows landing page
        // Mobile → immediately redirects to /splash via SplashScreen's kIsWeb check
        builder: (_, __) => kIsWeb
            ? const LandingScreen()
            : const SplashScreen(),
      ),

      // ── Landing (explicit route for web nav) ──────────────────────────────
      GoRoute(
        path: '/landing',
        name: 'landing',
        builder: (_, __) => const LandingScreen(),
      ),

      // ── Splash (mobile app entry) ─────────────────────────────────────────
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),

      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),

      // ── Legal pages (Play Store + website) ───────────────────────────────
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (_, __) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/terms',
        name: 'terms',
        builder: (_, __) => const TermsScreen(),
      ),

      // ── App screens ───────────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/create',
        name: 'create',
        builder: (context, state) {
          final idea = state.extra as String?;
          return CreateScreen(initialIdea: idea);
        },
      ),
      GoRoute(
        path: '/results/:id',
        name: 'results',
        builder: (context, state) {
          final id      = int.tryParse(
              state.pathParameters['id'] ?? '0') ?? 0;
          final project = state.extra as ProjectModel?;
          return ResultsScreen(projectId: id, project: project);
        },
      ),
      GoRoute(
        path: '/projects',
        name: 'projects',
        builder: (_, __) => const ProjectsScreen(),
      ),
      GoRoute(
        path: '/tools',
        name: 'tools',
        builder: (_, __) => const ToolsScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (_, __) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'plans',
            name: 'plans',
            builder: (_, __) => const PlansScreen(),
          ),
          GoRoute(
            path: 'ai-models',
            name: 'ai-models',
            builder: (_, __) => const AiModelsScreen(),
          ),
        ],
      ),
    ],

    // ── 404 Error ─────────────────────────────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('404',
                style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFB830))),
            const SizedBox(height: 12),
            Text(
              'Page not found',
              style: TextStyle(
                  fontSize: 18, color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withOpacity(0.3)),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB830),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                shape: const StadiumBorder(),
              ),
              onPressed: () => context.go('/'),
              child: const Text('Go Home',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    ),
  );
});
