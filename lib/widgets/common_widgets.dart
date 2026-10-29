import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class CreditBadge extends StatelessWidget {
  final int balance;
  final VoidCallback? onTap;

  const CreditBadge({super.key, required this.balance, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent.withAlpha(38),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent.withAlpha(128)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on, color: AppColors.accent, size: 18),
            const SizedBox(width: 6),
            Text(
              '$balance credit',
              style: const TextStyle(
                color: Color(0xFFB45309),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label = status;

    switch (status.toLowerCase()) {
      case 'open':
        bg = const Color(0xFFDEF7EC);
        fg = const Color(0xFF03543F);
        label = 'Đang nhận hồ sơ';
        break;
      case 'closed':
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF4B5563);
        label = 'Đã đóng';
        break;
      case 'hidden':
        bg = const Color(0xFFFEF08A);
        fg = const Color(0xFF854D0E);
        label = 'Tạm ẩn';
        break;
      case 'removed':
        bg = const Color(0xFFFDE8E8);
        fg = const Color(0xFF9B1C1C);
        label = 'Đã gỡ bỏ';
        break;
      case 'pending':
        bg = const Color(0xFFE1EFFE);
        fg = const Color(0xFF1E429F);
        label = 'Chờ duyệt';
        break;
      case 'reviewing':
        bg = const Color(0xFFEDEBFE);
        fg = const Color(0xFF5521B5);
        label = 'Đang xem xét';
        break;
      case 'shortlisted':
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF3730A3);
        label = 'Đã chọn lọc';
        break;
      case 'accepted':
        bg = const Color(0xFFDEF7EC);
        fg = const Color(0xFF03543F);
        label = 'Được nhận';
        break;
      case 'rejected':
        bg = const Color(0xFFFDE8E8);
        fg = const Color(0xFF9B1C1C);
        label = 'Bị từ chối';
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onButtonPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
