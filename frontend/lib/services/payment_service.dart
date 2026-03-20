import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/app_config.dart';

/// Cross-platform Flutterwave payment service.
/// - Web     → opens your backend checkout page in browser tab
/// - Mobile  → opens your backend checkout page in in-app WebView
class FlutterwavePaymentService {
  
  /// Start payment process
  /// Returns: 'success', 'cancelled', 'pending' (web), or null on error
  static Future<String?> startPayment({
    required BuildContext context,
    required String email,
    required String name,
    required String planId,  // 'creator' or 'studio' - NOT amount
    required String txRef,
    String currency = 'USD',
  }) async {
    // Validate plan
    if (planId != 'creator' && planId != 'studio') {
      throw ArgumentError('Invalid plan. Must be "creator" or "studio"');
    }

    if (kIsWeb) {
      return _startWebPayment(
        email: email,
        name: name,
        planId: planId,
        txRef: txRef,
        currency: currency,
      );
    } else {
      return _startMobilePayment(
        context: context,
        email: email,
        name: name,
        planId: planId,
        txRef: txRef,
        currency: currency,
      );
    }
  }

  // ─── WEB ─────────────────────────────────────────────────────────────────
  /// On web, open your backend checkout page in new browser tab
  static Future<String?> _startWebPayment({
    required String email,
    required String name,
    required String planId,
    required String txRef,
    required String currency,
  }) async {
    // Build URL to YOUR backend checkout page
    final checkoutUrl = Uri.parse(
      '${AppConfig.apiBaseUrl}/api/payments/checkout-page',
    ).replace(queryParameters: {
      'plan_id': planId,
      'email': email,
      'name': name,
      'tx_ref': txRef,
      'currency': currency,
    });

    debugPrint('Opening checkout URL: $checkoutUrl');

    if (await canLaunchUrl(checkoutUrl)) {
      await launchUrl(
        checkoutUrl,
        mode: LaunchMode.externalApplication,
      );
      // Web cannot detect completion, return 'pending'
      // Caller should show "I have paid" button
      return 'pending';
    }
    
    debugPrint('Could not launch URL: $checkoutUrl');
    return null;
  }

  // ─── MOBILE ──────────────────────────────────────────────────────────────
  /// On Android/iOS, open checkout in in-app WebView
  static Future<String?> _startMobilePayment({
    required BuildContext context,
    required String email,
    required String name,
    required String planId,
    required String txRef,
    required String currency,
  }) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _MobilePaymentPage(
          email: email,
          name: name,
          planId: planId,
          txRef: txRef,
          currency: currency,
        ),
        fullscreenDialog: true,
      ),
    );
    return result;
  }
}

// ─── Mobile WebView Page ──────────────────────────────────────────────────────
class _MobilePaymentPage extends StatefulWidget {
  final String email;
  final String name;
  final String planId;
  final String txRef;
  final String currency;

  const _MobilePaymentPage({
    required this.email,
    required this.name,
    required this.planId,
    required this.txRef,
    required this.currency,
  });

  @override
  State<_MobilePaymentPage> createState() => _MobilePaymentPageState();
}

class _MobilePaymentPageState extends State<_MobilePaymentPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoading = false);
            },
            onWebResourceError: (error) {
              debugPrint('WebView error: ${error.description}');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                });
              }
            },
            onNavigationRequest: (req) {
              final url = req.url;
              debugPrint('Navigation request: $url');
              
              // Check for success
              if (url.contains('status=successful') ||
                  (url.contains('/api/payments/callback') && 
                   url.contains('transaction_id'))) {
                _handleSuccess();
                return NavigationDecision.prevent;
              }
              
              // Check for cancellation/failure
              if (url.contains('status=cancelled') ||
                  url.contains('status=failed') ||
                  url.contains('cancel')) {
                _handleCancellation();
                return NavigationDecision.prevent;
              }
              
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(_checkoutUri);
    } catch (e) {
      debugPrint('WebView init error: $e');
      setState(() => _hasError = true);
    }
  }

  Uri get _checkoutUri {
    return Uri.parse(
      '${AppConfig.apiBaseUrl}/api/payments/checkout-page',
    ).replace(queryParameters: {
      'plan_id': widget.planId,
      'email': widget.email,
      'name': widget.name,
      'tx_ref': widget.txRef,
      'currency': widget.currency,
    });
  }

  void _handleSuccess() {
    if (mounted) {
      Navigator.of(context).pop('success');
    }
  }

  void _handleCancellation() {
    if (mounted) {
      Navigator.of(context).pop('cancelled');
    }
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
          onPressed: () => _handleCancellation(),
        ),
        title: const Text(
          'Secure Payment',
          style: TextStyle(color: Colors.white, fontSize: 16),
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
                  style: TextStyle(color: Colors.green, fontSize: 12),
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
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFFFFB830)),
                    SizedBox(height: 16),
                    Text(
                      'Loading secure checkout...',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          if (_hasError)
            Container(
              color: const Color(0xFF0A0A0F),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, 
                      color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load payment page',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _isLoading = true;
                        });
                        _initWebView();
                      },
                      child: const Text('Retry'),
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

// Backward-compatible alias
typedef FlutterwaveWebPayment = FlutterwavePaymentService;
