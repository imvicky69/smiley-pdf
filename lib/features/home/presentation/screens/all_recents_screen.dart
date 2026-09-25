import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/models/recent_file.dart';
import '../../../../core/services/recent_files_service.dart';
import '../../../pdf_viewer/presentation/screens/pdf_viewer_screen.dart';
import '../widgets/recent_file_card.dart';

class AllRecentsScreen extends StatefulWidget {
  final VoidCallback onPickManual;

  const AllRecentsScreen({
    super.key,
    required this.onPickManual,
  });

  @override
  State<AllRecentsScreen> createState() => _AllRecentsScreenState();
}

class _AllRecentsScreenState extends State<AllRecentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    RecentFilesService.instance.purgeMissingFiles();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openPdf(String path) {
    RecentFilesService.instance.addRecent(path);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(filePath: path),
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear All Recents?',
          style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will remove all documents from your recent history. Your original files will not be deleted.',
          style:
              GoogleFonts.rubik(fontSize: 14, color: const Color(0xFF64748B)),
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
              'Clear All',
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
    const Color textDark = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        foregroundColor: textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: ValueListenableBuilder<List<RecentFile>>(
          valueListenable: RecentFilesService.instance.recentFilesNotifier,
          builder: (context, recents, _) {
            final validRecents =
                recents.where((f) => File(f.path).existsSync()).toList();
            return Row(
              children: [
                Text(
                  'Recently Viewed',
                  style: GoogleFonts.prompt(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${validRecents.length}',
                    style: GoogleFonts.rubik(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primaryBlue,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          ValueListenableBuilder<List<RecentFile>>(
            valueListenable: RecentFilesService.instance.recentFilesNotifier,
            builder: (context, recents, _) {
              final validRecents =
                  recents.where((f) => File(f.path).existsSync()).toList();
              if (validRecents.isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: _confirmClearAll,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE11D48),
                ),
                child: Text(
                  'Clear all',
                  style: GoogleFonts.rubik(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: Color(0xFF94A3B8), size: 19),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.rubik(
                        fontSize: 13.5,
                        color: const Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search recent documents...',
                        hintStyle: GoogleFonts.rubik(
                          fontSize: 13.5,
                          color: const Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () => _searchController.clear(),
                      child: const Icon(Icons.close_rounded,
                          color: Color(0xFF94A3B8), size: 18),
                    ),
                ],
              ),
            ),
          ),

          // Slide hint banner
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: Row(
              children: [
                const Icon(Icons.swipe_left_rounded,
                    size: 15, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Text(
                  'Slide left on any document to remove',
                  style: GoogleFonts.rubik(
                    fontSize: 11.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),

          // Recents list
          Expanded(
            child: ValueListenableBuilder<List<RecentFile>>(
              valueListenable: RecentFilesService.instance.recentFilesNotifier,
              builder: (context, recents, _) {
                final validRecents =
                    recents.where((f) => File(f.path).existsSync()).toList();
                final filtered = _searchQuery.isEmpty
                    ? validRecents
                    : validRecents
                        .where((f) =>
                            f.fileName.toLowerCase().contains(_searchQuery))
                        .toList();

                if (validRecents.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: primaryBlue.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.history_rounded,
                                size: 36, color: primaryBlue),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'No Recent Documents',
                            style: GoogleFonts.prompt(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Documents you open in Smiley PDF will appear here for quick access.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.rubik(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 22),
                          ElevatedButton.icon(
                            onPressed: widget.onPickManual,
                            icon: const Icon(Icons.folder_open_rounded,
                                size: 18),
                            label: const Text('Open a PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (filtered.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Text(
                      'No documents match "$_searchQuery"',
                      style: GoogleFonts.rubik(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final recent = filtered[index];
                    return RecentFileCard(
                      file: recent,
                      onOpen: () => _openPdf(recent.path),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onPickManual,
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
      ),
    );
  }
}
