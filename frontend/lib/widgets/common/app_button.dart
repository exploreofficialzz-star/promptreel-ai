import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final Widget? icon;
  final double? height;
  final double? fontSize;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = false,
    this.icon,
    this.height,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(_getForegroundColor()),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: _getForegroundColor(),
                  fontSize: fontSize ?? 14,
                ),
              ),
            ],
          );

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height ?? 48,
      child: _buildButton(child),
    );
  }

  Color _getForegroundColor() {
    switch (variant) {
      case AppButtonVariant.primary:
        return Colors.black;
      case AppButtonVariant.secondary:
        return Colors.black;
      case AppButtonVariant.outline:
        return AppColors.primary;
      case AppButtonVariant.ghost:
        return AppColors.textSecondary;
      case AppButtonVariant.danger:
        return Colors.white;
    }
  }

  Widget _buildButton(Widget child) {
    switch (variant) {
      case AppButtonVariant.primary:
        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: onPressed != null ? AppShadows.primary : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Center(child: child),
            ),
          ),
        ).animate(target: onPressed != null ? 1 : 0).scaleXY(end: 0.98);

      case AppButtonVariant.secondary:
        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.secondaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Center(child: child),
            ),
          ),
        );

      case AppButtonVariant.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );

      case AppButtonVariant.ghost:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );

      case AppButtonVariant.danger:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          child: child,
        );
    }
  }
}

// Gradient Text Button
class GradientTextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const GradientTextButton({super.key, required this.text, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ShaderMask(
        shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
        child: Text(
          text,
          style: AppTypography.labelLarge.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}
