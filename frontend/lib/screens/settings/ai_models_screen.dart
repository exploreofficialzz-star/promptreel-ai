import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_card.dart';

class AiModelsScreen extends StatelessWidget {
  const AiModelsScreen({super.key});

  static const _providers = [
    {
      'name': 'GPT-4o',
      'company': 'OpenAI',
      'emoji': '🟢',
      'color': 0xFF10A37F,
      'plans': ['Studio'],
      'strengths': 'Best overall reasoning, long context, precise JSON output',
      'speed': '⚡⚡⚡',
      'quality': '⭐⭐⭐⭐⭐',
    },
    {
      'name': 'Claude 3.5 Sonnet',
      'company': 'Anthropic',
      'emoji': '🟠',
      'color': 0xFFCC785C,
      'plans': ['Studio'],
      'strengths': 'Exceptional writing, nuanced scripts, creative prompts',
      'speed': '⚡⚡⚡',
      'quality': '⭐⭐⭐⭐⭐',
    },
    {
      'name': 'Grok-2',
      'company': 'xAI',
      'emoji': '✖️',
      'color': 0xFFFFFFFF,
      'plans': ['Studio', 'Creator'],
      'strengths': 'Real-time knowledge, trending topics, viral content',
      'speed': '⚡⚡⚡⚡',
      'quality': '⭐⭐⭐⭐⭐',
    },
    {
      'name': 'GPT-4o-mini',
      'company': 'OpenAI',
      'emoji': '🟩',
      'color': 0xFF10A37F,
      'plans': ['Creator'],
      'strengths': 'Fast, affordable, strong JSON generation',
      'speed': '⚡⚡⚡⚡',
      'quality': '⭐⭐⭐⭐',
    },
    {
      'name': 'Gemini 1.5 Pro',
      'company': 'Google',
      'emoji': '🔵',
      'color': 0xFF4285F4,
      'plans': ['Studio', 'Creator'],
      'strengths': 'Huge context window, multilingual, multimedia-aware',
      'speed': '⚡⚡⚡',
      'quality': '⭐⭐⭐⭐',
    },
    {
      'name': 'Mistral Large',
      'company': 'Mistral AI',
      'emoji': '🟡',
      'color': 0xFFFF7000,
      'plans': ['Creator', 'Free'],
      'strengths': 'European excellence, strong instruction following',
      'speed': '⚡⚡⚡',
      'quality': '⭐⭐⭐⭐',
    },
    {
      'name': 'Gemini 1.5 Flash',
      'company': 'Google',
      'emoji': '⚡',
      'color': 0xFF4285F4,
      'plans': ['Free'],
      'strengths': 'Fastest Gemini model, generous free tier',
      'speed': '⚡⚡⚡⚡⚡',
      'quality': '⭐⭐⭐',
    },
    {
      'name': 'Llama 3.3 70B (Groq)',
      'company': 'Meta / Groq',
      'emoji': '🦙',
      'color': 0xFF6C63FF,
      'plans': ['Free'],
      'strengths': 'Ultra-fast inference, free tier, open-source quality',
      'speed': '⚡⚡⚡⚡⚡',
      'quality': '⭐⭐⭐',
    },
    {
      'name': 'DeepSeek-V3',
      'company': 'DeepSeek',
      'emoji': '🔷',
      'color': 0xFF0099FF,
      'plans': ['Free', 'Creator'],
      'strengths': 'Exceptional value, strong coding & reasoning, very cheap',
      'speed': '⚡⚡⚡⚡',
      'quality': '⭐⭐⭐⭐',
    },
    {
      'name': 'Qwen 2.5 72B',
      'company': 'Alibaba / Together AI',
      'emoji': '🌐',
      'color': 0xFFFF6B35,
      'plans': ['Free'],
      'strengths': 'Multilingual, strong Asian content, pay-as-you-go',
      'speed': '⚡⚡⚡',
      'quality': '⭐⭐⭐',
    },
    {
      'name': 'Llama 3.3 70B (OpenRouter)',
      'company': 'Meta / OpenRouter',
      'emoji': '🆓',
      'color': 0xFF9C27B0,
      'plans': ['Free'],
      'strengths': 'Completely free, multi-model fallback gateway',
      'speed': '⚡⚡⚡',
      'quality': '⭐⭐⭐',
    },
  ];

  @override
  Widget build(BuildContext context) {
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
                title: Text('AI Models', style: AppTypography.headlineMedium),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Plan routing overview
                    _buildRoutingOverview(),
                    const SizedBox(height: AppSpacing.lg),
                    Text('All Providers', style: AppTypography.headlineMedium),
                    const SizedBox(height: AppSpacing.sm),
                    ..._providers.asMap().entries.map((e) =>
                      _ProviderCard(provider: e.value)
                        .animate(delay: Duration(milliseconds: e.key * 60))
                        .fadeIn()
                        .slideY(begin: 0.1),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutingOverview() {
    return AppCard(
      borderColor: AppColors.primary.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🤖', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('Smart Model Routing', style: AppTypography.headlineMedium),
          ]),
          const SizedBox(height: 4),
          Text(
            'PromptReel AI automatically routes your generation to the best available model for your plan. If the primary model fails, it falls back through the chain — you always get a result.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          _routeRow('🔮 Free', 'Gemini Flash → Groq Llama → DeepSeek → Qwen → OpenRouter', AppColors.textMuted),
          const SizedBox(height: 8),
          _routeRow('🚀 Creator', 'GPT-4o-mini → Grok-2 → Gemini Pro → Mistral → DeepSeek', AppColors.primary),
          const SizedBox(height: 8),
          _routeRow('🏆 Studio', 'GPT-4o → Claude 3.5 Sonnet → Grok-2 → Gemini Pro → Mistral', AppColors.secondary),
        ],
      ),
    );
  }

  Widget _routeRow(String plan, String chain, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(plan, style: AppTypography.labelMedium.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(chain, style: AppTypography.labelSmall.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final Map<String, dynamic> provider;
  const _ProviderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final color = Color(provider['color'] as int);
    final plans = List<String>.from(provider['plans'] as List);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        borderColor: color.withOpacity(0.2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Center(
                child: Text(provider['emoji'] as String, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(provider['name'] as String, style: AppTypography.titleMedium),
                      ),
                      // Plan badges
                      ...plans.map((p) => Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _planColor(p).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            p,
                            style: AppTypography.labelSmall.copyWith(color: _planColor(p)),
                          ),
                        ),
                      )),
                    ],
                  ),
                  Text(provider['company'] as String, style: AppTypography.bodySmall),
                  const SizedBox(height: 4),
                  Text(
                    provider['strengths'] as String,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Speed: ', style: AppTypography.labelSmall),
                      Text(provider['speed'] as String, style: const TextStyle(fontSize: 11)),
                      const SizedBox(width: 12),
                      Text('Quality: ', style: AppTypography.labelSmall),
                      Text(provider['quality'] as String, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _planColor(String plan) {
    switch (plan) {
      case 'Studio': return AppColors.secondary;
      case 'Creator': return AppColors.primary;
      default: return AppColors.textMuted;
    }
  }
}
