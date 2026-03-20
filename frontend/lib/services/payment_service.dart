import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../config/app_config.dart';

/// Payment result status
enum PaymentStatus {
  success,
  cancelled,
  pending,
  error,
  verified,
}

/// Cross-platform Flutterwave payment service with auto-renewal support.
/// - Web     → opens checkout in popup with postMessage communication
/// - Mobile  → opens checkout in in-app WebView with JavaScript channels
class FlutterwavePaymentService {
  /// Start payment process
  /// Returns PaymentResult with status and transaction details
  static Future<PaymentResult> startPayment({
    required BuildContext context,
    required String email,
    required String name,
    required String planId,
    String? txRef,
    String currency = 'USD',
    VoidCallback? onSuccess,
    VoidCallback? onCancel,
  }) async {
    // Validate plan
    if (planId != 'creator' && planId != 'studio') {
      throw ArgumentError('Invalid plan. Must be "creator" or "studio"');
    }

    // Generate txRef if not provided
    final String finalTxRef = txRef ?? _generateTxRef(planId);

    try {
      PaymentResult result;

      if (kIsWeb) {
        result = await _startWebPayment(
          email: email,
          name: name,
          planId: planId,
          txRef: finalTxRef,
          currency: currency,
        );
      } else {
        result = await _startMobilePayment(
          context: context,
          email: email,
          name: name,
          planId: planId,
          txRef: finalTxRef,
          currency: currency,
        );
      }

      // Handle callbacks
      if (result.status == PaymentStatus.success && onSuccess != null) {
        onSuccess();
      } else if (result.status == PaymentStatus.cancelled && onCancel != null) {
        onCancel();
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('Payment error: $e\n$stackTrace');
      return PaymentResult(
        status: PaymentStatus.error,
        txRef: finalTxRef,
        message: e.toString(),
      );
    }
  }

  /// Generate unique transaction reference
  static String _generateTxRef(String planId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (1000 + DateTime.now().microsecond % 9000);
    return 'PR-$planId-$timestamp-$random';
  }

  // ─── WEB IMPLEMENTATION ────────────────────────────────────────────────────
  static Future<PaymentResult> _startWebPayment({
    required String email,
    required String name,
    required String planId,
    required String txRef,
    required String currency,
  }) async {
    final checkoutUrl = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/payments/checkout-page',
    ).replace(queryParameters: {
      'plan_id': planId,
      'email': email,
      'name': name,
      'tx_ref': txRef,
      'currency': currency,
      'platform': 'web',
    });

    debugPrint('🌐 Web Payment URL: $checkoutUrl');

    // For web, open in new tab and return pending
    if (await canLaunchUrl(checkoutUrl)) {
      await launchUrl(
        checkoutUrl,
        mode: LaunchMode.externalApplication,
      );
      return PaymentResult(
        status: PaymentStatus.pending,
        txRef: txRef,
        message: 'Payment opened in new tab. Please complete and return.',
      );
    }

    throw Exception('Could not launch payment URL');
  }

  // ─── MOBILE IMPLEMENTATION ────────────────────────────────────────────────
  static Future<PaymentResult> _startMobilePayment({
    required BuildContext context,
    required String email,
    required String name,
    required String planId,
    required String txRef,
    required String currency,
  }) async {
    final result = await Navigator.of(context).push<PaymentResult>(
      MaterialPageRoute(
        builder: (_) => MobilePaymentScreen(
          email: email,
          name: name,
          planId: planId,
          txRef: txRef,
          currency: currency,
        ),
        fullscreenDialog: true,
      ),
    );

    return result ?? PaymentResult(
      status: PaymentStatus.cancelled,
      txRef: txRef,
      message: 'Payment cancelled by user',
    );
  }

  /// Verify payment with backend
  static Future<PaymentVerificationResult> verifyPayment({
    required String txRef,
    String? transactionId,
    required String planId,
  }) async {
    try {
      // Get auth token from your auth provider/storage
      final token = await _getAuthToken();
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/payments/verify'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'tx_ref': txRef,
          'transaction_id': transactionId ?? '0',
          'plan_id': planId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PaymentVerificationResult(
          success: true,
          plan: data['plan'],
          subscription: data['subscription'],
          message: data['message'],
        );
      } else {
        final error = jsonDecode(response.body);
        return PaymentVerificationResult(
          success: false,
          message: error['detail'] ?? 'Verification failed',
        );
      }
    } catch (e) {
      return PaymentVerificationResult(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Cancel auto-renewal subscription
  static Future<bool> cancelSubscription() async {
    try {
      final token = await _getAuthToken();
      
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/api/payments/subscription/cancel'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Cancel subscription error: $e');
      return false;
    }
  }

  /// Get current subscription status
  static Future<SubscriptionStatus?> getSubscriptionStatus() async {
    try {
      final token = await _getAuthToken();
      
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/api/payments/subscription/status'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SubscriptionStatus.fromJson(data['subscription']);
      }
      return null;
    } catch (e) {
      debugPrint('Get subscription status error: $e');
      return null;
    }
  }

  // Helper to get auth token - implement based on your auth system
  static Future<String?> _getAuthToken() async {
    // Replace with your actual token retrieval logic
    // Example: return await SecureStorage.read('auth_token');
    // Or: return await AuthService.getToken();
    return null;
  }
}

// ─── MOBILE PAYMENT SCREEN ────────────────────────────────────────────────────
class MobilePaymentScreen extends StatefulWidget {
  final String email;
  final String name;
  final String planId;
  final String txRef;
  final String currency;

  const MobilePaymentScreen({
    super.key,
    required this.email,
    required this.name,
    required this.planId,
    required this.txRef,
    required this.currency,
  });

  @override
  State<MobilePaymentScreen> createState() => _MobilePaymentScreenState();
}

class _MobilePaymentScreenState extends State<MobilePaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    // Platform-specific params
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0A0F))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() => _progress = progress);
          },
          onPageStarted: (String url) {
            debugPrint('🔄 Page started loading: $url');
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            debugPrint('✅ Page finished loading: $url');
            setState(() => _isLoading = false);
            _injectJavaScriptBridge();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('❌ WebView error: ${error.description} (Code: ${error.errorCode})');
            if (error.errorCode != -3) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = error.description;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            debugPrint('🔗 Navigation request: $url');

            if (_isSuccessUrl(url)) {
              _handleSuccess(url);
              return NavigationDecision.prevent;
            }

            if (_isCancelUrl(url)) {
              _handleCancellation();
              return NavigationDecision.prevent;
            }

            if (url.startsWith('promptreel://')) {
              _handleDeepLink(url);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );

    _addJavaScriptChannels(controller);

    final checkoutUrl = _buildCheckoutUrl();
    controller.loadRequest(checkoutUrl);

    _controller = controller;
  }

  Uri _buildCheckoutUrl() {
    return Uri.parse(
      '${AppConfig.apiBaseUrl}/api/payments/checkout-page',
    ).replace(queryParameters: {
      'plan_id': widget.planId,
      'email': widget.email,
      'name': widget.name,
      'tx_ref': widget.txRef,
      'currency': widget.currency,
      'platform': Platform.isIOS ? 'ios' : 'android',
    });
  }

  void _addJavaScriptChannels(WebViewController controller) {
    controller.addJavaScriptChannel(
      'PromptReelAndroid',
      onMessageReceived: (JavaScriptMessage message) {
        debugPrint('📱 Android JS Message: ${message.message}');
        _handleJavaScriptMessage(message.message);
      },
    );

    controller.addJavaScriptChannel(
      'PromptReel',
      onMessageReceived: (JavaScriptMessage message) {
        debugPrint('🍎 iOS JS Message: ${message.message}');
        _handleJavaScriptMessage(message.message);
      },
    );
  }

  void _handleJavaScriptMessage(String message) {
    try {
      final data = jsonDecode(message);
      final status = data['status'];
      
      if (status == 'successful' || status == 'success') {
        _handleSuccessWithData(data);
      } else if (status == 'cancelled' || status == 'cancel') {
        _handleCancellation();
      }
    } catch (e) {
      debugPrint('Error parsing JS message: $e');
    }
  }

  void _injectJavaScriptBridge() {
    const script = '''
      (function() {
        if (window.FlutterwaveCheckout) {
          const originalCheckout = window.FlutterwaveCheckout;
          window.FlutterwaveCheckout = function(config) {
            const originalOnClose = config.onclose;
            const originalCallback = config.callback;
            
            config.callback = function(data) {
              const message = JSON.stringify({
                status: data.status,
                transaction_id: data.transaction_id,
                tx_ref: data.tx_ref
              });
              
              if (window.PromptReelAndroid) {
                window.PromptReelAndroid.postMessage(message);
              } else if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.PromptReel) {
                window.webkit.messageHandlers.PromptReel.postMessage(message);
              }
              
              if (originalCallback) originalCallback(data);
            };
            
            config.onclose = function() {
              const message = JSON.stringify({status: 'cancelled'});
              
              if (window.PromptReelAndroid) {
                window.PromptReelAndroid.postMessage(message);
              } else if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.PromptReel) {
                window.webkit.messageHandlers.PromptReel.postMessage(message);
              }
              
              if (originalOnClose) originalOnClose();
            };
            
            return originalCheckout(config);
          };
        }
        
        window.addEventListener('message', function(event) {
          if (event.data && event.data.type === 'PAYMENT_SUCCESS') {
            const message = JSON.stringify(event.data.data);
            if (window.PromptReelAndroid) {
              window.PromptReelAndroid.postMessage(message);
            } else if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.PromptReel) {
              window.webkit.messageHandlers.PromptReel.postMessage(message);
            }
          }
        });
      })();
    ''';
    
    _controller.runJavaScript(script);
  }

  bool _isSuccessUrl(String url) {
    return url.contains('status=successful') ||
           url.contains('status=success') ||
           (url.contains('/api/payments/callback') && url.contains('transaction_id='));
  }

  bool _isCancelUrl(String url) {
    return url.contains('status=cancelled') ||
           url.contains('status=canceled') ||
           url.contains('status=failed') ||
           url.contains('cancel=true');
  }

  void _handleSuccess(String url) {
    String? transactionId;
    try {
      final uri = Uri.parse(url);
      transactionId = uri.queryParameters['transaction_id'];
    } catch (e) {
      debugPrint('Error parsing success URL: $e');
    }

    _returnResult(PaymentResult(
      status: PaymentStatus.success,
      txRef: widget.txRef,
      transactionId: transactionId,
      message: 'Payment successful',
    ));
  }

  void _handleSuccessWithData(Map<String, dynamic> data) {
    _returnResult(PaymentResult(
      status: PaymentStatus.success,
      txRef: data['tx_ref'] ?? widget.txRef,
      transactionId: data['transaction_id']?.toString(),
      message: 'Payment successful',
    ));
  }

  void _handleCancellation() {
    _returnResult(PaymentResult(
      status: PaymentStatus.cancelled,
      txRef: widget.txRef,
      message: 'Payment cancelled by user',
    ));
  }

  void _handleDeepLink(String url) {
    if (url.contains('success')) {
      _handleSuccess(url);
    } else if (url.contains('cancel')) {
      _handleCancellation();
    }
  }

  void _returnResult(PaymentResult result) {
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }

  Future<void> _retryLoading() async {
    setState(() {
      _hasError = false;
      _isLoading = true;
      _errorMessage = null;
    });
    _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _handleCancellation,
        ),
        title: const Text(
          'Secure Checkout',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 12, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'SSL Secure',
                  style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: const Color(0xFF0A0A0F),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _progress > 0 ? _progress / 100 : null,
                    color: const Color(0xFFFFB830),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading secure checkout...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  if (_progress > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '$_progress%',
                      style: const TextStyle(color: Color(0xFFFFB830), fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          if (_hasError)
            Container(
              color: const Color(0xFF0A0A0F),
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load payment page',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _retryLoading,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB830),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _handleCancellation,
                      child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── DATA MODELS ──────────────────────────────────────────────────────────────

class PaymentResult {
  final PaymentStatus status;
  final String txRef;
  final String? transactionId;
  final String? message;

  PaymentResult({
    required this.status,
    required this.txRef,
    this.transactionId,
    this.message,
  });

  bool get isSuccess => status == PaymentStatus.success;
  bool get isCancelled => status == PaymentStatus.cancelled;
  bool get isPending => status == PaymentStatus.pending;
  bool get isError => status == PaymentStatus.error;
}

class PaymentVerificationResult {
  final bool success;
  final String? plan;
  final Map<String, dynamic>? subscription;
  final String message;

  PaymentVerificationResult({
    required this.success,
    this.plan,
    this.subscription,
    required this.message,
  });
}

class SubscriptionStatus {
  final String plan;
  final String status;
  final bool autoRenew;
  final DateTime? expiresAt;
  final DateTime? startedAt;

  SubscriptionStatus({
    required this.plan,
    required this.status,
    required this.autoRenew,
    this.expiresAt,
    this.startedAt,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      plan: json['plan'] ?? '',
      status: json['status'] ?? '',
      autoRenew: json['auto_renew'] ?? true,
      expiresAt: json['expires_at'] != null 
          ? DateTime.tryParse(json['expires_at']) 
          : null,
      startedAt: json['started_at'] != null 
          ? DateTime.tryParse(json['started_at']) 
          : null,
    );
  }

  bool get isActive => status == 'active';
  bool get isExpired => status == 'expired';
  bool get isCancelled => status == 'cancelled';
}

// Backward-compatible alias
typedef FlutterwaveWebPayment = FlutterwavePaymentService;
