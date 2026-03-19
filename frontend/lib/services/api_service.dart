import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../models/user_model.dart';
import '../models/project_model.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ApiService {
  late final Dio _dio;
  late final Dio _generateDio;

  // ── FIX: Web-safe storage — no AndroidOptions on web ─────────────────────
  final _storage = kIsWeb
      ? const FlutterSecureStorage()
      : const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
            resetOnError: true,
          ),
        );

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: '${AppConfig.baseUrl}${AppConfig.apiPrefix}',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept':       'application/json',
      },
    ));

    _generateDio = Dio(BaseOptions(
      baseUrl: '${AppConfig.baseUrl}${AppConfig.apiPrefix}',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 300),
      sendTimeout:    const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept':       'application/json',
      },
    ));

    _dio.interceptors.add(_buildAuthInterceptor(_dio));
    _generateDio.interceptors.add(_buildAuthInterceptor(_generateDio));
  }

  // ── Auth Interceptor ──────────────────────────────────────────────────────
  InterceptorsWrapper _buildAuthInterceptor(Dio dioInstance) {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await _storage.read(key: AppConfig.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {}
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            try {
              final token = await _storage.read(key: AppConfig.tokenKey);
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              final response = await dioInstance.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            } catch (_) {}
          }
        }
        handler.next(error);
      },
    );
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken =
          await _storage.read(key: AppConfig.refreshTokenKey);
      if (refreshToken == null) return false;
      final response = await Dio().post(
        '${AppConfig.baseUrl}${AppConfig.apiPrefix}/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final data = response.data;
      await _storage.write(
          key: AppConfig.tokenKey, value: data['access_token']);
      await _storage.write(
          key: AppConfig.refreshTokenKey, value: data['refresh_token']);
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
      'email':    email,
      'password': password,
      'name':     name,
    });
    await _saveTokens(res.data);
    return res.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/auth/login', data: {
      'email':    email,
      'password': password,
    });
    await _saveTokens(res.data);
    return res.data;
  }

  Future<void> logout() async {
    try {
      await _storage.delete(key: AppConfig.tokenKey);
      await _storage.delete(key: AppConfig.refreshTokenKey);
      await _storage.delete(key: AppConfig.userKey);
    } catch (_) {}
  }

  Future<UserModel> getMe() async {
    final res = await _dio.get('/auth/me');
    return UserModel.fromJson(res.data);
  }

  Future<void> updateProfile({
    String? name,
    String? currentPassword,
    String? newPassword,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (currentPassword != null) data['password'] = currentPassword;
    if (newPassword != null) data['new_password'] = newPassword;
    await _dio.put('/auth/me', data: data);
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final res = await _dio.get('/auth/notifications');
    return Map<String, dynamic>.from(res.data);
  }

  Future<void> updateNotificationPreferences(
      Map<String, dynamic> prefs) async {
    await _dio.put('/auth/notifications', data: prefs);
  }

  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    await _dio.post('/auth/verify-email', data: {
      'email': email,
      'code':  code,
    });
  }

  Future<void> resendVerification({required String email}) async {
    await _dio.post('/auth/resend-verification',
        data: {'email': email});
  }

  Future<void> forgotPassword({required String email}) async {
    await _dio.post('/auth/forgot-password',
        data: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    await _dio.post('/auth/reset-password', data: {
      'email':    email,
      'code':     code,
      'password': password,
    });
  }

  Future<void> saveFcmToken(String token) async {
    try {
      await _dio.post('/auth/fcm-token',
          data: {'fcm_token': token});
    } catch (_) {}
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    try {
      if (data['access_token'] != null) {
        await _storage.write(
            key: AppConfig.tokenKey, value: data['access_token']);
      }
      if (data['refresh_token'] != null) {
        await _storage.write(
            key: AppConfig.refreshTokenKey,
            value: data['refresh_token']);
      }
    } catch (_) {}
  }

  Future<bool> isLoggedIn() async {
    try {
      final token = await _storage.read(key: AppConfig.tokenKey);
      return token != null;
    } catch (_) {
      return false;
    }
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
    Map<String, String> contentTypeOptions = const {},
  }) async {
    final res = await _generateDio.post('/generate/', data: {
      'idea':                   idea,
      'content_type':           contentType,
      'platform':               platform,
      'duration_minutes':       durationMinutes,
      'generator':              generator,
      'generate_image_prompts': generateImagePrompts,
      'generate_voice_over':    generateVoiceOver,
      'content_type_options':   contentTypeOptions,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getGeneratePreview({
    required int durationMinutes,
    required String generator,
  }) async {
    final res = await _dio.get('/generate/preview', queryParameters: {
      'duration_minutes': durationMinutes,
      'generator':        generator,
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
      'page':  page,
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
    final res = await _generateDio.get<List<int>>(
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

  // ── Payments ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getPlans() async {
    final res = await _dio.get('/payments/plans');
    return res.data;
  }

  Future<Map<String, dynamic>> getPaymentMethods({
    String currency = 'USD',
  }) async {
    final res = await _dio.get('/payments/methods',
        queryParameters: {'currency': currency});
    return res.data;
  }

  Future<Map<String, dynamic>> createCheckout({
    required String planId,
    required String email,
    required String name,
    required String currency,
  }) async {
    final res = await _dio.post('/payments/checkout', data: {
      'plan_id':  planId,
      'email':    email,
      'name':     name,
      'currency': currency,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String txRef,
    required String planId,
    String transactionId = '0',
  }) async {
    final res = await _dio.post('/payments/verify', data: {
      'transaction_id': transactionId,
      'tx_ref':         txRef,
      'plan_id':        planId,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getPaymentPrices() async {
    final res = await _dio.get('/payments/prices');
    return res.data;
  }

  // ── Error Helper ───────────────────────────────────────────────────────────
  static String extractError(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Connection timed out. Please try again.';
      }
      final data = error.response?.data;
      if (data is Map && data['detail'] != null)
        return data['detail'].toString();
      if (data is Map && data['message'] != null)
        return data['message'].toString();
      if (error.response?.statusCode == 402)
        return 'Payment required or verification failed.';
      if (error.response?.statusCode == 429)
        return 'Daily limit reached. Upgrade your plan.';
      if (error.response?.statusCode == 403)
        return 'Upgrade your plan to access this feature.';
      if (error.response?.statusCode == 401)
        return 'Session expired. Please log in again.';
      if (error.response?.statusCode == 503)
        return 'Payment service temporarily unavailable.';
      if (error.response?.statusCode == 500)
        return 'Server error. Please try again.';
      return error.message ?? 'Network error. Please try again.';
    }
    return error.toString();
  }
}
