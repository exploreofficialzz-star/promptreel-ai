import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/create/create_screen.dart';
import '../screens/results/results_screen.dart';
import '../screens/projects/projects_screen.dart';
import '../screens/tools/tools_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/plans_screen.dart';
import '../screens/settings/ai_models_screen.dart';
import '../models/project_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final isLoading = authState.isLoading;
      final isAuthRoute = state.matchedLocation == '/login';

      if (isLoading) return null;
      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
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
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
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
            const Text('404', style: TextStyle(fontSize: 64, color: Color(0xFFFFB830))),
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
