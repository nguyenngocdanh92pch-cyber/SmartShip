import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0A0E21);
  static const Color surface = Color(0xFF1D2136);
  static const Color primary = Color(0xFF2196F3);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.grey;
  static const Color accent = Color(0xFF4CAF50);

  // Màu nền cho Sender (Tông sáng/Xám nhẹ)
  static const Color senderBackground = Color(0xFFF5F5F5);
  static const Color senderSurface = Colors.white;

  // Trạng thái đơn hàng (Thống nhất với Enum ShipmentStatus)
  static const Color pending = Color(0xFFFFA500); // Cam
  static const Color accepted = Color(0xFF2196F3); // Xanh dương
  static const Color shipping = Color(0xFF9C27B0); // Tím
  static const Color delivered = Color(0xFF4CAF50); // Xanh lá
  static const Color cancelled = Color(0xFFF44336); // Đỏ

  static const Color textDark = Color(0xFF2D2D2D);
}
