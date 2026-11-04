import 'package:flutter/material.dart';

class AppColors {
  // Primary brand palette - TopCV Emerald Green & Mint
  static const Color primary = Color(0xFF00B14F); // TopCV Signature Green
  static const Color primaryDark = Color(0xFF00873C); // TopCV Deep Green
  static const Color primaryLight = Color(0xFFE8F8EE); // TopCV Light Mint Tint
  static const Color primaryContainer = Color(0xFFD1F2DE); // TopCV Soft Green Container

  // Secondary & Accents
  static const Color secondary = Color(0xFF0F172A); // Dark Slate 900
  static const Color secondaryLight = Color(0xFF1E293B); // Slate 800
  static const Color accent = Color(0xFFF59E0B); // Amber / Credit Gold
  static const Color accentDark = Color(0xFFD97706); // Amber 600
  static const Color accentLight = Color(0xFFFEF3C7); // Amber 100

  // Feedback colors
  static const Color success = Color(0xFF00B14F); // TopCV Green
  static const Color successLight = Color(0xFFE8F8EE); // Mint
  static const Color successDark = Color(0xFF00873C); // Forest

  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 100

  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorLight = Color(0xFFFEE2E2); // Red 100
  static const Color errorDark = Color(0xFF991B1B); // Red 800

  static const Color info = Color(0xFF0284C7); // Sky 600
  static const Color infoLight = Color(0xFFE0F2FE); // Sky 100

  // Neutrals & Surfaces
  static const Color background = Color(0xFFF4F6F8); // TopCV Light Gray
  static const Color surface = Colors.white;
  static const Color surfaceSecondary = Color(0xFFF8FAFC); // Clean Surface
  static const Color border = Color(0xFFE5E7EB); // Soft Border Gray 200
  static const Color borderDark = Color(0xFFD1D5DB); // Border Gray 300

  // Text hierarchy
  static const Color textPrimary = Color(0xFF111827); // Dark Gray 900
  static const Color textSecondary = Color(0xFF4B5563); // Gray 600
  static const Color textMuted = Color(0xFF9CA3AF); // Gray 400

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00B14F), Color(0xFF009643)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient creditGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
