import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static TextTheme _buildTextTheme(Color textColor, Color primaryColor) {
    return TextTheme(
      // Headlines & Titles (Prompt)
      displayLarge: GoogleFonts.prompt(color: textColor, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.prompt(color: textColor, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.prompt(color: textColor, fontWeight: FontWeight.w600),
      headlineLarge: GoogleFonts.prompt(color: textColor, fontWeight: FontWeight.w600),
      headlineMedium: GoogleFonts.prompt(color: textColor, fontWeight: FontWeight.w600),
      headlineSmall: GoogleFonts.prompt(color: textColor, fontWeight: FontWeight.w500),
      titleLarge: GoogleFonts.prompt(color: textColor, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.prompt(color: textColor, fontWeight: FontWeight.w500),
      titleSmall: GoogleFonts.prompt(color: textColor, fontWeight: FontWeight.w500),

      // Body & UI Elements (Rubik)
      bodyLarge: GoogleFonts.rubik(color: textColor),
      bodyMedium: GoogleFonts.rubik(color: textColor),
      bodySmall: GoogleFonts.rubik(color: textColor),
      labelLarge: GoogleFonts.rubik(color: primaryColor, fontWeight: FontWeight.w500),
      labelMedium: GoogleFonts.rubik(color: textColor),
      labelSmall: GoogleFonts.rubik(color: textColor),
    );
  }

  static ThemeData get lightTheme {
    const primaryBlue = AppColors.primary;
    const surfaceGray = AppColors.lightSurface;
    const textDark = AppColors.lightTextPrimary;

    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        surface: surfaceGray,
        onSurface: textDark,
      ),
      textTheme: _buildTextTheme(textDark, primaryBlue),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: GoogleFonts.prompt(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceGray,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.rubik(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const primaryBlue = AppColors.primary;
    const surfaceDark = AppColors.darkSurface;
    const textLight = AppColors.darkTextPrimary;

    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
        primary: primaryBlue,
        surface: surfaceDark,
        onSurface: textLight,
      ),
      textTheme: _buildTextTheme(textLight, primaryBlue),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: textLight,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        titleTextStyle: GoogleFonts.prompt(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.rubik(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
