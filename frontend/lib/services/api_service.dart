import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../models/project_model.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: '${AppConfig.baseUrl}${AppConfig.apiPrefix}',
      connectTimeout: const Duration(milliseconds: AppConfig.connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeoutMs),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));

    // Auth interceptor — inject token automatically
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConfig.tokenKey);
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Attempt token refresh
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              // Retry original request
              final token = await _storage.read(key: AppConfig.tokenKey);
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              try {
                final response = await _dio.fetch(error.requestOptions);
                handler.resolve(response);
                return;
              } catch (_) {}
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _storage.read(key: AppConfig.refreshTokenKey);
      if (refreshToken == null) return false;
      final response = await Dio().post(
        '${AppConfig.baseUrl}${AppConfig.apiPrefix}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = response.data;
      await _storage.write(key: AppConfig.tokenKey, value: data['access_token']);
      await _storage.write(key: AppConfig.refreshTokenKey, value: data['refresh_token']);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Auth ───────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
    });
    await _saveTokens(res.data);
    return res.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    await _saveTokens(res.data);
    return res.data;
  }

  Future<void> logout() async {
    await _storage.delete(key: AppConfig.tokenKey);
    await _storage.delete(key: AppConfig.refreshTokenKey);
    await _storage.delete(key: AppConfig.userKey);
  }

  Future<UserModel> getMe() async {
    final res = await _dio.get('/auth/me');
    return UserModel.fromJson(res.data);
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    if (data['access_token'] != null) {
      await _storage.write(key: AppConfig.tokenKey, value: data['access_token']);
    }
    if (data['refresh_token'] != null) {
      await _storage.write(key: AppConfig.refreshTokenKey, value: data['refresh_token']);
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConfig.tokenKey);
    return token != null;
  }

  // ── Generation ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> generateVideoplan({
    required String idea,
    required String contentType,
    required String platform,
    required int durationMinutes,
    required String generator,
    bool generateImagePrompts = false,
    bool generateVoiceOver = false,
  }) async {
    final res = await _dio.post('/generate/', data: {
      'idea': idea,
      'content_type': contentType,
      'platform': platform,
      'duration_minutes': durationMinutes,
      'generator': generator,
      'generate_image_prompts': generateImagePrompts,
      'generate_voice_over': generateVoiceOver,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getGeneratePreview({
    required int durationMinutes,
    required String generator,
  }) async {
    final res = await _dio.get('/generate/preview', queryParameters: {
      'duration_minutes': durationMinutes,
      'generator': generator,
    });
    return res.data;
  }

  // ── Projects ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getProjects({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final res = await _dio.get('/projects/', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null) 'search': search,
      if (status != null) 'status': status,
    });
    return res.data;
  }

  Future<ProjectModel> getProject(int id) async {
    final res = await _dio.get('/projects/$id');
    return ProjectModel.fromJson(res.data);
  }

  Future<void> deleteProject(int id) async {
    await _dio.delete('/projects/$id');
  }

  Future<Map<String, dynamic>> getStats() async {
    final res = await _dio.get('/projects/stats/summary');
    return res.data;
  }

  // ── Export ─────────────────────────────────────────────────────────────────
  Future<List<int>> exportProjectZip(int projectId) async {
    final res = await _dio.get<List<int>>(
      '/export/$projectId/zip',
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? [];
  }

  Future<String> exportProjectScript(int projectId) async {
    final res = await _dio.get<String>(
      '/export/$projectId/script',
      options: Options(responseType: ResponseType.plain),
    );
    return res.data ?? '';
  }

  Future<String> exportProjectSrt(int projectId) async {
    final res = await _dio.get<String>(
      '/export/$projectId/srt',
      options: Options(responseType: ResponseType.plain),
    );
    return res.data ?? '';
  }

  // ── Plans ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getPlans() async {
    final res = await _dio.get('/plans');
    return res.data;
  }

  // ── Payments ───────────────────────────────────────────────────────────────
  /// Verifies a completed Flutterwave transaction server-side and upgrades
  /// the user's plan. Returns the response map on success.
  Future<Map<String, dynamic>> verifyPayment({
    required String transactionId,
    required String txRef,
    required String plan,
  }) async {
    final res = await _dio.post('/payments/verify', data: {
      'transaction_id': transactionId,
      'tx_ref': txRef,
      'plan': plan,
    });
    return res.data;
  }

  /// Returns the current NGN prices from the backend (creator + studio).
  Future<Map<String, dynamic>> getPaymentPrices() async {
    final res = await _dio.get('/payments/prices');
    return res.data;
  }

  // ── Error helper ──────────────────────────────────────────────────────────
  static String extractError(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) return data['detail'].toString();
      if (data is Map && data['message'] != null) return data['message'].toString();
      if (error.response?.statusCode == 429) return 'Daily limit reached. Upgrade your plan.';
      if (error.response?.statusCode == 403) return 'Upgrade your plan to access this feature.';
      if (error.response?.statusCode == 401) return 'Session expired. Please log in again.';
      return error.message ?? 'Network error. Please try again.';
    }
    return error.toString();
  }
}
