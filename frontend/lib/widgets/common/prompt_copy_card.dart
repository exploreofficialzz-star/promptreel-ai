import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class PromptCopyCard extends StatefulWidget {
  final String label;
  final String content;
  final Color? accentColor;
  final bool isMonospace;
  final int? maxLines;
  final String? badge;

  const PromptCopyCard({
    super.key,
    required this.label,
    required this.content,
    this.accentColor,
    this.isMonospace = false,
    this.maxLines,
    this.badge,
  });

  @override
  State<PromptCopyCard> createState() => _PromptCopyCardState();
}

class _PromptCopyCardState extends State<PromptCopyCard> {
  bool _copied = false;
  bool _expanded = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.content));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppColors.primary;
    final hasLongContent = widget.maxLines != null && widget.content.split('\n').length > (widget.maxLines ?? 5);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md - 1)),
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        widget.label,
                        style: AppTypography.labelMedium.copyWith(
                          color: accent,
                          letterSpacing: 0.8,
                        ),
                      ),
                      if (widget.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            widget.badge!,
                            style: AppTypography.labelSmall.copyWith(color: accent),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _copy,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _copied ? AppColors.success.withOpacity(0.2) : accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 12,
                          color: _copied ? AppColors.success : accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Copied!' : 'Copy',
                          style: AppTypography.labelSmall.copyWith(
                            color: _copied ? AppColors.success : accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.content,
                  style: widget.isMonospace
                      ? AppTypography.mono
                      : AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.7,
                        ),
                  maxLines: hasLongContent && !_expanded ? widget.maxLines : null,
                  overflow: hasLongContent && !_expanded ? TextOverflow.ellipsis : null,
                ),
                if (hasLongContent) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      _expanded ? '↑ Show less' : '↓ Show more',
                      style: AppTypography.labelMedium.copyWith(color: accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Tag display widget
class TagsDisplay extends StatelessWidget {
  final List<String> tags;
  final Color? color;

  const TagsDisplay({super.key, required this.tags, this.color});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (color ?? AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: (color ?? AppColors.primary).withOpacity(0.3)),
          ),
          child: Text(
            tag,
            style: AppTypography.labelSmall.copyWith(
              color: color ?? AppColors.primary,
              letterSpacing: 0.3,
            ),
          ),
        );
      }).toList(),
    );
  }
}
