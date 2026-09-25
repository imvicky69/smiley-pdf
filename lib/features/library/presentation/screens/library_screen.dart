import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/services/library_folder_service.dart';
import '../../../../core/services/recent_files_service.dart';
import '../../../pdf_viewer/presentation/screens/pdf_viewer_screen.dart';

class LibraryScreen extends StatefulWidget {
  final VoidCallback onPickManual;

  const LibraryScreen({
    super.key,
    required this.onPickManual,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isLoading = false;
  List<File> _savedFiles = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadSavedFiles();
    LibraryFolderService.instance.savedChangeNotifier
        .addListener(_loadSavedFiles);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    LibraryFolderService.instance.savedChangeNotifier
        .removeListener(_loadSavedFiles);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedFiles() async {
    setState(() => _isLoading = true);
    await RecentFilesService.instance.purgeMissingFiles();
    final files = await LibraryFolderService.instance.getSavedPdfs();
    if (!mounted) return;
    setState(() {
      _savedFiles = files;
      _isLoading = false;
    });
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

  Future<void> _sharePdf(File file) async {
    try {
      final name = file.path.split(RegExp(r'[\\/]')).last;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf', name: name)],
          subject: name,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share file: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _renameSavedPdf(File file) async {
    final currentName = file.path.split(RegExp(r'[\\/]')).last;
    final nameWithoutExt = currentName.toLowerCase().endsWith('.pdf')
        ? currentName.substring(0, currentName.length - 4)
        : currentName;

    final controller = TextEditingController(text: nameWithoutExt);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rename PDF',
          style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'File Name',
            suffixText: '.pdf',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.rubik(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Rename',
              style: GoogleFonts.rubik(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != nameWithoutExt) {
      final success =
          await LibraryFolderService.instance.renamePdf(file, newName);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Renamed to "$newName.pdf"'),
              backgroundColor: const Color(0xFF0D9488),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
          _loadSavedFiles();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Could not rename file. Name may already exist.'),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteSavedPdf(File file) async {
    final fileName = file.path.split(RegExp(r'[\\/]')).last;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete PDF?',
          style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to permanently delete "$fileName" from your offline storage?',
          style:
              GoogleFonts.rubik(fontSize: 14, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.rubik(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.rubik(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await LibraryFolderService.instance.deletePdf(file);
      if (mounted) {
        if (success) {
          RecentFilesService.instance.removeRecent(file.path);
          await RecentFilesService.instance.purgeMissingFiles();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "$fileName"'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
          _loadSavedFiles();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Could not delete file.'),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Future<void> _importPdfToSaved() async {
    final List<PlatformFile> files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (files.isNotEmpty && files.first.path != null) {
      final result = await LibraryFolderService.instance
          .savePdfToAppFolder(files.first.path!);
      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.isAlreadySaved
                  ? 'This document is already in your Saved PDFs'
                  : '✓ Saved to Smiley PDF Library'),
              backgroundColor: const Color(0xFF0D9488),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadSavedFiles();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save PDF.'),
              backgroundColor: Color(0xFFDC2626),
            ),
          );
        }
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2596BE);
    const Color tealAccent = Color(0xFF0D9488);
    const Color textDark = Color(0xFF1E293B);

    final filtered = _searchQuery.isEmpty
        ? _savedFiles
        : _savedFiles.where((f) {
            final name = f.path.split(RegExp(r'[\\/]')).last.toLowerCase();
            return name.contains(_searchQuery);
          }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Text(
              'Library',
              style: GoogleFonts.prompt(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: tealAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_savedFiles.length}',
                style: GoogleFonts.rubik(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tealAccent,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Refresh',
            onPressed: _loadSavedFiles,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open_rounded, size: 22),
            tooltip: 'Browse device',
            onPressed: widget.onPickManual,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: Column(
        children: [
          // Sleek Search Input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
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
                        hintText: 'Search saved documents...',
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

          // Subheader: Quick Count & Add Action
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.offline_pin_rounded,
                        size: 15, color: tealAccent),
                    const SizedBox(width: 6),
                    Text(
                      'Offline App Storage',
                      style: GoogleFonts.rubik(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _importPdfToSaved,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add PDF'),
                  style: TextButton.styleFrom(
                    foregroundColor: tealAccent,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: GoogleFonts.rubik(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),

          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
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
                                  color: tealAccent.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.bookmark_border_rounded,
                                  size: 36,
                                  color: tealAccent,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No Matching PDFs'
                                    : 'No Saved PDFs Yet',
                                style: GoogleFonts.prompt(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No documents match "$_searchQuery".'
                                    : 'Save documents directly into Smiley PDF to keep them organized and accessible offline anytime.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.rubik(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 22),
                              if (_searchQuery.isEmpty)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _importPdfToSaved,
                                      icon: const Icon(Icons.add_rounded,
                                          size: 18),
                                      label: const Text('Add PDF'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: tealAccent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        await LibraryFolderService.instance
                                            .ensureDefaultPdfExists();
                                        _loadSavedFiles();
                                      },
                                      icon: const Icon(
                                          Icons.restore_page_rounded,
                                          size: 18),
                                      label: const Text('Default Guide'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: tealAccent,
                                        side: BorderSide(
                                            color: tealAccent
                                                .withValues(alpha: 0.5)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final file = filtered[index];
                          final fileName =
                              file.path.split(RegExp(r'[\\/]')).last;
                          final isDefaultGuide =
                              fileName == LibraryFolderService.defaultPdfName;

                          int size = 0;
                          DateTime? modified;
                          try {
                            size = file.lengthSync();
                            modified = file.lastModifiedSync();
                          } catch (_) {}

                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () => _openPdf(file.path),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Icon / Emblem
                                    Container(
                                      width: 44,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: isDefaultGuide
                                            ? tealAccent.withValues(alpha: 0.1)
                                            : const Color(0xFFF1F5F9),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isDefaultGuide
                                              ? tealAccent.withValues(alpha: 0.3)
                                              : const Color(0xFFE2E8F0),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isDefaultGuide
                                                ? Icons.star_rounded
                                                : Icons.picture_as_pdf_rounded,
                                            color: isDefaultGuide
                                                ? tealAccent
                                                : primaryBlue,
                                            size: 22,
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: isDefaultGuide
                                                  ? tealAccent
                                                  : primaryBlue,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              'PDF',
                                              style: GoogleFonts.rubik(
                                                color: Colors.white,
                                                fontSize: 7,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  fileName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.prompt(
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        const Color(0xFF1E293B),
                                                  ),
                                                ),
                                              ),
                                              if (isDefaultGuide) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFCCFBF1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    'Default',
                                                    style: GoogleFonts.rubik(
                                                      fontSize: 9.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: const Color(
                                                          0xFF0F766E),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (size > 0)
                                                Text(
                                                  _formatSize(size),
                                                  style: GoogleFonts.rubik(
                                                    fontSize: 11.5,
                                                    color:
                                                        const Color(0xFF64748B),
                                                  ),
                                                ),
                                              if (size > 0 && modified != null)
                                                Text(
                                                  ' • ',
                                                  style: GoogleFonts.rubik(
                                                    fontSize: 11.5,
                                                    color:
                                                        const Color(0xFF94A3B8),
                                                  ),
                                                ),
                                              if (modified != null)
                                                Text(
                                                  _formatDate(modified),
                                                  style: GoogleFonts.rubik(
                                                    fontSize: 11.5,
                                                    color:
                                                        const Color(0xFF64748B),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 3-dot Menu
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                          Icons.more_vert_rounded,
                                          size: 18,
                                          color: Color(0xFF94A3B8)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      onSelected: (value) {
                                        if (value == 'open') {
                                          _openPdf(file.path);
                                        } else if (value == 'share') {
                                          _sharePdf(file);
                                        } else if (value == 'rename') {
                                          _renameSavedPdf(file);
                                        } else if (value == 'delete') {
                                          _deleteSavedPdf(file);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'open',
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons.visibility_outlined,
                                                  size: 18,
                                                  color: Color(0xFF2596BE)),
                                              const SizedBox(width: 10),
                                              Text('Open',
                                                  style: GoogleFonts.rubik(
                                                      fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'share',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.share_outlined,
                                                  size: 18,
                                                  color: Color(0xFF2596BE)),
                                              const SizedBox(width: 10),
                                              Text('Share',
                                                  style: GoogleFonts.rubik(
                                                      fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'rename',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.edit_outlined,
                                                  size: 18,
                                                  color: Color(0xFF64748B)),
                                              const SizedBox(width: 10),
                                              Text('Rename',
                                                  style: GoogleFonts.rubik(
                                                      fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuDivider(),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 18,
                                                  color: Color(0xFFE11D48)),
                                              const SizedBox(width: 10),
                                              Text(
                                                'Delete',
                                                style: GoogleFonts.rubik(
                                                  fontSize: 13,
                                                  color:
                                                      const Color(0xFFE11D48),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
