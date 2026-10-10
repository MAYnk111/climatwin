import 'package:flutter/material.dart';

class ClimatwinTheme {
  // Dark Palette (Obsidian / Slate / Emerald / Teal)
  static const Color background = Color(0xFF0A0E17);
  static const Color surfaceCard = Color(0xFF111827);
  static const Color surfaceElevated = Color(0xFF1F2937);
  static const Color borderSubtle = Color(0xFF263345);
  static const Color borderFocused = Color(0xFF3B82F6);

  // Accents
  static const Color darkGreenPrimary = Color(0xFF10B981); // Emerald
  static const Color darkGreenAccent = Color(0xFF14B8A6);  // Teal
  static const Color lightGreenSurface = Color(0xFF064E3B); // Deep emerald surface
  static const Color accentTeal = Color(0xFF06B6D4);

  // Typography
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Meaningful Risk State Colors
  static const Color riskLow = Color(0xFF10B981);       // Green
  static const Color riskMedium = Color(0xFFF59E0B);    // Amber
  static const Color riskHigh = Color(0xFFEF4444);      // Red
  static const Color riskCritical = Color(0xFFDC2626);  // Deep Red

  // Backwards compatibility aliases
  static const Color surfaceBackground = background;

  static Color getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return riskLow;
      case 'medium':
      case 'moderate':
        return riskMedium;
      case 'high':
        return riskHigh;
      case 'critical':
        return riskCritical;
      default:
        return textSecondary;
    }
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: darkGreenPrimary,
        secondary: darkGreenAccent,
        surface: surfaceCard,
        error: riskHigh,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceCard,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1.0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: borderSubtle, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceCard,
        selectedItemColor: darkGreenPrimary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkGreenPrimary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: lightGreenSurface,
        labelStyle: const TextStyle(fontSize: 12, color: textPrimary),
        side: const BorderSide(color: borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: const DividerThemeData(
        color: borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Light theme preserved for compatibility
  static ThemeData get lightTheme => darkTheme;
}
