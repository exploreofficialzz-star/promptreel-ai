import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Color Palette ─────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Core Brand
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color surfaceElevated = Color(0xFF1A1A26);
  static const Color surfaceHighlight = Color(0xFF22223A);

  // Borders
  static const Color border = Color(0xFF2A2A40);
  static const Color borderLight = Color(0xFF383858);

  // Amber — Primary accent (cinematic film amber)
  static const Color primary = Color(0xFFFFB830);
  static const Color primaryLight = Color(0xFFFFCC66);
  static const Color primaryDark = Color(0xFFCC8800);
  static const Color primaryGlow = Color(0x33FFB830);

  // Teal — Secondary accent (electric)
  static const Color secondary = Color(0xFF00E5CC);
  static const Color secondaryLight = Color(0xFF66F0E0);
  static const Color secondaryDark = Color(0xFF00B8A6);
  static const Color secondaryGlow = Color(0x3300E5CC);

  // Status
  static const Color success = Color(0xFF4CAF7D);
  static const Color successGlow = Color(0x334CAF7D);
  static const Color error = Color(0xFFFF5252);
  static const Color errorGlow = Color(0x33FF5252);
  static const Color warning = Color(0xFFFFB830);
  static const Color info = Color(0xFF2196F3);

  // Text
  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFFAAAAAE);
  static const Color textMuted = Color(0xFF66667A);
  static const Color textDisabled = Color(0xFF44445A);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFFB830), Color(0xFFFF7B00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF00E5CC), Color(0xFF0099FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0A0F), Color(0xFF0F0F1E), Color(0xFF0A0A0F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF12121A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ── Typography ─────────────────────────────────────────────────────────────────
class AppTypography {
  AppTypography._();

  // Web-safe fallback font stack for when Google Fonts fails to load
  static const List<String> _fallbackFonts = [
    'system-ui',
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'sans-serif',
  ];

  static TextStyle get displayLarge => GoogleFonts.syne(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.2,
      ).copyWith(fontFamilyFallback: _fallbackFonts);

  static TextStyle get displayMedium => GoogleFonts.syne(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
        height: 1.25,
      ).copyWith(fontFamilyFallback: _fallbackFonts);

  static TextStyle get displaySmall => GoogleFonts.syne(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
        height: 1.3,
      ).copyWith(fontFamilyFallback: _fallbackFonts);

  static TextStyle get headlineLarge => GoogleFonts.syne(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
      ).copyWith(fontFamilyFallback: _fallbackFonts);

  static TextStyle get headlineMedium => GoogleFonts.syne(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.35,
      ).copyWith(fontFamilyFallback: _fallbackFonts);

  static TextStyle get titleLarge => GoogleFonts.syne(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
      ).copyWith(fontFamilyFallback: _fallbackFonts);

  static TextStyle get titleMedium => GoogleFonts.syne(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.1,
        height: 1.4,
      ).copyWith(fontFamilyFallback: _fallbackFonts);

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.6,
      ).copyWith(fontFamilyFallback: _fallbackFonts);

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.6,
      ).copyWith(fontFamilyFallback: _fallbackFonts);

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.5,
      ).copyWith(fontFamilyFallback: _fallbackFonts);

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      ).copyWith(fontFamilyFallback: _fallbackFonts);

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ).copyWith(fontFamilyFallback: _fallbackFonts);

  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
        letterSpacing: 1.0,
      ).copyWith(fontFamilyFallback: _fallbackFonts);

  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.6,
      ).copyWith(fontFamilyFallback: ['Courier New', 'Courier', 'monospace']);
}

// ── Spacing ─────────────────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

// ── Border Radius ─────────────────────────────────────────────────────────────
class AppRadius {
  AppRadius._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double full = 999;
}

// ── Shadows ─────────────────────────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  // Shadows are no-ops on web (performance) but work normally on mobile
  static List<BoxShadow> get primary => kIsWeb
      ? []
      : [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ];

  static List<BoxShadow> get card => kIsWeb
      ? []
      : [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ];

  static List<BoxShadow> get glow => kIsWeb
      ? []
      : [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 0,
          ),
        ];
}

// ── Main Theme ─────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: AppColors.textPrimary,
        ),
        textTheme: TextTheme(
          displayLarge: AppTypography.displayLarge,
          displayMedium: AppTypography.displayMedium,
          displaySmall: AppTypography.displaySmall,
          headlineLarge: AppTypography.headlineLarge,
          headlineMedium: AppTypography.headlineMedium,
          titleLarge: AppTypography.titleLarge,
          titleMedium: AppTypography.titleMedium,
          bodyLarge: AppTypography.bodyLarge,
          bodyMedium: AppTypography.bodyMedium,
          bodySmall: AppTypography.bodySmall,
          labelLarge: AppTypography.labelLarge,
          labelMedium: AppTypography.labelMedium,
          labelSmall: AppTypography.labelSmall,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          // Web doesn't support SystemUiOverlayStyle — guard it
          systemOverlayStyle: kIsWeb ? null : SystemUiOverlayStyle.light,
          titleTextStyle: AppTypography.headlineMedium,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          centerTitle: false,
        ),
        cardTheme: CardTheme(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceElevated,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          hintStyle: AppTypography.bodyMedium,
          labelStyle: AppTypography.bodyMedium,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.black,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTypography.labelLarge,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surfaceElevated,
          selectedColor: AppColors.primaryGlow,
          labelStyle: AppTypography.labelMedium,
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surfaceHighlight,
          contentTextStyle: AppTypography.bodyMedium
              .copyWith(color: AppColors.textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
        ),
        tabBarTheme: TabBarTheme(
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          labelStyle: AppTypography.labelLarge,
          unselectedLabelStyle: AppTypography.labelMedium,
        ),
        dialogTheme: DialogTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            side: const BorderSide(color: AppColors.border),
          ),
          titleTextStyle: AppTypography.headlineMedium,
          contentTextStyle: AppTypography.bodyMedium,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          modalBackgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textMuted,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.primaryGlow
                : AppColors.surfaceHighlight,
          ),
        ),
      );
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

/// GlowCard — Card with an optional glow border effect.
/// Safe on all platforms. Does NOT use both color + decoration on Container.
class GlowCard extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final EdgeInsetsGeometry? padding;

  const GlowCard({
    super.key,
    required this.child,
    this.glowColor = AppColors.primary,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        // ✅ color is inside BoxDecoration — no conflict
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: glowColor.withOpacity(0.3)),
        boxShadow: kIsWeb
            ? []
            : [
                BoxShadow(
                  color: glowColor.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
      ),
      child: child,
    );
  }
}

/// TagsDisplay — wrapping chip list for SEO tags and hashtags.
class TagsDisplay extends StatelessWidget {
  final List<String> tags;
  final Color color;

  const TagsDisplay({
    super.key,
    required this.tags,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags
          .map(
            (tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                // ✅ color inside BoxDecoration — no conflict
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Text(
                tag,
                style: AppTypography.labelSmall.copyWith(color: color),
              ),
            ),
          )
          .toList(),
    );
  }
}
