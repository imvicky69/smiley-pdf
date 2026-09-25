import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_constants.dart';
import 'core/models/recent_file.dart';
import 'core/services/recent_files_service.dart';
import 'features/home/presentation/widgets/app_bottom_nav_bar.dart';
import 'features/home/presentation/widgets/placeholder_tab_view.dart';
import 'features/home/presentation/widgets/quick_tools_section.dart';
import 'features/home/presentation/widgets/recent_file_card.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RecentFilesService.instance.init();
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
  int _currentNavIndex = 0;

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
    RecentFilesService.instance.addRecent(path);
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

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear Recent Files?',
          style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will clear your recently opened list. Your original files will not be deleted.',
          style: GoogleFonts.rubik(fontSize: 14, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.rubik(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              RecentFilesService.instance.clearAll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Clear',
              style: GoogleFonts.rubik(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2596BE);

    final List<Widget> pages = [
      _buildHomeBody(primaryBlue),
      PlaceholderTabView(
        title: 'Library',
        description: 'Organize, tag, and browse all PDF documents across your device.',
        icon: Icons.folder_copy_rounded,
        actionLabel: 'Browse PDFs',
        onAction: _pickFileManually,
      ),
      PlaceholderTabView(
        title: 'Search',
        description: 'Search document titles, metadata, and OCR-extracted text across all your files.',
        icon: Icons.search_rounded,
        extraContent: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
              const SizedBox(width: 10),
              Text(
                'Search across your documents...',
                style: GoogleFonts.rubik(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
      PlaceholderTabView(
        title: 'Account',
        description: 'Manage viewer preferences, customize app theme, and security settings.',
        icon: Icons.person_rounded,
        extraContent: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smiley PDF',
                    style: GoogleFonts.prompt(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Version 1.0.0 (Release)',
                    style: GoogleFonts.rubik(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _currentNavIndex == 0
          ? AppBar(
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
            )
          : null,
      body: IndexedStack(
        index: _currentNavIndex,
        children: pages,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentNavIndex,
        onTabSelected: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
      ),
      floatingActionButton: _currentNavIndex == 0
          ? ValueListenableBuilder<List<RecentFile>>(
              valueListenable: RecentFilesService.instance.recentFilesNotifier,
              builder: (context, recents, _) {
                if (recents.isEmpty) return const SizedBox.shrink();
                return FloatingActionButton.extended(
                  onPressed: _pickFileManually,
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: Text(
                    'Open PDF',
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }

  Widget _buildHomeBody(Color primaryBlue) {
    return SafeArea(
      child: ValueListenableBuilder<List<RecentFile>>(
        valueListenable: RecentFilesService.instance.recentFilesNotifier,
        builder: (context, recents, _) {
          if (recents.isEmpty) {
            return _buildEmptyState(primaryBlue);
          }
          return _buildRecentsState(recents, primaryBlue);
        },
      ),
    );
  }

  Widget _buildEmptyState(Color primaryBlue) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Quick Tools section above or below
            const QuickToolsSection(),
            const SizedBox(height: 24),

            // Real Smiley PDF Logo in hero circle
            Container(
              width: 120,
              height: 120,
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
              padding: const EdgeInsets.all(20),
              child: Image.asset(
                'assets/images/appIcon_foreground.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),

            // Clean headline & subtitle
            Text(
              AppConstants.appName,
              style: GoogleFonts.prompt(
                fontSize: 24,
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
                  fontSize: 13.5,
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Single, prominent Open PDF action button
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
            const SizedBox(height: 14),
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
    );
  }

  Widget _buildRecentsState(List<RecentFile> recents, Color primaryBlue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Placeholder buttons for OCR, Scan Document, Protect PDF
        const QuickToolsSection(),

        // Section Header: "Recently Viewed" with count badge & Clear all
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Recently Viewed',
                    style: GoogleFonts.prompt(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${recents.length}',
                      style: GoogleFonts.rubik(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _confirmClearAll,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Clear all',
                  style: GoogleFonts.rubik(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // List of Recently Viewed files
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            itemCount: recents.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final recent = recents[index];
              return RecentFileCard(
                file: recent,
                onOpen: () => _openPdf(recent.path),
              );
            },
          ),
        ),
      ],
    );
  }
}
