import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String formatVnd(dynamic amount) {
    if (amount == null) return 'Thỏa thuận';
    final numVal = amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return formatter.format(numVal);
  }

  static String formatVND(dynamic amount) => formatVnd(amount);

  static String formatBudget(dynamic min, dynamic max, {String currency = 'VND'}) {
    if (min == null && max == null) return 'Thỏa thuận';
    if (min != null && max != null) {
      if (min == max) return formatVnd(min);
      return '${formatVnd(min)} - ${formatVnd(max)}';
    }
    if (min != null) return 'Từ ${formatVnd(min)}';
    return 'Lên đến ${formatVnd(max)}';
  }

  static String formatBudgetRange(dynamic min, dynamic max) => formatBudget(min, max);

  static String formatBudgetShort(dynamic min, dynamic max) {
    if (min == null && max == null) return 'Thỏa thuận';

    String formatCompact(num val) {
      if (val >= 1000000) {
        final mil = val / 1000000;
        return mil % 1 == 0 ? '${mil.toInt()} triệu' : '${mil.toStringAsFixed(1)} triệu';
      } else if (val >= 1000) {
        return '${(val / 1000).toInt()}k';
      }
      return val.toString();
    }

    if (min != null && max != null) {
      final minVal = min is num ? min : num.tryParse(min.toString()) ?? 0;
      final maxVal = max is num ? max : num.tryParse(max.toString()) ?? 0;
      if (minVal == maxVal) return formatCompact(minVal);
      return '${formatCompact(minVal)} - ${formatCompact(maxVal)}';
    }
    if (min != null) {
      final minVal = min is num ? min : num.tryParse(min.toString()) ?? 0;
      return 'Từ ${formatCompact(minVal)}';
    }
    final maxVal = max is num ? max : num.tryParse(max.toString()) ?? 0;
    return 'Tới ${formatCompact(maxVal)}';
  }

  static String formatDate(dynamic date) {
    if (date == null) return '';
    final dt = date is DateTime ? date : DateTime.tryParse(date.toString());
    if (dt == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
  }

  static String formatDateOnly(dynamic date) {
    if (date == null) return '';
    final dt = date is DateTime ? date : DateTime.tryParse(date.toString());
    if (dt == null) return '';
    return DateFormat('dd/MM/yyyy').format(dt.toLocal());
  }

  static String formatFileSize(dynamic bytes) {
    if (bytes == null) return '0 B';
    final b = bytes is num ? bytes : num.tryParse(bytes.toString()) ?? 0;
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
