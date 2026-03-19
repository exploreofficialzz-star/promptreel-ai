import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

// ── Auth State ────────────────────────────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final bool isLoggedIn;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isLoggedIn = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isLoggedIn,
    String? error,
  }) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        error: error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;

  AuthNotifier(this._api) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final loggedIn = await _api.isLoggedIn();
      if (loggedIn) {
        // ── FIX: On web, skip getMe() on startup to avoid CORS error ─────
        // getMe() will be called after user navigates to /home
        if (kIsWeb) {
          state = state.copyWith(
              isLoggedIn: true, isLoading: false);
        } else {
          final user = await _api.getMe();
          state = state.copyWith(
              isLoggedIn: true, user: user, isLoading: false);
        }
      } else {
        state = state.copyWith(isLoggedIn: false, isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoggedIn: false, isLoading: false);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.register(
          email: email, password: password, name: name);
      final user = UserModel.fromJson(data['user']);
      state = state.copyWith(
          isLoggedIn: true, user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: ApiService.extractError(e));
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data =
          await _api.login(email: email, password: password);
      final user = UserModel.fromJson(data['user']);
      state = state.copyWith(
          isLoggedIn: true, user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: ApiService.extractError(e));
      return false;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    state = const AuthState();
  }

  Future<void> refreshUser() async {
    try {
      final user = await _api.getMe();
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  // ── FIX: clearError method ────────────────────────────────────────────────
  void clearError() => state = state.copyWith(error: null);
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiServiceProvider));
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});
