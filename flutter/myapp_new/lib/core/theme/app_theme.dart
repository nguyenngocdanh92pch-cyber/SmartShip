import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Theme dành cho Sender (Light Mode - Thân thiện người dùng)
  static ThemeData get senderTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.senderBackground,
      cardColor: AppColors.senderSurface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
