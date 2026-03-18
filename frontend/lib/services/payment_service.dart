import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/app_config.dart';

class FlutterwaveWebPayment {
  static Future<String?> startPayment({
    required BuildContext context,
    required String email,
    required String name,
    required String amount,
    required String txRef,
    required String plan,
  }) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _PaymentWebView(
          email:  email,
          name:   name,
          amount: amount,
          txRef:  txRef,
          plan:   plan,
        ),
        fullscreenDialog: true,
      ),
    );
    return result;
  }
}

class _PaymentWebView extends StatefulWidget {
  final String email;
  final String name;
  final String amount;
  final String txRef;
  final String plan;

  const _PaymentWebView({
    required this.email,
    required this.name,
    required this.amount,
    required this.txRef,
    required this.plan,
  });

  @override
  State<_PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<_PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            final url = request.url;
            // Detect successful payment redirect
            if (url.contains('promptreel.ai/payment/callback') ||
                url.contains('status=successful') ||
                url.contains('status=completed')) {
              Navigator.of(context).pop('success');
              return NavigationDecision.prevent;
            }
            // Detect cancelled payment
            if (url.contains('status=cancelled') ||
                url.contains('status=failed')) {
              Navigator.of(context).pop('cancelled');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(_buildPaymentHtml());
  }

  String _buildPaymentHtml() {
    final key    = AppConfig.flutterwavePublicKey;
    final amount = widget.amount;
    final email  = widget.email;
    final name   = widget.name;
    final txRef  = widget.txRef;
    final plan   = widget.plan;

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PromptReel AI Payment</title>
  <script src="https://checkout.flutterwave.com/v3.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      background: #0A0A0F;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      font-family: Arial, sans-serif;
    }
    .container {
      text-align: center;
      color: white;
      padding: 40px 20px;
    }
    .logo {
      font-size: 48px;
      margin-bottom: 16px;
    }
    .title {
      font-size: 22px;
      font-weight: 800;
      color: #FFB830;
      margin-bottom: 8px;
    }
    .subtitle {
      font-size: 14px;
      color: #888;
      margin-bottom: 32px;
    }
    .btn {
      background: linear-gradient(135deg, #FFB830, #FF8C00);
      color: black;
      border: none;
      padding: 16px 48px;
      border-radius: 50px;
      font-size: 16px;
      font-weight: 800;
      cursor: pointer;
      width: 100%;
      max-width: 300px;
    }
    .amount {
      font-size: 36px;
      font-weight: 900;
      color: white;
      margin-bottom: 8px;
    }
    .plan-name {
      font-size: 14px;
      color: #FFB830;
      text-transform: uppercase;
      letter-spacing: 2px;
      margin-bottom: 32px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">🎬</div>
    <div class="title">PromptReel AI</div>
    <div class="subtitle">Secure payment via Flutterwave</div>
    <div class="amount">\$$amount/mo</div>
    <div class="plan-name">$plan Plan</div>
    <button class="btn" onclick="makePayment()">
      Pay Now
    </button>
  </div>

  <script>
    // Auto-trigger payment on load
    window.onload = function() {
      setTimeout(makePayment, 800);
    };

    function makePayment() {
      FlutterwaveCheckout({
        public_key: "$key",
        tx_ref: "$txRef",
        amount: $amount,
        currency: "USD",
        payment_options: "card",
        redirect_url: "https://promptreel.ai/payment/callback",
        meta: {
          source: "promptreel_app",
          plan: "$plan",
          consumer_id: "$txRef"
        },
        customer: {
          email: "$email",
          phone_number: "0000000000",
          name: "$name"
        },
        customizations: {
          title: "PromptReel AI",
          description: "$plan Plan — Monthly Subscription",
          logo: "https://promptreel.ai/logo.png"
        },
        callback: function(data) {
          if (data.status === "successful" || data.status === "completed") {
            window.location.href =
              "https://promptreel.ai/payment/callback?status=successful&tx_ref=$txRef&transaction_id=" + data.transaction_id;
          } else {
            window.location.href =
              "https://promptreel.ai/payment/callback?status=" + data.status;
          }
        },
        onclose: function() {
          window.location.href =
            "https://promptreel.ai/payment/callback?status=cancelled";
        }
      });
    }
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
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop('cancelled'),
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
              children: [
                Icon(Icons.lock_outline, size: 12, color: Colors.green),
                SizedBox(width: 4),
                Text('Secure',
                    style: TextStyle(color: Colors.green, fontSize: 12)),
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
                      'Loading secure payment...',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
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
