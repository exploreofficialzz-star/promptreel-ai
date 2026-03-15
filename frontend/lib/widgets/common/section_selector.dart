import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class SectionSelector<T> extends StatelessWidget {
  final String label;
  final List<SectionOption<T>> options;
  final T? selected;
  final ValueChanged<T> onSelect;
  final bool wrap;
  final double? itemHeight;

  const SectionSelector({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.wrap = true,
    this.itemHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (wrap)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.asMap().entries.map((entry) {
              return _OptionChip<T>(
                option: entry.value,
                isSelected: entry.value.value == selected,
                onTap: () => onSelect(entry.value.value),
              ).animate(delay: Duration(milliseconds: entry.key * 40)).fadeIn().slideX(begin: -0.1);
            }).toList(),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _OptionChip<T>(
                    option: entry.value,
                    isSelected: entry.value.value == selected,
                    onTap: () => onSelect(entry.value.value),
                  ),
                ).animate(delay: Duration(milliseconds: entry.key * 40)).fadeIn().slideX(begin: -0.1);
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class SectionOption<T> {
  final T value;
  final String label;
  final String? emoji;
  final String? description;
  final bool? locked;

  const SectionOption({
    required this.value,
    required this.label,
    this.emoji,
    this.description,
    this.locked,
  });
}

class _OptionChip<T> extends StatelessWidget {
  final SectionOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = option.locked ?? false;
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.8)
                : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? AppShadows.primary : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (option.emoji != null) ...[
              Text(option.emoji!, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option.label,
                  style: AppTypography.labelLarge.copyWith(
                    color: isSelected ? Colors.black : AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
                if (option.description != null)
                  Text(
                    option.description!,
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected ? Colors.black54 : AppColors.textMuted,
                    ),
                  ),
              ],
            ),
            if (isLocked) ...[
              const SizedBox(width: 6),
              Icon(Icons.lock_outline, size: 12, color: AppColors.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}

// Toggle Switch Row
class ToggleRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? badge;

  const ToggleRow({
    super.key,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: value ? AppColors.primary.withOpacity(0.4) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: AppTypography.titleMedium),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: AppColors.secondaryGradient,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          badge!,
                          style: AppTypography.labelSmall.copyWith(color: Colors.black),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null)
                  Text(subtitle!, style: AppTypography.bodySmall),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
