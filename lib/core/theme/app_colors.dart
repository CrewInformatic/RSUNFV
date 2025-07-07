import 'package:flutter/material.dart';

/// RSU App color palette and theme constants.
/// 
/// Contains all colors used throughout the application organized by category.
/// Follows Material Design 3 guidelines for color usage and accessibility.
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // === PRIMARY COLORS ===
  /// Main brand color - Orange gradient start
  static const Color primary = Color(0xFFF5591F);
  
  /// Light variant of primary color - Orange gradient end  
  static const Color primaryLight = Color(0xFFF2861E);
  
  /// Dark variant of primary color
  static const Color primaryDark = Color(0xFF1a1a1a);

  // === NEUTRAL COLORS ===
  /// Pure white
  static const Color white = Colors.white;
  
  /// Light grey for backgrounds
  static const Color greyLight = Color(0xFFF5F5F5);
  
  /// Medium grey for dividers and borders
  static const Color greyMedium = Color(0xFFE0E0E0);
  
  /// Background light color
  static const Color backgroundLight = Color(0xFFF8FAFC);

  // === TEXT COLORS ===
  /// Dark text for headings and important content
  static const Color darkText = Color(0xFF1E293B);
  
  /// Medium grey text for secondary content
  static const Color mediumText = Color(0xFF64748B);

  // === GRADIENT COLORS ===
  /// Blue gradient start for primary actions
  static const Color primaryBlue = Color(0xFF667eea);
  
  /// Purple gradient for secondary actions
  static const Color secondaryPurple = Color(0xFF764ba2);
  
  /// Pink gradient start for donation actions
  static const Color pinkGradientStart = Color(0xFFf093fb);
  
  /// Pink gradient end for donation actions
  static const Color pinkGradientEnd = Color(0xFFf5576c);
  
  /// Blue gradient start for events
  static const Color blueGradientStart = Color(0xFF4facfe);
  
  /// Blue gradient end for events
  static const Color blueGradientEnd = Color(0xFF00f2fe);

  // === STATUS COLORS ===
  /// Success/positive actions color
  static const Color success = Color(0xFF2dd4bf);
  
  /// Warning color
  static const Color warning = Color(0xFFFF8C00);
  
  /// Error/danger color
  static const Color error = Color(0xFFf5576c);
  
  /// Info color
  static const Color info = Color(0xFF4facfe);

  // === SPECIAL COLORS ===
  /// Gold color for achievements and medals
  static const Color gold = Color(0xFFFFD700);
  
  /// Purple for games and gamification
  static const Color gamesPurple = Color(0xFF9333ea);
  
  /// Divider color
  static const Color divider = Color(0xFFE0E0E0);

  // === GRADIENTS ===
  /// Primary orange gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Blue to purple gradient for hero sections
  static const LinearGradient heroGradient = LinearGradient(
    colors: [primaryBlue, secondaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Pink gradient for donations
  static const LinearGradient donationGradient = LinearGradient(
    colors: [pinkGradientStart, pinkGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Blue gradient for events
  static const LinearGradient eventGradient = LinearGradient(
    colors: [blueGradientStart, blueGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
