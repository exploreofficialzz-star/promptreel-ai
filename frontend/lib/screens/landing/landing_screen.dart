import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(String section) {
    // Simple scroll by offset for each section
    final offsets = {
      'features':    600.0,
      'how':         1200.0,
      'pricing':     2000.0,
      'testimonials':2600.0,
    };
    _scrollController.animateTo(
      offsets[section] ?? 0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Top Nav ─────────────────────────────────────────────────────
          _WebNav(isWide: isWide, onNav: _scrollTo),
          // ── Content ─────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _HeroSection(isWide: isWide),
                  _FeaturesSection(),
                  _HowItWorksSection(),
                  _AiModelsSection(),
                  _PricingSection(),
                  _TestimonialsSection(),
                  _CtaSection(),
                  _WebFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nav ──────────────────────────────────────────────────────────────────────
class _WebNav extends StatelessWidget {
  final bool isWide;
  final Function(String) onNav;
  const _WebNav({required this.isWide, required this.onNav});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.95),
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          // Logo
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('🎬', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
              child: Text('PromptReel AI',
                  style: AppTypography.headlineMedium.copyWith(color: Colors.white)),
            ),
          ]),
          const Spacer(),
          if (isWide) ...[
            _NavLink('Features',     () => onNav('features')),
            _NavLink('How It Works', () => onNav('how')),
            _NavLink('Pricing',      () => onNav('pricing')),
            _NavLink('Reviews',      () => onNav('testimonials')),
            const SizedBox(width: 24),
          ],
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text('Sign In',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.textMuted)),
          ),
          const SizedBox(width: 8),
          AppButton(
            label: 'Get Started Free',
            onPressed: () => context.go('/register'),
            variant: AppButtonVariant.primary,
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton(
        onPressed: onTap,
        child: Text(label,
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.textMuted)),
      ),
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final bool isWide;
  const _HeroSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24,
        vertical: 80,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.05),
            Colors.transparent,
          ],
        ),
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _HeroLeft()),
                const SizedBox(width: 64),
                Expanded(child: _HeroMockup()),
              ],
            )
          : Column(children: [_HeroLeft(), const SizedBox(height: 48), _HeroMockup()]),
    );
  }
}

class _HeroLeft extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Text('✦ AI-Powered Video Production',
              style: AppTypography.labelMedium.copyWith(color: AppColors.primary)),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 20),
        Text(
          'Turn Ideas Into\nComplete Video\nProduction Plans',
          style: AppTypography.displaySmall.copyWith(
            fontSize: 52, fontWeight: FontWeight.w900, height: 1.1,
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
          child: Text('In Seconds.',
              style: AppTypography.displaySmall.copyWith(
                fontSize: 52, fontWeight: FontWeight.w900,
                color: Colors.white, height: 1.1,
              )),
        ).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 20),
        Text(
          'Generate full scripts, scene breakdowns, video prompts,\n'
          'SEO packs, hashtags, and more. Used by 10,000+ creators.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, height: 1.7),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 36),
        Row(children: [
          AppButton(
            label: '🚀 Start for Free',
            onPressed: () => GoRouter.of(context).go('/register'),
            fullWidth: false,
          ),
          const SizedBox(width: 16),
          AppButton(
            label: 'Sign In →',
            onPressed: () => GoRouter.of(context).go('/login'),
            variant: AppButtonVariant.outline,
            fullWidth: false,
          ),
        ]).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 40),
        Row(children: [
          _StatItem('50K+', 'Plans Generated'),
          const SizedBox(width: 40),
          _StatItem('10K+', 'Active Creators'),
          const SizedBox(width: 40),
          _StatItem('9', 'AI Providers'),
        ]).animate().fadeIn(delay: 600.ms),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String num;
  final String label;
  const _StatItem(this.num, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ShaderMask(
        shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
        child: Text(num, style: AppTypography.headlineLarge
            .copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
      Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
    ]);
  }
}

class _HeroMockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _Dot(Colors.red), const SizedBox(width: 6),
            _Dot(Colors.orange), const SizedBox(width: 6),
            _Dot(Colors.green), const SizedBox(width: 12),
            Text('PromptReel AI', style: AppTypography.labelMedium),
          ]),
          const SizedBox(height: 20),
          _MockupRow('📋', 'Full Narration Script', 'Complete word-for-word • Scene markers'),
          _MockupRow('🎬', '30 Scene Breakdown', 'Camera work • Mood • Transitions'),
          _MockupRow('🎥', 'Video AI Prompts', 'Kling • Runway • Pika • Sora'),
          _MockupRow('🔍', 'YouTube SEO Pack', 'Title • Description • 30 Hashtags'),
          _MockupRow('🎙️', 'Voice-Over Script', 'Timed [MM:SS] markers • ElevenLabs ready'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Center(
              child: Text('✦ Generate Video Plan',
                  style: AppTypography.labelLarge.copyWith(color: Colors.black)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.2);
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);
  @override
  Widget build(BuildContext context) =>
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _MockupRow extends StatelessWidget {
  final String icon, title, sub;
  const _MockupRow(this.icon, this.title, this.sub);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.labelMedium),
            Text(sub, style: AppTypography.labelSmall
                .copyWith(color: AppColors.textMuted)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.12),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text('Ready', style: AppTypography.labelSmall
              .copyWith(color: AppColors.success, fontSize: 10)),
        ),
      ]),
    );
  }
}

// ─── Features ─────────────────────────────────────────────────────────────────
class _FeaturesSection extends StatelessWidget {
  static const _features = [
    ('📋', 'Full Narration Script',   'Complete word-for-word script with [SCENE] markers. Ready to record immediately.'),
    ('🎬', 'Scene Breakdown',         'Every scene with visual descriptions, camera angles, mood, and transitions.'),
    ('🎥', 'Video AI Prompts',        'Optimized prompts for Kling, Runway, Pika, Sora — with character consistency.'),
    ('🔍', 'YouTube SEO Pack',        'Viral title, description, 20 tags, thumbnail prompt — optimized for discovery.'),
    ('#️⃣', '30 Hashtags',            'Primary, secondary, niche, and trending hashtags across all platforms.'),
    ('🎙️', 'Voice-Over Script',       'Timed narration with [MM:SS] markers. Ready for ElevenLabs or any TTS tool.'),
    ('🖼️', 'Thumbnail Prompt',        'Detailed thumbnail description with character, text overlay, and composition.'),
    ('📦', 'ZIP Export',              'Download everything in one ZIP — scripts, prompts, SRT subtitles, SEO pack.'),
    ('🤖', '9 AI Providers',          'GPT-4o, Claude, Gemini, Grok, Mistral, DeepSeek — smart fallback for reliability.'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24, vertical: 80),
      child: Column(children: [
        _SectionLabel('⚡ Everything You Need'),
        const SizedBox(height: 12),
        _SectionTitle('One Plan. ', 'Everything Included.'),
        const SizedBox(height: 12),
        Text('PromptReel AI generates a complete production package — not just a script.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center),
        const SizedBox(height: 56),
        Wrap(
          spacing: 20, runSpacing: 20,
          children: _features.map((f) => SizedBox(
            width: isWide ? 340 : double.infinity,
            child: _FeatureCard(f.$1, f.$2, f.$3),
          )).toList(),
        ),
      ]),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final String icon, title, desc;
  const _FeatureCard(this.icon, this.title, this.desc);

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? AppColors.primary.withOpacity(0.4)
                : AppColors.border,
          ),
          boxShadow: _hovered ? AppShadows.glow : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(widget.title, style: AppTypography.titleMedium),
          const SizedBox(height: 6),
          Text(widget.desc, style: AppTypography.bodySmall
              .copyWith(color: AppColors.textMuted)),
        ]),
      ),
    );
  }
}

// ─── How It Works ─────────────────────────────────────────────────────────────
class _HowItWorksSection extends StatelessWidget {
  static const _steps = [
    ('1', 'Enter Your Idea',       'Type any video topic, story, or concept. The more specific the better.'),
    ('2', 'Choose Settings',       'Select content type, platform, duration, AI generator, and style options.'),
    ('3', 'AI Generates Plan',     'Our AI creates your complete production package in 30-90 seconds.'),
    ('4', 'Create Your Video',     'Use the prompts with Kling, Runway, or Pika. Edit with CapCut or DaVinci.'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24, vertical: 80),
      color: AppColors.surface,
      child: Column(children: [
        _SectionLabel('⚙️ Simple Process'),
        const SizedBox(height: 12),
        _SectionTitle('From Idea to ', 'Production Plan'),
        const SizedBox(height: 56),
        isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _steps.asMap().entries.map((e) =>
                Expanded(child: _StepCard(e.value.$1, e.value.$2, e.value.$3,
                    isLast: e.key == _steps.length - 1))).toList(),
            )
          : Column(
              children: _steps.map((s) =>
                Padding(padding: const EdgeInsets.only(bottom: 20),
                  child: _StepCard(s.$1, s.$2, s.$3, isLast: false))).toList(),
            ),
      ]),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String num, title, desc;
  final bool isLast;
  const _StepCard(this.num, this.title, this.desc, {required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(num,
                style: AppTypography.headlineMedium
                    .copyWith(color: Colors.black))),
          ),
          if (!isLast) ...[
            const SizedBox(width: 8),
            Text('→', style: TextStyle(
                color: AppColors.primary.withOpacity(0.4), fontSize: 20)),
          ],
        ]),
        const SizedBox(height: 16),
        Text(title, style: AppTypography.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(desc, style: AppTypography.bodySmall
            .copyWith(color: AppColors.textMuted), textAlign: TextAlign.center),
      ]),
    );
  }
}

// ─── AI Models ────────────────────────────────────────────────────────────────
class _AiModelsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24, vertical: 80),
      child: Column(children: [
        _SectionLabel('🤖 Powered By'),
        const SizedBox(height: 12),
        _SectionTitle('The World\'s Best ', 'AI Models'),
        const SizedBox(height: 56),
        Wrap(spacing: 20, runSpacing: 20, children: [
          _ModelCard('Free Plan', 'Gemini 2.0 Flash',
              'Fast capable free models',
              ['Gemini Flash', 'Groq Llama 3.3', 'DeepSeek-V3', 'Together Qwen', 'OpenRouter'],
              AppColors.textMuted, isWide),
          _ModelCard('Creator Plan', 'GPT-4o-mini',
              'Pro models for richer output',
              ['GPT-4o-mini', 'Grok-2', 'Gemini 1.5 Pro', 'Mistral Large', 'DeepSeek-V3'],
              AppColors.primary, isWide),
          _ModelCard('Studio Plan', 'GPT-4o',
              'Frontier models for best quality',
              ['GPT-4o', 'Claude 3.5 Sonnet', 'Grok-2', 'Gemini 1.5 Pro', 'Mistral Large'],
              const Color(0xFF00E5CC), isWide),
        ]),
      ]),
    );
  }
}

class _ModelCard extends StatelessWidget {
  final String badge, name, desc;
  final List<String> chips;
  final Color color;
  final bool isWide;
  const _ModelCard(this.badge, this.name, this.desc,
      this.chips, this.color, this.isWide);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isWide ? 340 : double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(badge, style: AppTypography.labelSmall
              .copyWith(color: color, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        Text(name, style: AppTypography.headlineMedium),
        const SizedBox(height: 4),
        Text(desc, style: AppTypography.bodySmall
            .copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 16),
        Wrap(spacing: 6, runSpacing: 6, children: chips.map((c) =>
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(c, style: AppTypography.labelSmall
                .copyWith(color: AppColors.textMuted)),
          )).toList()),
      ]),
    );
  }
}

// ─── Pricing ──────────────────────────────────────────────────────────────────
class _PricingSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24, vertical: 80),
      color: AppColors.surface,
      child: Column(children: [
        _SectionLabel('💎 Simple Pricing'),
        const SizedBox(height: 12),
        _SectionTitle('Start Free. ', 'Upgrade Anytime.'),
        const SizedBox(height: 8),
        Text('No contracts. Cancel anytime. Prices in USD.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 56),
        Wrap(
          spacing: 20, runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [
            _PriceCard(
              name: 'Free', price: r'$0', period: 'forever',
              desc: 'Perfect for trying out PromptReel AI',
              color: AppColors.textMuted,
              features: ['3 video plans per day', 'Up to 5-minute videos',
                'All 10 content types', 'All AI generators', 'Basic export'],
              missing: ['10 & 20 min videos', 'ZIP export', 'No ads'],
              isPopular: false,
              buttonLabel: 'Get Started Free',
              onTap: () => GoRouter.of(context).go('/register'),
              isWide: isWide,
            ),
            _PriceCard(
              name: 'Creator', price: r'$15', period: '/month',
              desc: 'For serious content creators',
              color: AppColors.primary,
              features: ['Unlimited video plans', 'Up to 20-minute videos',
                'No ads — ever', 'Full ZIP export', 'Voice-over scripts',
                'Advanced AI prompts', 'Priority AI processing', 'GPT-4o-mini + Grok-2'],
              missing: [],
              isPopular: true,
              buttonLabel: 'Get Creator Plan',
              onTap: () => GoRouter.of(context).go('/register'),
              isWide: isWide,
            ),
            _PriceCard(
              name: 'Studio', price: r'$35', period: '/month',
              desc: 'For agencies and power users',
              color: const Color(0xFF00E5CC),
              features: ['Everything in Creator', 'GPT-4o + Claude 3.5 Sonnet',
                'Team collaboration (5 seats)', 'Priority AI', 'API access',
                'Custom branding', 'Dedicated support'],
              missing: [],
              isPopular: false,
              buttonLabel: 'Get Studio Plan',
              onTap: () => GoRouter.of(context).go('/register'),
              isWide: isWide,
            ),
          ],
        ),
      ]),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String name, price, period, desc, buttonLabel;
  final Color color;
  final List<String> features, missing;
  final bool isPopular, isWide;
  final VoidCallback onTap;

  const _PriceCard({
    required this.name, required this.price, required this.period,
    required this.desc, required this.color, required this.features,
    required this.missing, required this.isPopular, required this.buttonLabel,
    required this.onTap, required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: isWide ? 320 : double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isPopular
                ? color.withOpacity(0.06)
                : AppColors.background,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isPopular ? color.withOpacity(0.5) : AppColors.border,
              width: isPopular ? 1.5 : 1,
            ),
            boxShadow: isPopular
                ? [BoxShadow(color: color.withOpacity(0.15),
                    blurRadius: 40, spreadRadius: -5)]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.headlineMedium),
              const SizedBox(height: 8),
              RichText(text: TextSpan(children: [
                TextSpan(text: price,
                    style: AppTypography.displaySmall
                        .copyWith(color: color, fontSize: 40)),
                TextSpan(text: period,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textMuted)),
              ])),
              const SizedBox(height: 8),
              Text(desc, style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f, style: AppTypography.bodySmall)),
                ]),
              )),
              ...missing.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Icon(Icons.remove_circle_outline,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted))),
                ]),
              )),
              const SizedBox(height: 20),
              AppButton(
                label: buttonLabel,
                onPressed: onTap,
                fullWidth: true,
                variant: isPopular
                    ? AppButtonVariant.primary
                    : AppButtonVariant.outline,
              ),
            ],
          ),
        ),
        if (isPopular)
          Positioned(
            top: -14, left: 0, right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text('⭐ MOST POPULAR',
                    style: AppTypography.labelSmall.copyWith(
                        color: Colors.black, letterSpacing: 1)),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Testimonials ─────────────────────────────────────────────────────────────
class _TestimonialsSection extends StatelessWidget {
  static const _reviews = [
    ('JK', 'James K.', 'YouTube Creator • 250K subs',
      '"I used to spend 4-6 hours planning each video. Now I do it in 2 minutes. The scene breakdown and video prompts are exactly what I need for Kling AI."'),
    ('AS', 'Amara S.', 'TikTok Creator',
      '"The SEO pack alone is worth it. My videos started ranking way higher after using the optimized titles and descriptions from PromptReel AI."'),
    ('MR', 'Marcus R.', 'AI Video Producer',
      '"The character consistency in video prompts is incredible. My AI characters look the same across all 30 scenes. Game changer for storytelling."'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24, vertical: 80),
      child: Column(children: [
        _SectionLabel('💬 Loved By Creators'),
        const SizedBox(height: 12),
        _SectionTitle('What ', 'Creators Say'),
        const SizedBox(height: 56),
        Wrap(spacing: 20, runSpacing: 20, children: _reviews.map((r) =>
          SizedBox(
            width: isWide ? 340 : double.infinity,
            child: _ReviewCard(r.$1, r.$2, r.$3, r.$4),
          )).toList()),
      ]),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String initials, name, role, review;
  const _ReviewCard(this.initials, this.name, this.role, this.review);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.star_rounded, color: AppColors.primary, size: 16),
          Icon(Icons.star_rounded, color: AppColors.primary, size: 16),
          Icon(Icons.star_rounded, color: AppColors.primary, size: 16),
          Icon(Icons.star_rounded, color: AppColors.primary, size: 16),
          Icon(Icons.star_rounded, color: AppColors.primary, size: 16),
        ]),
        const SizedBox(height: 12),
        Text(review, style: AppTypography.bodySmall
            .copyWith(color: Colors.white.withOpacity(0.85),
                fontStyle: FontStyle.italic, height: 1.7)),
        const SizedBox(height: 16),
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient, shape: BoxShape.circle),
            child: Center(child: Text(initials,
                style: AppTypography.labelMedium
                    .copyWith(color: Colors.black))),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppTypography.labelMedium),
            Text(role, style: AppTypography.labelSmall
                .copyWith(color: AppColors.textMuted)),
          ]),
        ]),
      ]),
    );
  }
}

// ─── CTA ──────────────────────────────────────────────────────────────────────
class _CtaSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isWide ? 80 : 24, vertical: 40),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.surfaceElevated],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Text('🚀 Ready to Start?',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.primary)),
        ),
        const SizedBox(height: 20),
        Text('Create Your First\nAI Video Plan Free',
            style: AppTypography.displaySmall
                .copyWith(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
          child: Text('No credit card required.',
              style: AppTypography.bodyLarge
                  .copyWith(color: Colors.white)),
        ),
        const SizedBox(height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          AppButton(
            label: '🚀 Start for Free',
            onPressed: () => GoRouter.of(context).go('/register'),
            fullWidth: false,
          ),
          const SizedBox(width: 16),
          AppButton(
            label: 'View Pricing →',
            onPressed: () {},
            variant: AppButtonVariant.outline,
            fullWidth: false,
          ),
        ]),
      ]),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────
class _WebFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 48),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) =>
                      AppColors.primaryGradient.createShader(b),
                  child: Text('PromptReel AI',
                      style: AppTypography.headlineMedium
                          .copyWith(color: Colors.white)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Turn simple ideas into complete AI video\nproduction plans. Scripts, prompts, SEO and more.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                Text('Made with ❤️ by chAs Tech Group',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textMuted)),
              ],
            )),
            _FooterCol('Product', [
              ('Features', '/'),
              ('Pricing', '/'),
              ('Download App', '/'),
            ]),
            _FooterCol('Legal', [
              ('Privacy Policy', '/privacy'),
              ('Terms of Service', '/terms'),
            ]),
            _FooterCol('Support', [
              ('Contact Us', '/'),
              ('support@promptreel.ai', '/'),
            ]),
          ],
        ),
        const SizedBox(height: 40),
        const Divider(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('© 2025 PromptReel AI · chAs Tech Group',
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.textMuted)),
            Row(children: [
              _FooterLink('Privacy Policy', '/privacy', context),
              const SizedBox(width: 24),
              _FooterLink('Terms of Service', '/terms', context),
            ]),
          ],
        ),
      ]),
    );
  }
}

class _FooterCol extends StatelessWidget {
  final String heading;
  final List<(String, String)> links;
  const _FooterCol(this.heading, this.links);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(heading, style: AppTypography.labelLarge),
        const SizedBox(height: 16),
        ...links.map((l) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _FooterLink(l.$1, l.$2, context),
        )),
      ]),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label, path;
  final BuildContext ctx;
  const _FooterLink(this.label, this.path, this.ctx);

  @override
  Widget build(BuildContext ctx2) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => GoRouter.of(ctx).go(path),
        child: Text(label, style: AppTypography.labelSmall
            .copyWith(color: AppColors.textMuted)),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(label, style: AppTypography.labelMedium
          .copyWith(color: AppColors.primary)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String normal, gold;
  const _SectionTitle(this.normal, this.gold);

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(children: [
        TextSpan(text: normal,
            style: AppTypography.displaySmall
                .copyWith(fontWeight: FontWeight.w900)),
        WidgetSpan(child: ShaderMask(
          shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
          child: Text(gold, style: AppTypography.displaySmall
              .copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
        )),
      ]),
    );
  }
}

