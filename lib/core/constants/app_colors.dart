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

  // Extra tokens (previously hardcoded inside widgets)
  static const Color slate50 = Color(0xFFF8FAFC); // same as surfaceSecondary
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate600 = Color(0xFF475569);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color red600 = Color(0xFFDC2626);
  static const Color violet50 = Color(0xFFF5F3FF); // soft tint used in empty states

  // Credit badge
  static const Color creditBadgeStart = Color(0xFFFEF3C7);
  static const Color creditBadgeEnd = Color(0xFFFDE68A);
  static const Color creditBadgeText = Color(0xFF92400E);
  static const Color creditBadgeSubText = Color(0xFFB45309);

  // Skeleton / shimmer
  static const Color shimmerBase = Color(0xFFE5E7EB);
  static const Color shimmerHighlight = Color(0xFFF9FAFB);

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

/// Colour set used by [StatusBadge] (background, foreground, dot) plus a
/// Vietnamese label. Keeping it here means a status colour only has to be
/// changed in one place.
class StatusStyle {
  final Color bg;
  final Color fg;
  final Color dot;
  final String? label;

  const StatusStyle({
    required this.bg,
    required this.fg,
    required this.dot,
    this.label,
  });

  static const StatusStyle _success = StatusStyle(
    bg: AppColors.primaryLight,
    fg: AppColors.primary,
    dot: AppColors.primary,
  );
  static const StatusStyle _neutral = StatusStyle(
    bg: AppColors.gray100,
    fg: AppColors.gray500,
    dot: AppColors.textMuted,
  );
  static const StatusStyle _warning = StatusStyle(
    bg: AppColors.amber50,
    fg: AppColors.accentDark,
    dot: AppColors.warning,
  );
  static const StatusStyle _danger = StatusStyle(
    bg: AppColors.errorLight,
    fg: AppColors.red600,
    dot: AppColors.error,
  );
  static const StatusStyle _info = StatusStyle(
    bg: AppColors.blue50,
    fg: AppColors.blue600,
    dot: AppColors.blue500,
  );

  StatusStyle _withLabel(String l) =>
      StatusStyle(bg: bg, fg: fg, dot: dot, label: l);

  /// Returns the style for a backend status string (case-insensitive).
  /// Unknown statuses fall back to a neutral grey with no label override.
  static StatusStyle of(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return _success._withLabel('Đang nhận hồ sơ');
      case 'closed':
        return _neutral._withLabel('Đã đóng');
      case 'hidden':
        return _warning._withLabel('Tạm ẩn');
      case 'removed':
        return _danger._withLabel('Đã gỡ bỏ');
      case 'pending':
        return _info._withLabel('Chờ xem xét');
      case 'reviewing':
        return _warning._withLabel('Đang đánh giá');
      case 'shortlisted':
        return _info._withLabel('Chọn phỏng vấn');
      case 'accepted':
        return _success._withLabel('Trúng tuyển');
      case 'rejected':
        return _danger._withLabel('Từ chối');
      case 'resolved':
        return _success._withLabel('Đã giải quyết');
      default:
        return _neutral;
    }
  }
}
