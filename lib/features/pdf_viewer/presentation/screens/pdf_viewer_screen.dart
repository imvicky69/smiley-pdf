import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/library_folder_service.dart';
import '../../../../core/services/recent_files_service.dart';

class PdfViewerScreen extends StatefulWidget {
  final String filePath;

  const PdfViewerScreen({super.key, required this.filePath});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  // PdfViewerController extends ValueListenable<Matrix4> — no dispose() needed
  final _controller = PdfViewerController();

  // ValueNotifiers — zero setState, surgical update only for page counter
  final _pageNumber = ValueNotifier<int>(1);
  final _pageCount = ValueNotifier<int>(0);

  late String _currentFilePath;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _currentFilePath = widget.filePath;
    _checkSavedStatus();
    LibraryFolderService.instance.savedChangeNotifier
        .addListener(_checkSavedStatus);
  }

  @override
  void dispose() {
    LibraryFolderService.instance.savedChangeNotifier
        .removeListener(_checkSavedStatus);
    _pageNumber.dispose();
    _pageCount.dispose();
    super.dispose();
  }

  Future<void> _checkSavedStatus() async {
    final saved =
        await LibraryFolderService.instance.isPdfSaved(_currentFilePath);
    if (mounted && saved != _isSaved) {
      setState(() {
        _isSaved = saved;
      });
    }
  }

  String get _fileName {
    final name = _currentFilePath.split(RegExp(r'[\\/]')).last;
    return name.isNotEmpty ? name : 'Document';
  }

  /// Direct 1-tap save/unsave toggle with instant toast (zero extra steps)
  Future<void> _handleSavePressed() async {
    if (_isSaved) {
      // Direct unsave
      await LibraryFolderService.instance
          .removeSavedPdfBySource(_currentFilePath);
      if (mounted) {
        setState(() => _isSaved = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from Saved PDFs'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Direct save
      final result = await LibraryFolderService.instance
          .savePdfToAppFolder(_currentFilePath);
      if (mounted) {
        if (result.success) {
          setState(() => _isSaved = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.isAlreadySaved
                  ? 'Already in your Saved PDFs'
                  : '✓ Saved to Smiley PDF Library'),
              backgroundColor: const Color(0xFF0D9488),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not save PDF to app storage'),
              backgroundColor: Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  /// Opens the modal showing document metadata and editable name
  void _showDocumentDetailsAndRenameModal() {
    final file = File(_currentFilePath);
    final exists = file.existsSync();
    final size = exists ? file.lengthSync() : 0;
    final modified = exists ? file.lastModifiedSync() : null;

    final nameWithoutExt = _fileName.toLowerCase().endsWith('.pdf')
        ? _fileName.substring(0, _fileName.length - 4)
        : _fileName;

    final nameController = TextEditingController(text: nameWithoutExt);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFF2596BE), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Document Details',
                      style: GoogleFonts.prompt(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                if (_isSaved)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Saved',
                      style: GoogleFonts.rubik(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // Editable Name Section
            Text(
              'RENAME DOCUMENT',
              style: GoogleFonts.prompt(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameController,
                            style: GoogleFonts.rubik(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E293B),
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '.pdf',
                            style: GoogleFonts.rubik(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final newBase = nameController.text.trim();
                    if (newBase.isEmpty || newBase == nameWithoutExt) {
                      return;
                    }
                    Navigator.pop(ctx);
                    await _renameCurrentDocument(newBase);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2596BE),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  child: Text(
                    'Rename',
                    style: GoogleFonts.rubik(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Metadata Cards
            Text(
              'METADATA',
              style: GoogleFonts.prompt(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _metadataRow(
                    'Pages',
                    '${_pageCount.value} ${_pageCount.value == 1 ? "page" : "pages"}',
                    Icons.auto_stories_rounded,
                  ),
                  const Divider(color: Color(0xFFE2E8F0), height: 16),
                  _metadataRow(
                    'File Size',
                    _formatSize(size),
                    Icons.sd_storage_rounded,
                  ),
                  if (modified != null) ...[
                    const Divider(color: Color(0xFFE2E8F0), height: 16),
                    _metadataRow(
                      'Modified',
                      _formatFullDate(modified),
                      Icons.calendar_today_rounded,
                    ),
                  ],
                  const Divider(color: Color(0xFFE2E8F0), height: 16),
                  _metadataRow(
                    'Storage',
                    _isSaved ? 'Smiley PDF App Storage' : 'Device Storage',
                    Icons.folder_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Path view
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded,
                      size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentFilePath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.rubik(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _renameCurrentDocument(String newBaseName) async {
    final file = File(_currentFilePath);
    if (!file.existsSync()) return;

    final sanitizedName = '$newBaseName.pdf';
    final parentDir = file.parent.path;
    final newPath = '$parentDir/$sanitizedName';

    if (File(newPath).existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A file with this name already exists.'),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final oldPath = _currentFilePath;
      await file.rename(newPath);

      if (mounted) {
        setState(() {
          _currentFilePath = newPath;
        });
      }

      await RecentFilesService.instance.updateFilePath(
        oldPath,
        newPath,
        newFileName: sanitizedName,
      );

      LibraryFolderService.instance.savedChangeNotifier.value++;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Renamed to "$sanitizedName"'),
            backgroundColor: const Color(0xFF0D9488),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error renaming PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not rename file: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute $period';
  }

  Widget _metadataRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.rubik(
            fontSize: 12.5,
            color: const Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.rubik(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2596BE);
    const Color textDark = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
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
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/images/appIcon_foreground.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: _showDocumentDetailsAndRenameModal,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _fileName,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.prompt(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_note_rounded,
                              size: 17, color: Color(0xFF94A3B8)),
                        ],
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: _pageCount,
                        builder: (_, count, _) {
                          if (count == 0) return const SizedBox.shrink();
                          return ValueListenableBuilder<int>(
                            valueListenable: _pageNumber,
                            builder: (_, page, _) => Text(
                              'Page $page of $count • Tap for details',
                              style: GoogleFonts.rubik(
                                fontSize: 11,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 21),
            tooltip: 'Share PDF',
            onPressed: () async {
              try {
                final file = File(_currentFilePath);
                if (file.existsSync()) {
                  await SharePlus.instance.share(
                    ShareParams(
                      files: [
                        XFile(file.path,
                            mimeType: 'application/pdf', name: _fileName)
                      ],
                      subject: _fileName,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not share: $e'),
                      backgroundColor: const Color(0xFFDC2626),
                    ),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: Icon(
              _isSaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color:
                  _isSaved ? const Color(0xFF0D9488) : const Color(0xFF64748B),
              size: 23,
            ),
            tooltip: _isSaved ? 'Unsave from Library' : 'Save to Library',
            onPressed: _handleSavePressed,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: PdfViewer.file(
        _currentFilePath,
        key: ValueKey(_currentFilePath),
        controller: _controller,
        params: PdfViewerParams(
          // PDFium renders natively off the UI thread — zero Flutter paint overhead
          backgroundColor: const Color(0xFFF1F5F9),
          margin: 8,

          // Clamp zoom using the non-deprecated API
          sizeDelegateProvider: PdfViewerSizeDelegateProviderLegacy(
            minScale: 0.8,
            maxScale: 5.0,
          ),

          // Document ready callback: immediate accurate page count
          onViewerReady: (document, controller) {
            final count = document.pages.length;
            _pageCount.value = count;
            RecentFilesService.instance
                .updatePageCount(_currentFilePath, count);
          },

          // Page change fires only when the visible page actually changes
          onPageChanged: (pageNumber) {
            if (pageNumber != null) {
              _pageNumber.value = pageNumber;
              if (_pageCount.value == 0 && _controller.isReady) {
                _pageCount.value = _controller.pageCount;
              }
            }
          },
        ),
      ),
    );
  }
}
