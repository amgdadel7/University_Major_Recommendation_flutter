import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryLight,
        brightness: Brightness.light,
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        surface: AppColors.surfaceLight,
        background: AppColors.backgroundLight,
        error: AppColors.errorLight,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.backgroundLight,
      
      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimaryLight,
        iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
        titleTextStyle: AppTextStyles.headlineMedium(color: AppColors.textPrimaryLight),
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge(color: AppColors.textPrimaryLight),
        displayMedium: AppTextStyles.displayMedium(color: AppColors.textPrimaryLight),
        displaySmall: AppTextStyles.displaySmall(color: AppColors.textPrimaryLight),
        headlineLarge: AppTextStyles.headlineLarge(color: AppColors.textPrimaryLight),
        headlineMedium: AppTextStyles.headlineMedium(color: AppColors.textPrimaryLight),
        headlineSmall: AppTextStyles.headlineSmall(color: AppColors.textPrimaryLight),
        titleLarge: AppTextStyles.titleLarge(color: AppColors.textPrimaryLight),
        titleMedium: AppTextStyles.titleMedium(color: AppColors.textPrimaryLight),
        titleSmall: AppTextStyles.titleSmall(color: AppColors.textPrimaryLight),
        bodyLarge: AppTextStyles.bodyLarge(color: AppColors.textPrimaryLight),
        bodyMedium: AppTextStyles.bodyMedium(color: AppColors.textSecondaryLight),
        bodySmall: AppTextStyles.bodySmall(color: AppColors.textSecondaryLight),
        labelLarge: AppTextStyles.labelLarge(color: AppColors.textPrimaryLight),
      ),
      
      // Card
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.surfaceLight,
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.errorLight),
        ),
        labelStyle: AppTextStyles.bodyMedium(color: AppColors.textSecondaryLight),
        hintStyle: AppTextStyles.bodyMedium(color: AppColors.textSecondaryLight),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.labelLarge(fontSize: 16),
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textSecondaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.bodySmall(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.bodySmall(fontSize: 12),
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: AppColors.textPrimaryLight,
        size: 24,
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryDark,
        brightness: Brightness.dark,
        primary: AppColors.primaryDark,
        secondary: AppColors.secondaryDark,
        surface: AppColors.surfaceDark,
        background: AppColors.backgroundDark,
        error: AppColors.errorDark,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.backgroundDark,
      
      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
        titleTextStyle: AppTextStyles.headlineMedium(color: AppColors.textPrimaryDark),
      ),
      
      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge(color: AppColors.textPrimaryDark),
        displayMedium: AppTextStyles.displayMedium(color: AppColors.textPrimaryDark),
        displaySmall: AppTextStyles.displaySmall(color: AppColors.textPrimaryDark),
        headlineLarge: AppTextStyles.headlineLarge(color: AppColors.textPrimaryDark),
        headlineMedium: AppTextStyles.headlineMedium(color: AppColors.textPrimaryDark),
        headlineSmall: AppTextStyles.headlineSmall(color: AppColors.textPrimaryDark),
        titleLarge: AppTextStyles.titleLarge(color: AppColors.textPrimaryDark),
        titleMedium: AppTextStyles.titleMedium(color: AppColors.textPrimaryDark),
        titleSmall: AppTextStyles.titleSmall(color: AppColors.textPrimaryDark),
        bodyLarge: AppTextStyles.bodyLarge(color: AppColors.textPrimaryDark),
        bodyMedium: AppTextStyles.bodyMedium(color: AppColors.textSecondaryDark),
        bodySmall: AppTextStyles.bodySmall(color: AppColors.textSecondaryDark),
        labelLarge: AppTextStyles.labelLarge(color: AppColors.textPrimaryDark),
      ),
      
      // Card
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.surfaceDark,
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.errorDark),
        ),
        labelStyle: AppTextStyles.bodyMedium(color: AppColors.textSecondaryDark),
        hintStyle: AppTextStyles.bodyMedium(color: AppColors.textSecondaryDark),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.labelLarge(fontSize: 16),
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.bodySmall(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.bodySmall(fontSize: 12),
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: AppColors.textPrimaryDark,
        size: 24,
      ),
    );
  }
}

