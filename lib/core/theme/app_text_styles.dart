import 'package:flutter/material.dart';

/// Text styles using local Cairo font
/// This replaces GoogleFonts.cairo() to avoid internet dependency
class AppTextStyles {
  static const String fontFamily = 'Cairo';
  
  // Helper method to create TextStyle with Cairo font
  static TextStyle cairo({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }
  
  // Display styles
  static TextStyle displayLarge({Color? color}) => cairo(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: color,
  );
  
  static TextStyle displayMedium({Color? color}) => cairo(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: color,
  );
  
  static TextStyle displaySmall({Color? color}) => cairo(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: color,
  );
  
  // Headline styles
  static TextStyle headlineLarge({Color? color}) => cairo(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: color,
  );
  
  static TextStyle headlineMedium({Color? color}) => cairo(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: color,
  );
  
  static TextStyle headlineSmall({Color? color}) => cairo(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: color,
  );
  
  // Title styles
  static TextStyle titleLarge({Color? color}) => cairo(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: color,
  );
  
  static TextStyle titleMedium({Color? color}) => cairo(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: color,
  );
  
  static TextStyle titleSmall({Color? color}) => cairo(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: color,
  );
  
  // Body styles
  static TextStyle bodyLarge({Color? color}) => cairo(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: color,
  );
  
  static TextStyle bodyMedium({Color? color}) => cairo(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: color,
  );
  
  static TextStyle bodySmall({Color? color, double? fontSize, FontWeight? fontWeight}) => cairo(
    fontSize: fontSize ?? 12,
    fontWeight: fontWeight ?? FontWeight.normal,
    color: color,
  );
  
  // Label styles
  static TextStyle labelLarge({Color? color, double? fontSize}) => cairo(
    fontSize: fontSize ?? 14,
    fontWeight: FontWeight.w600,
    color: color,
  );
}

