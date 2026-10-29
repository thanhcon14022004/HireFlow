import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String formatVnd(dynamic amount) {
    if (amount == null) return 'Thỏa thuận';
    final numVal = amount is num ? amount : num.tryParse(amount.toString()) ?? 0;
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return formatter.format(numVal);
  }

  static String formatBudget(dynamic min, dynamic max, {String currency = 'VND'}) {
    if (min == null && max == null) return 'Thỏa thuận';
    if (min != null && max != null) {
      if (min == max) return formatVnd(min);
      return '${formatVnd(min)} - ${formatVnd(max)}';
    }
    if (min != null) return 'Từ ${formatVnd(min)}';
    return 'Lên đến ${formatVnd(max)}';
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
}
