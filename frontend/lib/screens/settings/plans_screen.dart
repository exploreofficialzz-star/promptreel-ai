import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  bool _isProcessing  = false;
  String? _processingPlan;

  static const _plans = [
    {
      'id': 'free',
      'name': 'Free',
      'price_label': r'$0',
      'period': 'forever',
      'amount_usd': 0.0,
      'color': 0xFF66667A,
      'ai_primary': 'Gemini 2.0 Flash',
      'ai_chain':
          'Gemini Flash · Groq Llama 3.3 · DeepSeek-V3 · Qwen 2.5 · OpenRouter',
      'ai_badge': '⚡ Fast Free Models',
      'features': [
        '3 video plans per day',
        'Up to 5-minute videos',
        'All content types & platforms',
        'All AI generators supported',
        'Basic export (individual files)',
      ],
      'missing': [
        '10 & 20 min videos',
        'ZIP package export',
        'No ads',
        'Batch planner',
      ],
    },
    {
      'id': 'creator',
      'name': 'Creator',
      'price_label': r'$15',
      'period': '/month',
      'amount_usd': AppConfig.creatorPriceUsd,
      'popular': true,
      'color': 0xFFFFB830,
      'ai_primary': 'GPT-4o-mini',
      'ai_chain':
          'GPT-4o-mini · Grok-2 · Gemini 1.5 Pro · Mistral Large · DeepSeek-V3',
      'ai_badge': '🚀 Pro Models',
      'features': [
        'Unlimited video plans',
        'Up to 20-minute videos',
        'No ads — ever',
        'Full ZIP package export',
        'Advanced AI prompts',
        'Batch planner (10 at once)',
        'Priority AI processing',
        'All content types & platforms',
      ],
      'missing': ['Team collaboration', 'API access'],
    },
    {
      'id': 'studio',
      'name': 'Studio',
      'price_label': r'$35',
      'period': '/month',
      'amount_usd': AppConfig.studioPriceUsd,
      'color': 0xFF00E5CC,
      'ai_primary': 'GPT-4o',
      'ai_chain':
          'GPT-4o · Claude 3.5 Sonnet · Grok-2 · Gemini 1.5 Pro · Mistral Large',
      'ai_badge': '🏆 Frontier Models',
      'features': [
        'Everything in Creator',
        'GPT-4o + Claude 3.5 Sonnet',
        'Team collaboration (5 seats)',
        'Priority AI processing',
        'API access',
        'Custom branding',
        'Dedicated support',
        'Early access to new features',
      ],
      'missing': [],
    },
  ];

  // ── Handle Plan Select ────────────────────────────────────────────────────
  Future<void> _handleSelect(Map<String, dynamic> plan) async {
    final planId = plan['id'] as String;
    if (planId == 'free') return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      _showError('Please log in before upgrading.');
      return;
    }

    setState(() {
      _isProcessing   = true;
      _processingPlan = planId;
    });

    try {
      final txRef =
          'PR-${user.id}-$planId-${DateTime.now().millisecondsSinceEpoch}';

      final result = await Navigator.of(context).push<Map<String, String>>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _FlutterwaveWebView(
            email:    user.email,
            name:     user.name,
            amount:   (plan['amount_usd'] as double).toStringAsFixed(2),
            txRef:    txRef,
            planName: plan['name'] as String,
          ),
        ),
      );

      if (!mounted) return;

      if (result == null) {
        _showInfo('Payment cancelled.');
        return;
      }

      final status        = result['status'] ?? '';
      final transactionId = result['transaction_id'] ?? '0';

      if (status == 'successful' || status == 'completed') {
        await _verifyAndUpgrade(
          transactionId: transactionId,
          txRef:         txRef,
          planId:        planId,
          planName:      plan['name'] as String,
        );
      } else if (status == 'cancelled') {
        _showInfo('Payment cancelled.');
      } else if (status == 'timeout') {
        _showError(
          'Connection timed out.\n'
          'Please check your internet and try again.',
        );
      } else {
        _showError('Payment was not completed.\nPlease try again.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Payment error. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing   = false;
          _processingPlan = null;
        });
      }
    }
  }

  // ── Verify & Upgrade ──────────────────────────────────────────────────────
  Future<void> _verifyAndUpgrade({
    required String transactionId,
    required String txRef,
    required String planId,
    required String planName,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _VerifyingDialog(),
    );

    try {
      await ref.read(apiServiceProvider).verifyPayment(
        transactionId: transactionId,
        txRef:         txRef,
        plan:          planId,
      );
      await ref.read(authProvider.notifier).refreshUser();

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccess(planName);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showError(
          'Payment received but verification failed.\n'
          'Contact support with reference:\n$txRef',
        );
      }
    }
  }

  // ── Success Dialog ────────────────────────────────────────────────────────
  void _showSuccess(String planName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.black, size: 40),
            ).animate().scale(
                curve: Curves.elasticOut, duration: 600.ms),
            const SizedBox(height: 16),
            Text('🎉 Welcome to $planName!',
                style: AppTypography.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Your plan has been upgraded successfully. '
              'Enjoy all the new features!',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Start Creating',
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/create');
              },
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child:
                Text(message, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 6),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.surfaceElevated,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.go('/settings'),
                ),
                title: Text('Upgrade Plan',
                    style: AppTypography.headlineMedium),
                centerTitle: false,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: AppSpacing.lg),
                      ..._plans.asMap().entries.map((e) {
                        final plan = e.value;
                        final isCurrent =
                            (user?.plan ?? 'free').toLowerCase() ==
                                (plan['id'] as String).toLowerCase();
                        final isLoading = _isProcessing &&
                            _processingPlan == plan['id'];
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: 16),
                          child: _PlanCard(
                            plan:       plan,
                            isCurrent:  isCurrent,
                            isLoading:  isLoading,
                            isDisabled: _isProcessing && !isLoading,
                            onSelect:   () => _handleSelect(plan),
                          )
                              .animate(
                                  delay: Duration(
                                      milliseconds: e.key * 120))
                              .fadeIn()
                              .slideY(begin: 0.15),
                        );
                      }),
                      _buildPaymentInfo(),
                      const SizedBox(height: AppSpacing.md),
                      _buildFaq(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: AppShadows.glow,
          ),
          child: const Icon(Icons.workspace_premium_rounded,
              color: Colors.black, size: 32),
        ).animate().scale(curve: Curves.elasticOut, duration: 700.ms),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (b) =>
              AppColors.primaryGradient.createShader(b),
          child: Text('Unlock Full Power',
              style: AppTypography.displaySmall
                  .copyWith(color: Colors.white)),
        ),
        const SizedBox(height: 4),
        Text(
          'Generate unlimited AI video plans with no restrictions',
          style: AppTypography.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPaymentInfo() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius:
                      BorderRadius.circular(AppRadius.sm),
                ),
                child: const Text('🌍',
                    style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Secure Payment via Flutterwave',
                        style: AppTypography.titleMedium),
                    Text('Worldwide · Cards · Bank Transfer',
                        style: AppTypography.labelSmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          _payMethod('💳', 'Cards', 'Visa, Mastercard, Amex'),
          _payMethod('🏦', 'Bank Transfer', 'International wire'),
          _payMethod('📱', 'USSD', 'Available in supported regions'),
          _payMethod('📲', 'Mobile Money', 'Where available'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Prices in USD. Subscriptions monthly, cancel anytime.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _payMethod(String icon, String name, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Text(name,
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.textPrimary)),
        const SizedBox(width: 6),
        Text('· $desc', style: AppTypography.labelSmall),
      ]),
    );
  }

  Widget _buildFaq() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FAQ', style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          ...[
            (
              'Can I cancel anytime?',
              'Yes. Cancel from Settings — access continues until billing period ends.'
            ),
            (
              'Is there a free trial?',
              'The Free plan gives you 3 plans/day forever — no card needed.'
            ),
            (
              'Which AI models do I get?',
              'Creator gets GPT-4o-mini & Gemini Pro. Studio gets GPT-4o & Claude 3.5 Sonnet.'
            ),
            (
              'Do you generate actual videos?',
              'No. We generate scripts, prompts & SEO. Use those with Runway, Kling, Pika etc.'
            ),
            (
              'Is my payment secure?',
              'Yes — processed entirely by Flutterwave. We never store your card details.'
            ),
          ].map((faq) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(faq.$1,
                        style: AppTypography.labelLarge
                            .copyWith(color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(faq.$2, style: AppTypography.bodySmall),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Flutterwave WebView Checkout ─────────────────────────────────────────────
class _FlutterwaveWebView extends StatefulWidget {
  final String email;
  final String name;
  final String amount;
  final String txRef;
  final String planName;

  const _FlutterwaveWebView({
    required this.email,
    required this.name,
    required this.amount,
    required this.txRef,
    required this.planName,
  });

  @override
  State<_FlutterwaveWebView> createState() => _FlutterwaveWebViewState();
}

class _FlutterwaveWebViewState extends State<_FlutterwaveWebView> {
  late final WebViewController _controller;
  bool _isLoading  = true;
  bool _hasError   = false;
  bool _timedOut   = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
    // ── Timeout — if still loading after 20s show error ─────────────────────
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted && _isLoading && !_hasError) {
        setState(() {
          _isLoading = false;
          _timedOut  = true;
        });
      }
    });
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0A0F))
      ..addJavaScriptChannel(
        'PaymentResult',
        onMessageReceived: (msg) {
          final parts         = msg.message.split('|');
          final status        = parts.isNotEmpty ? parts[0] : '';
          final transactionId = parts.length > 1 ? parts[1] : '0';
          if (mounted) {
            Navigator.of(context).pop({
              'status':         status,
              'transaction_id': transactionId,
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError  = true;
              });
            }
          },
          onNavigationRequest: (req) {
            final url = req.url;
            if (url.contains('promptreel.ai/payment/callback')) {
              final uri    = Uri.parse(url);
              final status = uri.queryParameters['status'] ?? '';
              final txId   = uri.queryParameters['transaction_id'] ?? '0';
              if (mounted) {
                Navigator.of(context).pop({
                  'status':         status,
                  'transaction_id': txId,
                });
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(_buildHtml());
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _hasError  = false;
      _timedOut  = false;
    });
    _controller.loadHtmlString(_buildHtml());
  }

  String _buildHtml() {
    final key      = AppConfig.flutterwavePublicKey;
    final amount   = widget.amount;
    final email    = widget.email;
    final name     = widget.name.replaceAll("'", "\\'");
    final txRef    = widget.txRef;
    final planName = widget.planName;

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport"
        content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
  <title>PromptReel Payment</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      background: #0A0A0F;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      font-family: -apple-system, Arial, sans-serif;
      padding: 24px;
    }
    .card {
      background: #12121A;
      border: 1px solid #2A2A3A;
      border-radius: 20px;
      padding: 36px 28px;
      width: 100%;
      max-width: 400px;
      text-align: center;
    }
    .emoji { font-size: 48px; margin-bottom: 12px; }
    .app-name {
      color: #FFB830;
      font-size: 22px;
      font-weight: 800;
      margin-bottom: 4px;
    }
    .tagline { color: #666; font-size: 13px; margin-bottom: 28px; }
    .price-box {
      background: #1A1A2E;
      border: 1px solid #2A2A3A;
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 28px;
    }
    .price { color: white; font-size: 42px; font-weight: 900; line-height: 1; }
    .price span { font-size: 18px; font-weight: 400; color: #888; }
    .plan-badge {
      display: inline-block;
      background: rgba(255,184,48,0.15);
      color: #FFB830;
      border: 1px solid rgba(255,184,48,0.3);
      border-radius: 50px;
      padding: 4px 14px;
      font-size: 12px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1px;
      margin-top: 8px;
    }
    .pay-btn {
      width: 100%;
      padding: 18px;
      background: linear-gradient(135deg, #FFB830, #FF8C00);
      color: #000;
      font-size: 16px;
      font-weight: 800;
      border: none;
      border-radius: 50px;
      cursor: pointer;
      margin-bottom: 16px;
      transition: opacity 0.2s;
    }
    .pay-btn:disabled { opacity: 0.6; cursor: not-allowed; }
    .secure {
      color: #444;
      font-size: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 6px;
    }
    .status-msg {
      color: #888;
      font-size: 13px;
      margin-top: 12px;
      min-height: 20px;
    }
    .spinner {
      display: inline-block;
      width: 18px; height: 18px;
      border: 2px solid rgba(0,0,0,0.3);
      border-top-color: #000;
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
      vertical-align: middle;
      margin-right: 6px;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
  </style>
</head>
<body>
  <div class="card">
    <div class="emoji">🎬</div>
    <div class="app-name">PromptReel AI</div>
    <div class="tagline">AI Video Production Platform</div>

    <div class="price-box">
      <div class="price">\$$amount<span>/mo</span></div>
      <div class="plan-badge">$planName Plan</div>
    </div>

    <button class="pay-btn" id="payBtn" onclick="makePayment()">
      Pay Securely — \$$amount
    </button>

    <div class="secure">🔒 Secured by Flutterwave</div>
    <div class="status-msg" id="statusMsg"></div>
  </div>

  <script>
    var scriptLoaded = false;
    var retryCount   = 0;

    function loadScript(callback) {
      var s = document.createElement('script');
      s.src = 'https://checkout.flutterwave.com/v3.js';
      s.onload = function() {
        scriptLoaded = true;
        if (callback) callback();
      };
      s.onerror = function() {
        document.getElementById('statusMsg').innerHTML =
          '⚠️ Could not load payment. Check internet connection.';
        document.getElementById('payBtn').disabled  = false;
        document.getElementById('payBtn').innerHTML =
          'Retry Payment';
      };
      document.head.appendChild(s);
    }

    function makePayment() {
      var btn = document.getElementById('payBtn');
      var msg = document.getElementById('statusMsg');

      btn.disabled    = true;
      btn.innerHTML   =
        '<span class="spinner"></span>Opening payment...';
      msg.textContent = 'Connecting to Flutterwave...';

      if (!scriptLoaded) {
        loadScript(function() { initCheckout(btn, msg); });
      } else {
        initCheckout(btn, msg);
      }
    }

    function initCheckout(btn, msg) {
      try {
        msg.textContent = 'Payment window opening...';
        FlutterwaveCheckout({
          public_key:     "$key",
          tx_ref:         "$txRef",
          amount:         $amount,
          currency:       "USD",
          payment_options:"card,banktransfer,ussd,mobilemoney",
          redirect_url:   "https://promptreel.ai/payment/callback",
          meta: {
            source:      "promptreel_mobile_app",
            plan:        "$planName",
            consumer_id: "$txRef"
          },
          customer: {
            email:        "$email",
            phone_number: "0000000000",
            name:         "$name"
          },
          customizations: {
            title:       "PromptReel AI",
            description: "$planName Plan — Monthly Subscription",
            logo:        "https://promptreel.ai/logo.png"
          },
          callback: function(data) {
            var status = data.status        || 'unknown';
            var txId   = data.transaction_id || '0';
            msg.textContent = 'Processing payment...';
            if (window.PaymentResult) {
              window.PaymentResult.postMessage(status + '|' + txId);
            } else {
              window.location.href =
                'https://promptreel.ai/payment/callback?status='
                + status + '&transaction_id=' + txId;
            }
          },
          onclose: function() {
            btn.disabled    = false;
            btn.innerHTML   = 'Pay Securely — \$$amount';
            msg.textContent = 'Payment window closed.';
            if (window.PaymentResult) {
              window.PaymentResult.postMessage('cancelled|0');
            } else {
              window.location.href =
                'https://promptreel.ai/payment/callback?status=cancelled';
            }
          }
        });
      } catch(e) {
        btn.disabled    = false;
        btn.innerHTML   = 'Retry Payment';
        msg.textContent = 'Error: ' + e.message;
      }
    }

    // Auto-trigger on load
    window.addEventListener('load', function() {
      loadScript(function() {
        setTimeout(function() { makePayment(); }, 600);
      });
    });
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: const Text(
          'Secure Checkout',
          style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(
                right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline,
                    size: 11, color: Colors.green),
                SizedBox(width: 4),
                Text('Secure',
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── WebView ───────────────────────────────────────────────────
          if (!_timedOut && !_hasError)
            WebViewWidget(controller: _controller),

          // ── Loading Overlay ───────────────────────────────────────────
          if (_isLoading && !_timedOut && !_hasError)
            Container(
              color: const Color(0xFF0A0A0F),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB830)
                            .withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFFB830),
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Loading secure payment...',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Connecting to Flutterwave',
                      style: TextStyle(
                          color: Color(0xFF444455), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // ── Timeout / Error Screen ─────────────────────────────────────
          if (_timedOut || _hasError)
            Container(
              color: const Color(0xFF0A0A0F),
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.red,
                          size: 36),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Connection Issue',
                      style: TextStyle(
                          color: Color(0xFFFFB830),
                          fontSize: 20,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _timedOut
                          ? 'Payment page took too long to load.\nPlease check your internet connection.'
                          : 'Failed to load payment page.\nPlease check your internet connection.',
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          height: 1.6),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // Retry button
                    GestureDetector(
                      onTap: _retry,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFB830),
                              Color(0xFFFF8C00)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Text(
                          'Try Again',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Cancel button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(null),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                            color: Colors.grey, fontSize: 14),
                      ),
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

// ─── Plan Card ────────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isCurrent;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.isLoading,
    required this.isDisabled,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final color     = Color(plan['color'] as int);
    final isPopular = plan['popular'] == true;
    final isFree    = plan['id'] == 'free';
    final features  = plan['features'] as List<dynamic>;
    final missing   = plan['missing'] as List<dynamic>;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: isPopular
                ? LinearGradient(
                    colors: [
                      color.withOpacity(0.08),
                      AppColors.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : AppColors.cardGradient,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isCurrent
                  ? AppColors.success.withOpacity(0.6)
                  : isPopular
                      ? color.withOpacity(0.5)
                      : AppColors.border,
              width: isPopular || isCurrent ? 1.5 : 1,
            ),
            boxShadow: isPopular
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.12),
                      blurRadius: 30,
                      spreadRadius: -5,
                    )
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(plan['name'] as String,
                            style:
                                AppTypography.headlineMedium),
                        if (isCurrent)
                          Container(
                            margin:
                                const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success
                                  .withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(
                                      AppRadius.full),
                            ),
                            child: Text('Your current plan',
                                style: AppTypography.labelSmall
                                    .copyWith(
                                        color:
                                            AppColors.success)),
                          ),
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      style: AppTypography.bodyMedium,
                      children: [
                        TextSpan(
                          text: plan['price_label'] as String,
                          style: AppTypography.displaySmall
                              .copyWith(color: color),
                        ),
                        TextSpan(
                            text: plan['period'] as String),
                      ],
                    ),
                  ),
                ],
              ),

              // ── AI Badge ──────────────────────────────────────────────
              if (plan['ai_badge'] != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                        color: color.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(plan['ai_badge'] as String,
                          style: AppTypography.labelMedium
                              .copyWith(color: color)),
                      const SizedBox(height: 2),
                      Text(plan['ai_chain'] as String,
                          style: AppTypography.labelSmall
                              .copyWith(height: 1.5)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.sm),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),

              // ── Features ──────────────────────────────────────────────
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 16, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(f as String,
                                style: AppTypography.bodySmall
                                    .copyWith(
                                        color: AppColors
                                            .textPrimary))),
                      ],
                    ),
                  )),

              // ── Missing ───────────────────────────────────────────────
              if (missing.isNotEmpty)
                ...missing.map((f) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        const Icon(
                            Icons.remove_circle_outline,
                            size: 16,
                            color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(f as String,
                                style:
                                    AppTypography.bodySmall)),
                      ]),
                    )),

              const SizedBox(height: AppSpacing.md),

              // ── CTA ───────────────────────────────────────────────────
              if (!isFree && !isCurrent)
                AppButton(
                  label: isLoading
                      ? 'Processing…'
                      : 'Get ${plan['name']} — ${plan['price_label']}${plan['period']}',
                  onPressed: (isDisabled || isLoading)
                      ? null
                      : onSelect,
                  isLoading: isLoading,
                  fullWidth: true,
                  variant: isPopular
                      ? AppButtonVariant.primary
                      : AppButtonVariant.outline,
                )
              else if (isCurrent)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: AppColors.success
                            .withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_rounded,
                            size: 16,
                            color: AppColors.success),
                        const SizedBox(width: 6),
                        Text('Active Plan',
                            style: AppTypography.labelLarge
                                .copyWith(
                                    color: AppColors.success)),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Text('Current Plan',
                        style: AppTypography.labelLarge
                            .copyWith(
                                color: AppColors.textMuted)),
                  ),
                ),
            ],
          ),
        ),

        // ── Popular Badge ─────────────────────────────────────────────
        if (isPopular)
          Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius:
                      BorderRadius.circular(AppRadius.full),
                  boxShadow: AppShadows.primary,
                ),
                child: Text('⭐ MOST POPULAR',
                    style: AppTypography.labelSmall.copyWith(
                        color: Colors.black,
                        letterSpacing: 1.0)),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Verifying Dialog ─────────────────────────────────────────────────────────
class _VerifyingDialog extends StatelessWidget {
  const _VerifyingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.black),
              ),
            ),
            const SizedBox(height: 16),
            Text('Verifying Payment…',
                style: AppTypography.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Please wait while we confirm\nyour payment with Flutterwave.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
