import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class CreditBadge extends StatelessWidget {
  final int balance;
  final VoidCallback? onTap;
  final bool isLarge;

  const CreditBadge({
    super.key,
    required this.balance,
    this.onTap,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isLarge ? 24 : 18),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: isLarge ? 16 : 10,
            vertical: isLarge ? 8 : 5,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isLarge ? 24 : 18),
            border: Border.all(color: const Color(0xFFF59E0B).withAlpha(160), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withAlpha(35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFD97706),
                ),
                child: Icon(
                  Icons.monetization_on,
                  color: Colors.white,
                  size: isLarge ? 18 : 14,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$balance',
                style: TextStyle(
                  color: const Color(0xFF92400E),
                  fontWeight: FontWeight.w800,
                  fontSize: isLarge ? 15 : 12.5,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                'cr',
                style: TextStyle(
                  color: const Color(0xFFB45309),
                  fontWeight: FontWeight.w600,
                  fontSize: isLarge ? 13 : 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isSmall;

  const StatusBadge({super.key, required this.status, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color dot;
    String label = status;

    switch (status.toLowerCase()) {
      case 'open':
        bg = const Color(0xFFE8F8EE);
        fg = const Color(0xFF00B14F);
        dot = const Color(0xFF00B14F);
        label = 'Đang nhận hồ sơ';
        break;
      case 'closed':
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF6B7280);
        dot = const Color(0xFF9CA3AF);
        label = 'Đã đóng';
        break;
      case 'hidden':
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        dot = const Color(0xFFF59E0B);
        label = 'Tạm ẩn';
        break;
      case 'removed':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        dot = const Color(0xFFEF4444);
        label = 'Đã gỡ bỏ';
        break;
      case 'pending':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        dot = const Color(0xFF3B82F6);
        label = 'Chờ xem xét';
        break;
      case 'reviewing':
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFD97706);
        dot = const Color(0xFFF59E0B);
        label = 'Đang đánh giá';
        break;
      case 'shortlisted':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        dot = const Color(0xFF3B82F6);
        label = 'Chọn phỏng vấn';
        break;
      case 'accepted':
        bg = const Color(0xFFE8F8EE);
        fg = const Color(0xFF00B14F);
        dot = const Color(0xFF00B14F);
        label = 'Trúng tuyển';
        break;
      case 'rejected':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFDC2626);
        dot = const Color(0xFFEF4444);
        label = 'Từ chối';
        break;
      case 'resolved':
        bg = const Color(0xFFE8F8EE);
        fg = const Color(0xFF00B14F);
        dot = const Color(0xFF00B14F);
        label = 'Đã giải quyết';
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF6B7280);
        dot = const Color(0xFF9CA3AF);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withAlpha(35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: isSmall ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: themeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: themeColor, size: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          if (actionText != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              child: Text(actionText!),
            ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryLight, const Color(0xFFF5F3FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(20),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.add, size: 18),
                label: Text(buttonText!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
