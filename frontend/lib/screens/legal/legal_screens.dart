import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

// ─── Shared Legal Layout ───────────────────────────────────────────────────────
class _LegalLayout extends StatelessWidget {
  final String title;
  final String updated;
  final List<Widget> children;

  const _LegalLayout({
    required this.title,
    required this.updated,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Nav ────────────────────────────────────────────────────────────
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.95),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(children: [
              GestureDetector(
                onTap: () => context.go('/'),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                        child: Text('🎬', style: TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (b) =>
                        AppColors.primaryGradient.createShader(b),
                    child: Text('PromptReel AI',
                        style: AppTypography.headlineMedium
                            .copyWith(color: Colors.white)),
                  ),
                ]),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/'),
                child: Text('← Back to Home',
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.textMuted)),
              ),
            ]),
          ),

          // ── Content ────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTypography.displaySmall
                              .copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(updated,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textMuted)),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      ...children,
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Footer ─────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 40, vertical: 20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('© 2025 PromptReel AI · chAs Tech Group',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textMuted)),
                Row(children: [
                  _Link('Home', '/', context),
                  const SizedBox(width: 24),
                  _Link('Privacy Policy', '/privacy', context),
                  const SizedBox(width: 24),
                  _Link('Terms of Service', '/terms', context),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  final String label, path;
  final BuildContext ctx;
  const _Link(this.label, this.path, this.ctx);

  @override
  Widget build(BuildContext context) {
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

class _H2 extends StatelessWidget {
  final String text;
  const _H2(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 36, bottom: 12),
    child: Text(text, style: AppTypography.headlineMedium
        .copyWith(color: AppColors.primary)),
  );
}

class _P extends StatelessWidget {
  final String text;
  const _P(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Text(text, style: AppTypography.bodySmall
        .copyWith(color: Colors.white.withOpacity(0.8), height: 1.7)),
  );
}

class _UL extends StatelessWidget {
  final List<String> items;
  const _UL(this.items);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16, left: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: TextStyle(color: AppColors.primary)),
            Expanded(child: Text(item, style: AppTypography.bodySmall
                .copyWith(color: Colors.white.withOpacity(0.8), height: 1.6))),
          ],
        ),
      )).toList(),
    ),
  );
}

// ─── Privacy Screen ───────────────────────────────────────────────────────────
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalLayout(
      title: 'Privacy Policy',
      updated: 'Last updated: March 2025 · Effective: March 2025',
      children: [
        const _P('Welcome to PromptReel AI ("we", "our", or "us"), operated by chAs Tech Group. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and website. Please read this policy carefully.'),

        const _H2('1. Information We Collect'),
        const _P('We collect the following types of information:'),
        const _UL([
          'Account Information: Name, email address, and password when you register',
          'Usage Data: Features used, video plans generated, content types selected',
          'Device Information: Device type, OS version, app version, unique device identifiers',
          'Payment Information: Transaction references and plan status (we do NOT store card details — payments are processed by Flutterwave)',
          'Log Data: IP address, access times, pages viewed, app crashes',
        ]),

        const _H2('2. How We Use Your Information'),
        const _P('We use collected information to:'),
        const _UL([
          'Provide, operate, and maintain the Service',
          'Process payments and manage subscriptions',
          'Send transactional emails (verification, password reset)',
          'Improve and personalize your experience',
          'Monitor usage patterns to improve AI generation quality',
          'Comply with legal obligations',
          'Detect and prevent fraud or abuse',
        ]),

        const _H2('3. Advertising'),
        const _P('We use Google AdMob (in-app) and Google AdSense (website) to display advertisements. These services may collect and use data to show personalized ads based on your interests. You can opt out of personalized advertising in your device settings.'),
        const _UL([
          'Google AdMob Privacy Policy: policies.google.com/privacy',
          'Free plan users see ads. Creator and Studio plan subscribers are ad-free in the app.',
        ]),

        const _H2('4. Data Sharing'),
        const _P('We do not sell your personal data. We may share data with:'),
        const _UL([
          'AI Providers: OpenAI, Anthropic, Google, Groq, Mistral, DeepSeek — for AI generation (prompts only, no personal data)',
          'Flutterwave: Payment processing',
          'Supabase: Secure database hosting',
          'Google: Analytics and advertising services',
          'Render: Backend hosting',
          'Legal authorities: When required by law',
        ]),

        const _H2('5. Data Retention'),
        const _P('We retain your account data for as long as your account is active. You may request deletion at any time by contacting us at support@promptreel.ai. Generated video plans are stored until you delete them or close your account.'),

        const _H2('6. Data Security'),
        const _P('We implement industry-standard security measures including:'),
        const _UL([
          'HTTPS/TLS encryption for all data in transit',
          'Encrypted password storage (bcrypt)',
          'JWT token authentication with expiry',
          'Supabase row-level security policies',
          'No plain-text storage of sensitive data',
        ]),

        const _H2('7. Children\'s Privacy'),
        const _P('PromptReel AI is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you believe we have collected information from a child, please contact us immediately.'),

        const _H2('8. Your Rights'),
        const _P('Depending on your location, you may have rights to:'),
        const _UL([
          'Access your personal data',
          'Correct inaccurate data',
          'Request deletion of your data',
          'Opt out of personalized advertising',
          'Data portability',
        ]),
        const _P('To exercise these rights, contact us at support@promptreel.ai.'),

        const _H2('9. Changes to This Policy'),
        const _P('We may update this Privacy Policy from time to time. We will notify you of significant changes via email or in-app notification. Continued use of the Service after changes constitutes acceptance.'),

        const _H2('10. Contact Us'),
        const _P('If you have questions about this Privacy Policy, please contact us:'),
        const _UL([
          'Email: support@promptreel.ai',
          'Website: promptreel.ai',
          'Company: chAs Tech Group',
        ]),
      ],
    );
  }
}

// ─── Terms Screen ─────────────────────────────────────────────────────────────
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalLayout(
      title: 'Terms of Service',
      updated: 'Last updated: March 2025 · Effective: March 2025',
      children: [
        const _P('These Terms of Service ("Terms") govern your access to and use of PromptReel AI ("Service"), operated by chAs Tech Group. By using the Service, you agree to these Terms.'),

        const _H2('1. Acceptance of Terms'),
        const _P('By creating an account or using PromptReel AI in any way, you confirm that you are at least 13 years old, have read and agree to these Terms, and have the authority to enter into this agreement.'),

        const _H2('2. Description of Service'),
        const _P('PromptReel AI is an AI-powered video production planning platform that generates:'),
        const _UL([
          'Video scripts and narration',
          'Scene breakdowns and visual descriptions',
          'Video AI prompts for tools like Kling, Runway, and Pika',
          'SEO packs including titles, descriptions, and hashtags',
          'Voice-over scripts with timing markers',
          'Thumbnail prompts and production guides',
        ]),
        const _P('Important: PromptReel AI does NOT generate actual videos. It generates production plans and prompts that you use with third-party video generation tools.'),

        const _H2('3. User Accounts'),
        const _P('You are responsible for maintaining the confidentiality of your account credentials and all activity that occurs under your account. We reserve the right to suspend or terminate accounts that violate these Terms.'),

        const _H2('4. Subscription Plans and Payments'),
        const _UL([
          'Free Plan: 3 video plans per day, up to 5-minute videos, with ads',
          'Creator Plan: \$15/month — unlimited plans, up to 20-minute videos, no ads',
          'Studio Plan: \$35/month — everything in Creator plus GPT-4o, Claude 3.5 Sonnet, team features',
        ]),
        const _P('Payments are processed by Flutterwave. Subscriptions are monthly and auto-renew unless cancelled. We do not offer refunds for partial billing periods.'),

        const _H2('5. Acceptable Use'),
        const _P('You agree NOT to use PromptReel AI to:'),
        const _UL([
          'Generate content that is illegal, harmful, threatening, or abusive',
          'Create content that infringes on intellectual property rights',
          'Generate misinformation or deliberately deceptive content',
          'Attempt to reverse engineer or exploit the Service',
          'Resell or redistribute the Service without permission',
          'Use automated bots to abuse the free plan limits',
        ]),

        const _H2('6. Intellectual Property'),
        const _P('The content you generate using PromptReel AI is yours to use. The PromptReel AI platform, code, design, branding, and underlying technology are owned by chAs Tech Group and protected by intellectual property laws.'),

        const _H2('7. Disclaimer of Warranties'),
        const _P('THE SERVICE IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND. WE DO NOT GUARANTEE THAT THE SERVICE WILL BE UNINTERRUPTED OR ERROR-FREE. AI-GENERATED CONTENT MAY CONTAIN INACCURACIES.'),

        const _H2('8. Limitation of Liability'),
        const _P('TO THE MAXIMUM EXTENT PERMITTED BY LAW, CHAS TECH GROUP SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING FROM YOUR USE OF THE SERVICE.'),

        const _H2('9. Termination'),
        const _P('We may suspend or terminate your access to the Service at any time for violation of these Terms. You may delete your account at any time by contacting us at support@promptreel.ai.'),

        const _H2('10. Changes to Terms'),
        const _P('We reserve the right to modify these Terms at any time. We will notify you of material changes via email or in-app notification. Continued use of the Service after changes constitutes your acceptance.'),

        const _H2('11. Contact Us'),
        const _UL([
          'Email: support@promptreel.ai',
          'Website: promptreel.ai',
          'Company: chAs Tech Group',
        ]),
      ],
    );
  }
}

