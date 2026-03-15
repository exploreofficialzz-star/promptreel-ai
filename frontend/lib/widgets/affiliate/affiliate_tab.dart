import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

// ── Affiliate Tool Data ────────────────────────────────────────────────────
class AffiliateTool {
  final String name;
  final String tagline;
  final String emoji;
  final String url;
  final Color accentColor;
  final String? badge;
  final String category;

  const AffiliateTool({
    required this.name,
    required this.tagline,
    required this.emoji,
    required this.url,
    required this.accentColor,
    this.badge,
    required this.category,
  });
}

const _videoTools = [
  AffiliateTool(name: 'Runway', tagline: 'Gen-3 Alpha — cinematic AI video', emoji: '🎬', url: 'https://runwayml.com', accentColor: Color(0xFF6C63FF), badge: 'Popular', category: 'video'),
  AffiliateTool(name: 'Kling AI', tagline: '10s clips, best value generator', emoji: '🎥', url: 'https://klingai.com', accentColor: Color(0xFF00E5CC), badge: 'Best Value', category: 'video'),
  AffiliateTool(name: 'Pika', tagline: 'Fast 3s clips for social content', emoji: '⚡', url: 'https://pika.art', accentColor: Color(0xFFFF6B35), category: 'video'),
  AffiliateTool(name: 'Luma AI', tagline: 'Dream Machine — 3D-aware video', emoji: '🌀', url: 'https://lumalabs.ai', accentColor: Color(0xFFFF0080), category: 'video'),
];

const _imageTools = [
  AffiliateTool(name: 'Leonardo AI', tagline: 'Consistent characters & scenes', emoji: '🖼️', url: 'https://leonardo.ai', accentColor: Color(0xFFFFB830), badge: 'Recommended', category: 'image'),
  AffiliateTool(name: 'Midjourney', tagline: '#1 AI art quality worldwide', emoji: '🎨', url: 'https://midjourney.com', accentColor: Color(0xFF5865F2), category: 'image'),
];

const _editingTools = [
  AffiliateTool(name: 'CapCut', tagline: 'Free AI-powered video editing', emoji: '✂️', url: 'https://capcut.com', accentColor: Color(0xFF4CAF7D), badge: 'Free', category: 'editing'),
  AffiliateTool(name: 'ElevenLabs', tagline: 'Realistic AI voices for your script', emoji: '🎙️', url: 'https://elevenlabs.io', accentColor: Color(0xFFFF6B35), category: 'voice'),
];

// ── 1. FLOATING DISMISSIBLE BANNER ─────────────────────────────────────────
/// A floating ribbon at the bottom of the screen.
/// Rotates through tools every few seconds. User can dismiss permanently per session.
class FloatingAffiliateBanner extends StatefulWidget {
  const FloatingAffiliateBanner({super.key});

  @override
  State<FloatingAffiliateBanner> createState() => _FloatingAffiliateBannerState();
}

class _FloatingAffiliateBannerState extends State<FloatingAffiliateBanner> {
  static bool _dismissed = false; // session-level dismiss
  int _toolIndex = 0;
  late final List<AffiliateTool> _tools = [..._videoTools, ..._imageTools, ..._editingTools];

  @override
  void initState() {
    super.initState();
    _startRotation();
  }

  void _startRotation() async {
    while (mounted && !_dismissed) {
      await Future.delayed(const Duration(seconds: 6));
      if (mounted && !_dismissed) {
        setState(() => _toolIndex = (_toolIndex + 1) % _tools.length);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final tool = _tools[_toolIndex];

    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: _AffiliateRibbon(
        tool: tool,
        onDismiss: () => setState(() => _dismissed = true),
      ).animate(key: ValueKey(_toolIndex)).fadeIn(duration: 400.ms).slideY(begin: 0.3),
    );
  }
}

class _AffiliateRibbon extends StatelessWidget {
  final AffiliateTool tool;
  final VoidCallback onDismiss;
  const _AffiliateRibbon({required this.tool, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: tool.accentColor.withOpacity(0.4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            // Emoji + accent bar
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: tool.accentColor,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(AppRadius.lg - 1), bottomLeft: Radius.circular(AppRadius.lg - 1)),
              ),
            ),
            const SizedBox(width: 12),
            Text(tool.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(tool.name, style: AppTypography.titleMedium),
                      if (tool.badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: tool.accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(tool.badge!, style: AppTypography.labelSmall.copyWith(color: tool.accentColor)),
                        ),
                      ],
                    ],
                  ),
                  Text(tool.tagline, style: AppTypography.bodySmall),
                ],
              ),
            ),
            // Try button
            GestureDetector(
              onTap: () => launchUrl(Uri.parse(tool.url), mode: LaunchMode.externalApplication),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tool.accentColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text('Try Free', style: AppTypography.labelMedium.copyWith(color: Colors.black)),
              ),
            ),
            // Dismiss button
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
              onPressed: onDismiss,
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }
}

// ── 2. INLINE AFFILIATE CARD ──────────────────────────────────────────────
/// Inline card shown within content sections (results page, etc.).
/// Has "Not interested" option to hide.
class InlineAffiliateCard extends StatefulWidget {
  final AffiliateTool tool;
  final String contextLabel; // e.g. "For your Runway prompts:"
  const InlineAffiliateCard({super.key, required this.tool, this.contextLabel = ''});

  @override
  State<InlineAffiliateCard> createState() => _InlineAffiliateCardState();
}

class _InlineAffiliateCardState extends State<InlineAffiliateCard> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.tool.accentColor.withOpacity(0.06), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: widget.tool.accentColor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Context label + dismiss
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
            child: Row(
              children: [
                if (widget.contextLabel.isNotEmpty)
                  Expanded(
                    child: Text(
                      widget.contextLabel,
                      style: AppTypography.labelSmall.copyWith(color: widget.tool.accentColor),
                    ),
                  )
                else
                  const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _dismissed = true),
                  child: Text('✕ Hide', style: AppTypography.labelSmall),
                ),
              ],
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Row(
              children: [
                Text(widget.tool.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.tool.name, style: AppTypography.titleMedium),
                      Text(widget.tool.tagline, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => launchUrl(Uri.parse(widget.tool.url), mode: LaunchMode.externalApplication),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.tool.accentColor,
                    side: BorderSide(color: widget.tool.accentColor),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Try →'),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── 3. HORIZONTAL SCROLLABLE TOOLS ROW ───────────────────────────────────
/// Used on home screen — quick horizontal scroll of recommended tools.
class AffiliateToolsRow extends StatelessWidget {
  final String? title;
  final List<AffiliateTool> tools;

  const AffiliateToolsRow({
    super.key,
    this.title,
    this.tools = const [..._videoTools, ..._imageTools, ..._editingTools],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title!, style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
        ],
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tools.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final t = tools[i];
              return _AffiliateChip(tool: t)
                  .animate(delay: Duration(milliseconds: i * 60))
                  .fadeIn()
                  .slideX(begin: 0.2);
            },
          ),
        ),
      ],
    );
  }
}

class _AffiliateChip extends StatelessWidget {
  final AffiliateTool tool;
  const _AffiliateChip({required this.tool});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(tool.url), mode: LaunchMode.externalApplication),
      child: Container(
        width: 96,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: tool.accentColor.withOpacity(0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(tool.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              tool.name,
              style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (tool.badge != null)
              Text(
                tool.badge!,
                style: AppTypography.labelSmall.copyWith(color: tool.accentColor, fontSize: 9),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 4. CONTEXT-AWARE AFFILIATE SUGGESTION ─────────────────────────────────
/// Shown at the top of the video-prompts tab with the matching tool.
class GeneratorAffiliateSuggestion extends StatelessWidget {
  final String generatorName;
  const GeneratorAffiliateSuggestion({super.key, required this.generatorName});

  static const _generatorMap = {
    'Runway': AffiliateTool(name: 'Runway', tagline: 'Use your prompts here — Gen-3 Alpha', emoji: '🎬', url: 'https://runwayml.com', accentColor: Color(0xFF6C63FF), badge: 'Your Generator', category: 'video'),
    'Kling': AffiliateTool(name: 'Kling AI', tagline: 'Paste your Kling prompts here', emoji: '🎥', url: 'https://klingai.com', accentColor: Color(0xFF00E5CC), badge: 'Your Generator', category: 'video'),
    'Pika': AffiliateTool(name: 'Pika', tagline: 'Use your prompts in Pika 2.0', emoji: '⚡', url: 'https://pika.art', accentColor: Color(0xFFFF6B35), badge: 'Your Generator', category: 'video'),
    'Sora': AffiliateTool(name: 'Sora', tagline: 'OpenAI Sora — paste your scenes', emoji: '🎞️', url: 'https://sora.com', accentColor: Color(0xFF10A37F), badge: 'Your Generator', category: 'video'),
    'Luma': AffiliateTool(name: 'Luma AI', tagline: 'Dream Machine — use your prompts', emoji: '🌀', url: 'https://lumalabs.ai', accentColor: Color(0xFFFF0080), badge: 'Your Generator', category: 'video'),
    'Haiper': AffiliateTool(name: 'Haiper', tagline: 'Motion-first AI video generation', emoji: '💫', url: 'https://haiper.ai', accentColor: Color(0xFF2196F3), badge: 'Your Generator', category: 'video'),
  };

  @override
  Widget build(BuildContext context) {
    final tool = _generatorMap[generatorName];
    if (tool == null) return const SizedBox.shrink();
    return InlineAffiliateCard(
      tool: tool,
      contextLabel: '⬆  Paste these prompts into ${tool.name}:',
    );
  }
}
