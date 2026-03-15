import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_card.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  static final _categories = [
    {
      'title': '🎬 AI Video Generators',
      'subtitle': 'Create stunning AI videos',
      'tools': [
        {'name': 'Runway', 'desc': 'Industry-leading AI video generation. 5s cinematic clips.', 'tag': 'Most Popular', 'color': 0xFF6C63FF, 'url': 'https://runwayml.com'},
        {'name': 'Kling AI', 'desc': 'High-quality 10s clips with exceptional motion. Best value.', 'tag': 'Best Value', 'color': 0xFF00E5CC, 'url': 'https://klingai.com'},
        {'name': 'Pika', 'desc': 'Fast fluid 3s clips. Great for social media content.', 'tag': 'Fast', 'color': 0xFFFF6B35, 'url': 'https://pika.art'},
        {'name': 'Sora', 'desc': 'OpenAI\'s flagship video model. 10-20s complex narratives.', 'tag': 'OpenAI', 'color': 0xFF10A37F, 'url': 'https://sora.com'},
        {'name': 'Luma AI', 'desc': '3D-aware video with stunning depth and realism.', 'tag': '3D Depth', 'color': 0xFFFF0080, 'url': 'https://lumalabs.ai'},
        {'name': 'Haiper', 'desc': 'Motion-first AI video with dynamic camera work.', 'tag': 'Motion', 'color': 0xFF2196F3, 'url': 'https://haiper.ai'},
      ],
    },
    {
      'title': '🖼️ AI Image Generators',
      'subtitle': 'Create character references & scene art',
      'tools': [
        {'name': 'Midjourney', 'desc': 'The gold standard for AI art. Unmatched aesthetic quality.', 'tag': '#1 AI Art', 'color': 0xFF5865F2, 'url': 'https://midjourney.com'},
        {'name': 'Leonardo AI', 'desc': 'Consistent characters across scenes. Creator-friendly.', 'tag': 'Character AI', 'color': 0xFFFFB830, 'url': 'https://leonardo.ai'},
        {'name': 'Stable Diffusion', 'desc': 'Open source, unlimited generations. Full control.', 'tag': 'Open Source', 'color': 0xFF4CAF7D, 'url': 'https://stability.ai'},
        {'name': 'DALL-E 3', 'desc': 'OpenAI\'s image model. Best at following instructions.', 'tag': 'OpenAI', 'color': 0xFF10A37F, 'url': 'https://openai.com/dall-e-3'},
      ],
    },
    {
      'title': '✂️ Video Editing Tools',
      'subtitle': 'Edit, cut, and polish your AI videos',
      'tools': [
        {'name': 'CapCut', 'desc': 'Free, powerful, AI-enhanced editing. Perfect for creators.', 'tag': 'Free', 'color': 0xFF000000, 'url': 'https://capcut.com'},
        {'name': 'DaVinci Resolve', 'desc': 'Professional-grade color grading and NLE.', 'tag': 'Professional', 'color': 0xFF1A1AFF, 'url': 'https://blackmagicdesign.com/products/davinciresolve'},
        {'name': 'Adobe Premiere', 'desc': 'Industry standard video editing suite.', 'tag': 'Industry', 'color': 0xFF9999FF, 'url': 'https://adobe.com/premiere'},
      ],
    },
    {
      'title': '🎙️ AI Voice-Over Tools',
      'subtitle': 'Convert your scripts to speech',
      'tools': [
        {'name': 'ElevenLabs', 'desc': 'Most realistic AI voices. Perfect for faceless content.', 'tag': 'Best AI Voice', 'color': 0xFFFF6B35, 'url': 'https://elevenlabs.io'},
        {'name': 'Murf AI', 'desc': '120+ voices in 20 languages. Studio quality output.', 'tag': 'Multilingual', 'color': 0xFF6C63FF, 'url': 'https://murf.ai'},
        {'name': 'Play.ht', 'desc': 'Realistic AI voices with emotional control.', 'tag': 'Emotional', 'color': 0xFF00E5CC, 'url': 'https://play.ht'},
      ],
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
                  onPressed: () => context.go('/home'),
                ),
                title: Text('Recommended Tools', style: AppTypography.headlineMedium),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      if (i >= _categories.length) return null;
                      final category = _categories[i];
                      return _CategorySection(category: category)
                          .animate(delay: Duration(milliseconds: i * 100))
                          .fadeIn()
                          .slideY(begin: 0.1);
                    },
                    childCount: _categories.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final Map<String, dynamic> category;
  const _CategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        Text(category['title'] as String, style: AppTypography.headlineMedium),
        Text(category['subtitle'] as String, style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        ...(category['tools'] as List).asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ToolCard(tool: e.value as Map<String, dynamic>)
                .animate(delay: Duration(milliseconds: e.key * 60))
                .fadeIn()
                .slideX(begin: -0.05),
          ),
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  final Map<String, dynamic> tool;
  const _ToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    final color = Color(tool['color'] as int);
    return AppCard(
      onTap: () => launchUrl(Uri.parse(tool['url'] as String), mode: LaunchMode.externalApplication),
      borderColor: color.withOpacity(0.2),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                (tool['name'] as String).substring(0, 1),
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(tool['name'] as String, style: AppTypography.titleMedium),
                    if (tool['tag'] != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          tool['tag'] as String,
                          style: AppTypography.labelSmall.copyWith(color: color),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(tool['desc'] as String, style: AppTypography.bodySmall),
              ],
            ),
          ),
          Icon(Icons.open_in_new_rounded, size: 16, color: color.withOpacity(0.6)),
        ],
      ),
    );
  }
}
