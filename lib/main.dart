import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_constants.dart';
import 'pdf_viewer_screen.dart';

ThemeData buildSmileyPdfTheme() {
  const Color primaryBlue = Color(0xFF2596BE);
  const Color surfaceGray = Color(0xFFF8FAFC);
  const Color textDark = Color(0xFF1E293B);

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
    textTheme: TextTheme(
      // Headlines & Titles (Prompt)
      displayLarge: GoogleFonts.prompt(color: textDark, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.prompt(color: textDark, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.prompt(color: textDark, fontWeight: FontWeight.w600),
      headlineLarge: GoogleFonts.prompt(color: textDark, fontWeight: FontWeight.w600),
      headlineMedium: GoogleFonts.prompt(color: textDark, fontWeight: FontWeight.w600),
      headlineSmall: GoogleFonts.prompt(color: textDark, fontWeight: FontWeight.w500),
      titleLarge: GoogleFonts.prompt(color: textDark, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.prompt(color: textDark, fontWeight: FontWeight.w500),
      titleSmall: GoogleFonts.prompt(color: textDark, fontWeight: FontWeight.w500),

      // Body & UI Elements (Rubik)
      bodyLarge: GoogleFonts.rubik(color: textDark),
      bodyMedium: GoogleFonts.rubik(color: textDark),
      bodySmall: GoogleFonts.rubik(color: textDark),
      labelLarge: GoogleFonts.rubik(color: primaryBlue, fontWeight: FontWeight.w500),
      labelMedium: GoogleFonts.rubik(color: textDark),
      labelSmall: GoogleFonts.rubik(color: textDark),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.prompt(
        color: textDark,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 1,
        textStyle: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmileyPdfApp());
}

class SmileyPdfApp extends StatelessWidget {
  final ThemeData? theme;

  const SmileyPdfApp({super.key, this.theme});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: theme ?? buildSmileyPdfTheme(),
      home: const HomeOrganizer(),
    );
  }
}

class HomeOrganizer extends StatefulWidget {
  const HomeOrganizer({super.key});

  @override
  State<HomeOrganizer> createState() => _HomeOrganizerState();
}

class _HomeOrganizerState extends State<HomeOrganizer> {
  late StreamSubscription<List<SharedMediaFile>> _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _handleExternalFiles();
  }

  void _handleExternalFiles() {
    // 1. Handle files while the app is already open in the background
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty &&
          value.first.path.toLowerCase().endsWith('.pdf')) {
        _openPdf(value.first.path);
      }
    }, onError: (err) {
      debugPrint("Intent error: $err");
    });

    // 2. Handle files when the app is launched via opening a PDF externally
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> value) {
      if (value.isNotEmpty &&
          value.first.path.toLowerCase().endsWith('.pdf')) {
        _openPdf(value.first.path);
      }
      ReceiveSharingIntent.instance.reset();
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  void _openPdf(String path) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(filePath: path),
      ),
    );
  }

  Future<void> _pickFileManually() async {
    final List<PlatformFile> files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (files.isNotEmpty && files.first.path != null) {
      _openPdf(files.first.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2596BE);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(5),
              child: Image.asset(
                'assets/images/appIcon_foreground.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppConstants.appName,
              style: GoogleFonts.prompt(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFF1F5F9),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Real Smiley PDF Logo in hero circle
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withValues(alpha: 0.12),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(22),
                  child: Image.asset(
                    'assets/images/appIcon_foreground.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 28),

                // Clean headline & subtitle
                Text(
                  AppConstants.appName,
                  style: GoogleFonts.prompt(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    'Open and read your PDF documents seamlessly, or receive files shared from other apps.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Single, clear, prominent Open PDF action button
                SizedBox(
                  width: 220,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _pickFileManually,
                    icon: const Icon(Icons.folder_open_rounded, size: 22),
                    label: Text(
                      'Open PDF',
                      style: GoogleFonts.rubik(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: primaryBlue.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Supports .pdf files',
                  style: GoogleFonts.rubik(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
