import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';  // ← FIXED: proper import at top
import '../config/app_config.dart';

/// Cross-platform Flutterwave payment service.
/// - Web     → opens Flutterwave hosted checkout in a browser tab
/// - Mobile  → opens Flutterwave JS SDK inside an in-app WebView
class FlutterwavePaymentService {
  static Future<String?> startPayment({
    required BuildContext context,
    required String email,
    required String name,
    required String amount,
    required String txRef,
    required String plan,
  }) async {
    if (kIsWeb) {
      return _startWebPayment(
        email: email, name: name, amount: amount,
        txRef: txRef, plan: plan,
      );
    } else {
      return _startMobilePayment(
        context: context,
        email: email, name: name, amount: amount,
        txRef: txRef, plan: plan,
      );
    }
  }

  // ─── WEB ─────────────────────────────────────────────────────────────────
  // On web, open the Flutterwave hosted checkout in a new browser tab.
  // Flutter web cannot run a WebView or execute native JS SDKs directly.
  static Future<String?> _startWebPayment({
    required String email, required String name,
    required String amount, required String txRef, required String plan,
  }) async {
    final params = {
      'public_key':              AppConfig.flutterwavePublicKey,
      'tx_ref':                  txRef,
      'amount':                  amount,
      'currency':                'USD',
      'payment_options':         'card',
      'redirect_url':            'https://promptreel-ai.onrender.com/api/payments/callback',
      'customer[email]':         email,
      'customer[name]':          name,
      'customizations[title]':         'PromptReel AI',
      'customizations[description]':   '$plan Plan - Monthly Subscription',
      'meta[plan]':   plan,
      'meta[tx_ref]': txRef,
    };
    final query = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final uri = Uri.parse('https://checkout.flutterwave.com/v3/hosted/pay?$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      // Cannot detect in-app completion on web; caller shows "return & refresh" UI.
      return 'pending';
    }
    return null;
  }

  // ─── MOBILE ──────────────────────────────────────────────────────────────
  // On Android/iOS, push an in-app WebView that loads the Flutterwave JS SDK.
  static Future<String?> _startMobilePayment({
    required BuildContext context,
    required String email, required String name,
    required String amount, required String txRef, required String plan,
  }) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _MobilePaymentPage(
          email: email, name: name, amount: amount,
          txRef: txRef, plan: plan,
        ),
        fullscreenDialog: true,
      ),
    );
    return result;
  }
}

// Backward-compatible alias
typedef FlutterwaveWebPayment = FlutterwavePaymentService;

// ─── Mobile WebView Page ──────────────────────────────────────────────────────
class _MobilePaymentPage extends StatefulWidget {
  final String email, name, amount, txRef, plan;
  const _MobilePaymentPage({
    required this.email, required this.name, required this.amount,
    required this.txRef, required this.plan,
  });

  @override
  State<_MobilePaymentPage> createState() => _MobilePaymentPageState();
}

class _MobilePaymentPageState extends State<_MobilePaymentPage> {
  late final WebViewController _controller;  // ← FIXED: typed, not dynamic
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _buildWebViewController();
  }

  void _buildWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (req) {
            final url = req.url;
            if (url.contains('status=successful') ||
                (url.contains('payment/callback') &&
                    url.contains('transaction_id'))) {
              Navigator.of(context).pop('success');
              return NavigationDecision.prevent;
            }
            if (url.contains('status=cancelled') ||
                url.contains('status=failed')) {
              Navigator.of(context).pop('cancelled');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(_html);
  }

  String get _html {
    final k = AppConfig.flutterwavePublicKey;
    final a = widget.amount;
    final e = widget.email;
    final n = widget.name;
    final t = widget.txRef;
    final p = widget.plan;
    return '''<!DOCTYPE html><html><head>
<meta name="viewport" content="width=device-width,initial-scale=1">
<script src="https://checkout.flutterwave.com/v3.js"></script>
<style>*{margin:0;padding:0;box-sizing:border-box}
body{background:#0A0A0F;display:flex;align-items:center;justify-content:center;min-height:100vh;font-family:Arial,sans-serif}
.c{text-align:center;color:#fff;padding:40px 20px}
.t{font-size:22px;font-weight:800;color:#FFB830;margin-bottom:8px}
.s{font-size:14px;color:#888;margin-bottom:32px}
.a{font-size:36px;font-weight:900;color:#fff;margin-bottom:8px}
.pl{font-size:14px;color:#FFB830;text-transform:uppercase;letter-spacing:2px;margin-bottom:32px}
.b{background:linear-gradient(135deg,#FFB830,#FF8C00);color:#000;border:none;padding:16px 48px;border-radius:50px;font-size:16px;font-weight:800;cursor:pointer;width:100%;max-width:300px}</style>
</head><body>
<div class="c"><div style="font-size:48px;margin-bottom:16px">🎬</div>
<div class="t">PromptReel AI</div>
<div class="s">Secure payment via Flutterwave</div>
<div class="a">\$$a/mo</div><div class="pl">$p Plan</div>
<button class="b" onclick="pay()">Pay Now</button></div>
<script>
window.onload=()=>setTimeout(pay,800);
function pay(){FlutterwaveCheckout({public_key:"$k",tx_ref:"$t",amount:$a,currency:"USD",payment_options:"card",
redirect_url:"https://promptreel.ai/payment/callback",
meta:{source:"promptreel_app",plan:"$p"},
customer:{email:"$e",phone_number:"0000000000",name:"$n"},
customizations:{title:"PromptReel AI",description:"$p Plan"},
callback:function(d){window.location.href="https://promptreel.ai/payment/callback?status="+(d.status==="successful"||d.status==="completed"?"successful":d.status)+"&tx_ref=$t&transaction_id="+d.transaction_id;},
onclose:function(){window.location.href="https://promptreel.ai/payment/callback?status=cancelled";}});}
</script></body></html>''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121A),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop('cancelled'),
        ),
        title: const Text('Secure Payment',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.lock_outline, size: 12, color: Colors.green),
              SizedBox(width: 4),
              Text('Secure',
                  style:
                      TextStyle(color: Colors.green, fontSize: 12)),
            ]),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),  // ← FIXED: typed directly
          if (_isLoading)
            Container(
              color: const Color(0xFF0A0A0F),
              child: const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFFFB830)),
              ),
            ),
        ],
      ),
    );
  }
}
