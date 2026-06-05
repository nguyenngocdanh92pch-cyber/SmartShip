import 'package:intl/intl.dart';

class AppFormatters {
  // Định dạng tiền tệ Việt Nam: 50,000đ
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount);
  }

  // Định dạng ngày tháng: 27/10/2023 14:30
  static String formatDateTime(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return "";
    final dateTime = DateTime.parse(dateTimeStr);
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}
