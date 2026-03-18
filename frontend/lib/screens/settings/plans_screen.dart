import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:go_router/go_router.dart';
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
      'ai_chain': 'Gemini Flash · Groq Llama 3.3 · DeepSeek-V3 · Qwen 2.5 · OpenRouter',
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
      'ai_chain': 'GPT-4o-mini · Grok-2 · Gemini 1.5 Pro · Mistral Large · DeepSeek-V3',
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
      'ai_chain': 'GPT-4o · Claude 3.5 Sonnet · Grok-2 · Gemini 1.5 Pro · Mistral Large',
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

      final flutterwave = Flutterwave(
        publicKey:      AppConfig.flutterwavePublicKey,
        currency:       'USD',
        amount:         (plan['amount_usd'] as double).toStringAsFixed(2),
        customer: Customer(
          name:        user.name,
          phoneNumber: '0000000000',  // ← required by Flutterwave, cannot be empty
          email:       user.email,
        ),
        paymentOptions: 'card',  // ← simpler — card only avoids auth issues
        customization: Customization(
          title:       'PromptReel AI',
          description: '${plan['name']} Plan — Monthly Subscription',
          logo:        'https://promptreel.ai/logo.png',
        ),
        txRef:          txRef,
        isTestMode:     AppConfig.flutterwaveTestMode,
        redirectUrl:    'https://promptreel.ai/payment/callback', // ← valid HTTPS URL
      );

      final ChargeResponse response =
          await flutterwave.charge(context);

      if (!mounted) return;

      final status = (response.status ?? '').toLowerCase().trim();

      if (status == 'successful' || status == 'completed') {
        if (response.transactionId != null) {
          await _verifyAndUpgrade(
            transactionId: response.transactionId!,
            txRef:         txRef,
            planId:        planId,
            planName:      plan['name'] as String,
          );
        } else {
          // No transaction ID — verify by txRef
          await _verifyAndUpgrade(
            transactionId: '0',
            txRef:         txRef,
            planId:        planId,
            planName:      plan['name'] as String,
          );
        }
      } else if (status == 'cancelled' ||
                 status == 'cancel' ||
                 status == 'user_cancelled') {
        _showInfo('Payment cancelled.');
      } else if (status.isEmpty || status == 'null') {
        _showInfo('Payment window closed.');
      } else {
        _showError(
          'Payment was not completed. Status: $status\n'
          'Please try again or use a different card.',
        );
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('cancel') || errStr.contains('closed')) {
          _showInfo('Payment cancelled.');
        } else {
          _showError(
            'Payment error. Please try again.\n'
            'If issue persists, contact support.',
          );
        }
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
      final api = ref.read(apiServiceProvider);
      await api.verifyPayment(
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
          'Contact support with reference: $txRef',
        );
      }
    }
  }

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
            child: Text(message,
                style: const TextStyle(fontSize: 13))),
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
                            isDisabled:
                                _isProcessing && !isLoading,
                            onSelect:   () => _handleSelect(plan),
                          ).animate(
                            delay: Duration(
                                milliseconds: e.key * 120),
                          ).fadeIn().slideY(begin: 0.15),
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
            'Prices in USD. Subscriptions are monthly and can be cancelled anytime.',
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
              'No. We generate scripts, prompts & SEO. You use those with Runway, Kling, Pika etc.'
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
                    Text(faq.$2,
                        style: AppTypography.bodySmall),
                  ],
                ),
              )),
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
    final color    = Color(plan['color'] as int);
    final isPopular = plan['popular'] == true;
    final isFree   = plan['id'] == 'free';
    final features = plan['features'] as List<dynamic>;
    final missing  = plan['missing'] as List<dynamic>;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: isPopular
                ? LinearGradient(
                    colors: [
                      color.withOpacity(0.08),
                      AppColors.surface
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
              // ── Header Row ────────────────────────────────────────────
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
                    border:
                        Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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

              // ── Missing Features ──────────────────────────────────────
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

              // ── CTA Button ────────────────────────────────────────────
              if (!isFree && !isCurrent)
                AppButton(
                  label: isLoading
                      ? 'Processing…'
                      : 'Get ${plan['name']} — ${plan['price_label']}${plan['period']}',
                  onPressed:
                      (isDisabled || isLoading) ? null : onSelect,
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
                        color:
                            AppColors.success.withOpacity(0.3)),
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
                  shape: BoxShape.circle),
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
              'Please wait while we confirm your payment with Flutterwave.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
