import 'package:flutter/material.dart';

class ClimatwinTheme {
  // Approved CLIMATWIN Color Palette
  static const Color darkGreenPrimary = Color(0xFF0F3E30);
  static const Color darkGreenAccent = Color(0xFF185A46);
  static const Color lightGreenSurface = Color(0xFFEBF4F0);
  
  static const Color surfaceBackground = Color(0xFFF9FAFB);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color borderSubtle = Color(0xFFE5E7EB);
  
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Meaningful Risk State Colors
  static const Color riskLow = Color(0xFF15803D);       // Green
  static const Color riskMedium = Color(0xFFD97706);    // Amber
  static const Color riskHigh = Color(0xFFDC2626);      // Red
  static const Color riskCritical = Color(0xFF991B1B);  // Deep Red

  static Color getRiskColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return riskLow;
      case 'medium':
        return riskMedium;
      case 'high':
        return riskHigh;
      case 'critical':
        return riskCritical;
      default:
        return textSecondary;
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surfaceBackground,
      colorScheme: const ColorScheme.light(
        primary: darkGreenPrimary,
        secondary: darkGreenAccent,
        surface: surfaceCard,
        error: riskHigh,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceCard,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0.5,
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
    );
  }
}
