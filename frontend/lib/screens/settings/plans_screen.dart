import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  static const _plans = [
    {
      'id': 'free',
      'name': 'Free',
      'price': '\$0',
      'period': 'forever',
      'color': 0xFF66667A,
      'ai_primary': 'Gemini 1.5 Flash',
      'ai_chain': 'Gemini Flash · Groq Llama 3.3 · DeepSeek-V3 · Qwen 2.5 · OpenRouter',
      'ai_badge': '⚡ Fast Free Models',
      'features': [
        '3 video plans per day',
        'Up to 5-minute videos',
        'All content types & platforms',
        'All AI generators supported',
        'Basic export (individual files)',
        'Ads supported',
      ],
      'missing': ['10 & 20 min videos', 'ZIP package export', 'No ads', 'Batch planner'],
    },
    {
      'id': 'creator',
      'name': 'Creator',
      'price': '\$15',
      'period': '/month',
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
      'price': '\$35',
      'period': '/month',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
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
                title: Text('Upgrade Plan', style: AppTypography.headlineMedium),
                centerTitle: false,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(),
                      const SizedBox(height: AppSpacing.lg),

                      // Plan cards
                      ..._plans.asMap().entries.map((e) {
                        final plan = e.value;
                        final isCurrent = user?.plan == plan['id'];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _PlanCard(
                            plan: plan,
                            isCurrent: isCurrent,
                            onSelect: () => _handleSelect(context, plan['id'] as String),
                          ).animate(delay: Duration(milliseconds: e.key * 120)).fadeIn().slideY(begin: 0.15),
                        );
                      }),

                      // Payment methods
                      _buildPaymentMethods(),
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
          child: const Icon(Icons.workspace_premium_rounded, color: Colors.black, size: 32),
        ).animate().scale(curve: Curves.elasticOut, duration: 700.ms),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
          child: Text(
            'Unlock Full Power',
            style: AppTypography.displaySmall.copyWith(color: Colors.white),
          ),
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

  Widget _buildPaymentMethods() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Secure Global Payments', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _payBadge('Paystack', '🌍 Africa + International'),
              const SizedBox(width: 8),
              _payBadge('LemonSqueezy', '🌐 Global SaaS'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'We accept Visa, Mastercard, and local payment methods globally. Subscriptions auto-renew monthly. Cancel anytime.',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _payBadge(String name, String desc) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary)),
            Text(desc, style: AppTypography.labelSmall),
          ],
        ),
      ),
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
            ('Can I cancel anytime?', 'Yes. Cancel anytime from Settings. You keep access until the billing period ends.'),
            ('Is there a free trial?', 'The Free plan gives you 3 plans/day forever. No credit card needed.'),
            ('What AI providers are used?', 'We use OpenAI GPT-4o, Google Gemini, and Claude for maximum reliability.'),
            ('Do you generate videos?', 'No. We generate prompts, scripts, and SEO. You use these with Runway, Kling, Pika, etc.'),
          ].map((faq) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(faq.$1, style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
                const SizedBox(height: 4),
                Text(faq.$2, style: AppTypography.bodySmall),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _handleSelect(BuildContext context, String planId) {
    if (planId == 'free') return;
    // Launch payment page — replace with Paystack/LemonSqueezy integration
    launchUrl(
      Uri.parse('https://promptreel.ai/upgrade/$planId'),
      mode: LaunchMode.externalApplication,
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isCurrent;
  final VoidCallback onSelect;

  const _PlanCard({required this.plan, required this.isCurrent, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final color = Color(plan['color'] as int);
    final isPopular = plan['popular'] == true;
    final features = plan['features'] as List<dynamic>;
    final missing = plan['missing'] as List<dynamic>;
    final isFree = plan['id'] == 'free';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: isPopular
                ? LinearGradient(
                    colors: [color.withOpacity(0.08), AppColors.surface],
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
                ? [BoxShadow(color: color.withOpacity(0.12), blurRadius: 30, spreadRadius: -5)]
                : null,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + Price
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan['name'] as String, style: AppTypography.headlineMedium),
                        if (isCurrent)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text('Your current plan',
                                style: AppTypography.labelSmall.copyWith(color: AppColors.success)),
                          ),
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      style: AppTypography.bodyMedium,
                      children: [
                        TextSpan(
                          text: plan['price'] as String,
                          style: AppTypography.displaySmall.copyWith(color: color),
                        ),
                        TextSpan(text: plan['period'] as String),
                      ],
                    ),
                  ),
                ],
              ),
              // AI Model Tier Badge
              if (plan['ai_badge'] != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan['ai_badge'] as String,
                        style: AppTypography.labelMedium.copyWith(color: color),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan['ai_chain'] as String,
                        style: AppTypography.labelSmall.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),

              // Features
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 16, color: color),
                        const SizedBox(width: 8),
                        Expanded(child: Text(f as String, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary))),
                      ],
                    ),
                  )),

              // Not included
              if (missing.isNotEmpty) ...[
                ...missing.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.remove_circle_outline, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Expanded(child: Text(f as String, style: AppTypography.bodySmall)),
                        ],
                      ),
                    )),
              ],

              const SizedBox(height: AppSpacing.md),

              if (!isFree && !isCurrent)
                AppButton(
                  label: 'Get ${plan['name']} — ${plan['price']}${plan['period']}',
                  onPressed: onSelect,
                  fullWidth: true,
                  variant: isPopular ? AppButtonVariant.primary : AppButtonVariant.outline,
                )
              else if (isCurrent)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_rounded, size: 16, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text('Active Plan', style: AppTypography.labelLarge.copyWith(color: AppColors.success)),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: Text('Current Plan', style: AppTypography.labelLarge.copyWith(color: AppColors.textMuted)),
                  ),
                ),
            ],
          ),
        ),

        // Popular badge
        if (isPopular)
          Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  boxShadow: AppShadows.primary,
                ),
                child: Text(
                  '⭐ MOST POPULAR',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.black,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
