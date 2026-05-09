import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 暗色学院主题 — 古老图书馆阅读室的质感
class AppTheme {
  AppTheme._();

  // ── 主色系：古铜金 ──
  static const Color primaryColor = Color(0xFFD4A574);
  static const Color primaryLight = Color(0xFFE8C9A8);
  static const Color primaryDark = Color(0xFFB08150);

  // ── 背景色系：深墨绿 ──
  static const Color backgroundColor = Color(0xFF1A1D1A);
  static const Color surfaceColor = Color(0xFF222522);
  static const Color cardColor = Color(0xFF2A2D2A);
  static const Color elevatedColor = Color(0xFF313431);

  // ── 文字色系：暖白 ──
  static const Color textPrimary = Color(0xFFEBE5DB);
  static const Color textSecondary = Color(0xFFA0998C);
  static const Color textHint = Color(0xFF6B6560);

  // ── 功能色 ──
  static const Color accentColor = Color(0xFFD4A574);
  static const Color successColor = Color(0xFF6B8B6B);
  static const Color errorColor = Color(0xFFC4554A);
  static const Color warningColor = Color(0xFFD4A040);
  static const Color infoColor = Color(0xFF7BA4B5);

  // ── 装饰色 ──
  static const Color goldBorder = Color(0xFF4A4035);
  static const Color dividerColor = Color(0xFF3A3D3A);
  static const Color deepBurgundy = Color(0xFF5C2A34);

  // ── 浅色主题（备选）──
  static const Color lightBg = Color(0xFFFAF7F2);
  static const Color lightSurface = Color(0xFFFFFCF7);
  static const Color lightCard = Color(0xFFFFFDF8);
  static const Color lightTextPrimary = Color(0xFF2D2A26);
  static const Color lightTextSecondary = Color(0xFF6B6560);

  static TextTheme _buildTextTheme(
          {required Color primary, required Color secondary, required Color hint}) =>
      GoogleFonts.notoSansScTextTheme().copyWith(
        headlineLarge: GoogleFonts.notoSerifSc(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.notoSerifSc(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.notoSerifSc(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        titleMedium: GoogleFonts.notoSansSc(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: primary,
        ),
        bodyLarge: GoogleFonts.notoSansSc(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: primary,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.notoSansSc(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: primary,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.notoSansSc(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: secondary,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.notoSansSc(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: primary,
        ),
      );

  // ── 暗色学院主题（默认）──
  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(
        primary: textPrimary, secondary: textSecondary, hint: textHint);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: backgroundColor,
        onSecondary: backgroundColor,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: textTheme,

      // AppBar — 半透明深色
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: surfaceColor.withOpacity(0.95),
        foregroundColor: textPrimary,
        titleTextStyle: GoogleFonts.notoSerifSc(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
      ),

      // Card — 深邃表面 + 金边
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: goldBorder, width: 0.5),
        ),
        color: cardColor,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // Button — 古铜金填充
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: backgroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: GoogleFonts.notoSansSc(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input — 暗色凹陷
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        hintStyle: GoogleFonts.notoSansSc(
          fontSize: 14,
          color: textHint,
        ),
      ),

      // Divider — 极隐
      dividerTheme:
          const DividerThemeData(color: dividerColor, thickness: 0.5),

      // NavigationBar — 深色底栏
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceColor,
        indicatorColor: primaryColor.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.notoSansSc(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? primaryColor : textSecondary,
          );
        }),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        selectedColor: primaryColor.withOpacity(0.25),
        labelStyle: GoogleFonts.notoSansSc(
          fontSize: 12,
          color: textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: goldBorder, width: 0.5),
        ),
      ),

      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: goldBorder, width: 0.5),
        ),
        titleTextStyle: GoogleFonts.notoSerifSc(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: elevatedColor,
        contentTextStyle:
            GoogleFonts.notoSansSc(fontSize: 14, color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── 浅色主题（备选 - 暖纸色）──
  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(
        primary: lightTextPrimary,
        secondary: lightTextSecondary,
        hint: textHint);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryDark,
        secondary: accentColor,
        surface: lightSurface,
        error: errorColor,
      ),
      scaffoldBackgroundColor: lightBg,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: lightSurface.withOpacity(0.95),
        foregroundColor: lightTextPrimary,
        titleTextStyle: GoogleFonts.notoSerifSc(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: lightTextSecondary.withOpacity(0.15)),
        ),
        color: lightCard,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              BorderSide(color: lightTextSecondary.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              BorderSide(color: lightTextSecondary.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: primaryDark, width: 1.5),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: lightTextSecondary.withOpacity(0.15),
        thickness: 0.5,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        indicatorColor: primaryColor.withOpacity(0.15),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: lightBg,
        selectedColor: primaryColor.withOpacity(0.2),
        side: BorderSide(
            color: lightTextSecondary.withOpacity(0.15), width: 0.5),
      ),
    );
  }
}
