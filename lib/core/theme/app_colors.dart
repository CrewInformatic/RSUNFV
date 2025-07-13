import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFF5591F);
  
  static const Color primaryLight = Color(0xFFF2861E);
  
  static const Color primaryDark = Color(0xFF1a1a1a);

  static const Color white = Colors.white;
  
  static const Color greyLight = Color(0xFFF5F5F5);
  
  static const Color greyMedium = Color(0xFFE0E0E0);
  
  static const Color backgroundLight = Color(0xFFF8FAFC);

  static const Color darkText = Color(0xFF1E293B);
  
  static const Color mediumText = Color(0xFF64748B);

  static const Color primaryBlue = Color(0xFF667eea);
  
  static const Color secondaryPurple = Color(0xFF764ba2);
  
  static const Color pinkGradientStart = Color(0xFFf093fb);
  
  static const Color pinkGradientEnd = Color(0xFFf5576c);
  
  static const Color blueGradientStart = Color(0xFF4facfe);
  
  static const Color blueGradientEnd = Color(0xFF00f2fe);

  static const Color success = Color(0xFF2dd4bf);
  
  static const Color warning = Color(0xFFFF8C00);
  
  static const Color error = Color(0xFFf5576c);
  
  static const Color info = Color(0xFF4facfe);

  static const Color gold = Color(0xFFFFD700);
  
  static const Color gamesPurple = Color(0xFF9333ea);
  
  static const Color divider = Color(0xFFE0E0E0);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [primaryBlue, secondaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient donationGradient = LinearGradient(
    colors: [pinkGradientStart, pinkGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient eventGradient = LinearGradient(
    colors: [blueGradientStart, blueGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
