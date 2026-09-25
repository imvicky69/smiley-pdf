import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/screens/home_screen.dart';

class SmileyPdfApp extends StatefulWidget {
  const SmileyPdfApp({super.key});

  @override
  State<SmileyPdfApp> createState() => _SmileyPdfAppState();
}

class _SmileyPdfAppState extends State<SmileyPdfApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      if (_themeMode == ThemeMode.light) {
        _themeMode = ThemeMode.dark;
      } else if (_themeMode == ThemeMode.dark) {
        _themeMode = ThemeMode.light;
      } else {
        // If system, toggle based on current platform brightness
        final brightness = MediaQuery.platformBrightnessOf(context);
        _themeMode = brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: Builder(
        builder: (context) {
          final isDark = _themeMode == ThemeMode.dark ||
              (_themeMode == ThemeMode.system &&
                  MediaQuery.platformBrightnessOf(context) == Brightness.dark);
          return HomeScreen(
            onToggleTheme: _toggleTheme,
            isDarkMode: isDark,
          );
        },
      ),
    );
  }
}
