import 'package:flutter/material.dart';

class AppColors {
  // Brand colors - burgundy to purple gradient
  static const primary = Color(0xFF78133A);      // Deep burgundy
  static const primaryDark = Color(0xFF5A0F2A);  // Darker burgundy
  static const accent = Color(0xFF6f42c1);       // Purple accent
  static const background = Color(0xFF0D1F1F);   // Very dark teal-black
  static const surface = Color(0xFF1D2F2F);      // Dark teal
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFCCCCCC);
  
  // Unified gradient colors for all navigation buttons
  // Deep burgundy to muted purple-gray
  static const gradientLeft = Color(0xFF78133A);   // Deep burgundy (left)
  static const gradientRight = Color(0xFF785284);  // Muted purple-gray (right)
}

class AppSizes {
  static const double headerHeight = 80.0;
  static const double carouselHeightRatio = 0.50; // 50% of screen height for 43" display
  static const double menuHeightRatio = 0.35;
  static const double footerHeightRatio = 0.15;
  static const double cardWidth = 400.0; // Wider for 9:16 aspect
  static const double cardHeight = 700.0; // Taller for 9:16 aspect
  static const double cardBorderRadius = 20.0;
  static const double qrSize = 80.0;
}

class AppDurations {
  static const Duration carouselInterval = Duration(seconds: 5);
  static const Duration buttonAnimation = Duration(milliseconds: 150);
  static const Duration idleTimeout = Duration(seconds: 30);
  static const Duration fadeTransition = Duration(milliseconds: 500);
}

class AppTextStyles {
  static const TextStyle buttonTitle = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle time = TextStyle(
    fontSize: 64,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle dateCard = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.accent,
  );

  static const TextStyle screensaverTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle screensaverHint = TextStyle(
    fontSize: 18,
    color: AppColors.textSecondary,
  );
}
