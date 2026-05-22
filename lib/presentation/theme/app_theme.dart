import 'package:flutter/material.dart';

/// 「Twilight Sky」設計系統 — Glassmorphism + 漸層天空。
///
/// 整個 App 共用同一組色票、漸層與字體階層。
class AppTheme {
  AppTheme._();

  // ── Palette ───────────────────────────────────────────────
  static const Color skyTop = Color(0xFF3B5BA0);
  static const Color skyMid = Color(0xFF7B92D1);
  static const Color skyLow = Color(0xFFB8B5DE);
  static const Color skyHorizon = Color(0xFFE5C9DF);

  static const Color glassFill = Color(0x2EFFFFFF); // white @ 18%
  static const Color glassBorder = Color(0x4DFFFFFF); // white @ 30%

  static const Color textPrimary = Color(0xFFFFFFFF);
  static Color get textSecondary => Colors.white.withValues(alpha: 0.80);
  static Color get textTertiary => Colors.white.withValues(alpha: 0.60);

  static const Color accentSun = Color(0xFFFFD56B);
  static const Color accentError = Color(0xFFFF8E8E);

  // ── Gradient ─────────────────────────────────────────────
  static const LinearGradient skyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [skyTop, skyMid, skyLow, skyHorizon],
    stops: [0.0, 0.45, 0.80, 1.0],
  );

  // ── Radius / Spacing ─────────────────────────────────────
  static const double radiusGlass = 24;
  static const double radiusGlassSmall = 16;
  static const double radiusPill = 999;

  // ── ThemeData ────────────────────────────────────────────
  static ThemeData build() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = base.textTheme.apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: textPrimary,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w200,
          letterSpacing: -2,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.80),
          letterSpacing: 0.2,
          height: 1.5,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassFill,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontWeight: FontWeight.w400,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: glassBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: const BorderSide(color: glassBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.7),
            width: 1.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusPill),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.95),
          foregroundColor: skyTop,
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: const BorderSide(color: glassBorder, width: 1.2),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: textPrimary,
      ),
      iconTheme: IconThemeData(color: Colors.white.withValues(alpha: 0.90)),
      cardTheme: const CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(),
      ),
    );
  }
}
