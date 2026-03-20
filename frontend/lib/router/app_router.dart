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
import '../models/project_model.dart';

// ✅ FIX: RouterNotifier listens to auth changes without recreating the router
class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  _RouterNotifier(this._ref) {
    // Listen to auth state changes and notify router to re-evaluate redirects
    // WITHOUT recreating the entire GoRouter instance
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

final _routerNotifierProvider = ChangeNotifierProvider(
  (ref) => _RouterNotifier(ref),
);

// ✅ FIX: Use Provider.family or a simple Provider that never recreates
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: notifier, // ← Router re-evaluates redirects on auth change
    redirect: (context, state) {
      final authState   = ref.read(authProvider); // ← read not watch
      final isLoggedIn  = authState.isLoggedIn;
      final isLoading   = authState.isLoading;
      final currentPath = state.matchedLocation;

      // ✅ Never redirect away from splash — it handles its own navigation
      if (currentPath == '/') return null;

      // ✅ Don't redirect while auth is loading
      if (isLoading) return null;

      // ✅ Not logged in — send to login (except if already there)
      if (!isLoggedIn && currentPath != '/login') return '/login';

      // ✅ Logged in — don't show login again
      if (isLoggedIn && currentPath == '/login') return '/home';

      return null;
    },
    routes: [
      // ── Splash ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
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
          final id =
              int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
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
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('404',
                style: TextStyle(
                    fontSize: 64,
                    color: Color(0xFFFFB830))),
            const SizedBox(height: 16),
            Text('Page not found: ${state.matchedLocation}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
