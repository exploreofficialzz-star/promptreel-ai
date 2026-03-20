import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool hasBorder;
  final bool hasGlow;
  final Color? borderColor;
  final double? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.hasBorder = true,
    this.hasGlow = false,
    this.borderColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius:
            BorderRadius.circular(borderRadius ?? AppRadius.lg),
        border: hasBorder
            ? Border.all(
                color: borderColor ?? AppColors.border,
                width: 1,
              )
            : null,
        boxShadow: hasGlow ? AppShadows.glow : AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(borderRadius ?? AppRadius.lg),
        child: Material(
          color: Colors.transparent,
          child: onTap != null
              ? InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding:
                        padding ?? const EdgeInsets.all(AppSpacing.md),
                    child: child,
                  ),
                )
              : Padding(
                  padding:
                      padding ?? const EdgeInsets.all(AppSpacing.md),
                  child: child,
                ),
        ),
      ),
    );
  }
}

// ─── Glow Card ────────────────────────────────────────────────────────────────
class GlowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color glowColor;

  const GlowCard({
    super.key,
    required this.child,
    this.padding,
    this.glowColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: glowColor.withOpacity(0.4), width: 1),
        // ✅ Shadows disabled on web for performance
        boxShadow: kIsWeb
            ? []
            : [
                BoxShadow(
                  color: glowColor.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: -5,
                ),
              ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget? icon;
  final Color? accentColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: (accentColor ?? AppColors.primary).withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Expanded(
                child: Text(label, style: AppTypography.labelMedium),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.displaySmall.copyWith(
              color: accentColor ?? AppColors.primary,
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }
}
