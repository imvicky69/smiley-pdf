import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/models/recent_file.dart';
import '../../../../core/services/library_folder_service.dart';
import '../../../../core/services/recent_files_service.dart';

class RecentFileCard extends StatelessWidget {
  final RecentFile file;
  final VoidCallback onOpen;

  const RecentFileCard({
    super.key,
    required this.file,
    required this.onOpen,
  });

  void _showFileInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                color: Color(0xFF2596BE), size: 22),
            const SizedBox(width: 8),
            Text(
              'Document Details',
              style: GoogleFonts.prompt(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Name', file.fileName),
            const SizedBox(height: 8),
            _infoRow('Size', file.formattedSize.isNotEmpty ? file.formattedSize : 'Unknown'),
            if (file.pageCount != null) ...[
              const SizedBox(height: 8),
              _infoRow('Pages', '${file.pageCount}'),
            ],
            const SizedBox(height: 8),
            _infoRow('Last Opened', file.formattedDate),
            const SizedBox(height: 8),
            _infoRow('Path', file.path, isPath: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.rubik(
                color: const Color(0xFF2596BE),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePdf(BuildContext context) async {
    try {
      final xFile = XFile(
        file.path,
        mimeType: 'application/pdf',
        name: file.fileName,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: file.fileName,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not share file: $e',
              style: GoogleFonts.rubik(fontSize: 13),
            ),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Widget _infoRow(String label, String value, {bool isPath = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.rubik(
            fontSize: 11,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.rubik(
            fontSize: isPath ? 11 : 13,
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w500,
          ),
          maxLines: isPath ? 3 : 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2596BE);
    const Color textDark = Color(0xFF1E293B);
    const Color textMuted = Color(0xFF64748B);

    final bool fileExists = file.exists;
    final bool hasThumbnail = file.thumbnailPath != null &&
        File(file.thumbnailPath!).existsSync();

    final cardContent = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          if (fileExists) {
            onOpen();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'File not found: "${file.fileName}". It may have been moved or deleted.',
                  style: GoogleFonts.rubik(fontSize: 13),
                ),
                backgroundColor: const Color(0xFFDC2626),
                action: SnackBarAction(
                  label: 'Remove',
                  textColor: Colors.white,
                  onPressed: () {
                    RecentFilesService.instance.removeRecent(file.path);
                  },
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Thumbnail or PDF Emblem
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 50,
                  height: 66,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                  ),
                  child: hasThumbnail
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(
                              File(file.thumbnailPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 1),
                                color: Colors.black.withValues(alpha: 0.45),
                                child: Text(
                                  'PDF',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.rubik(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : _buildFallbackIcon(),
                ),
              ),
              const SizedBox(width: 14),

              // Title and Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      file.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.prompt(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: fileExists ? textDark : const Color(0xFF94A3B8),
                        decoration: fileExists ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      file.metadataSummary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.rubik(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                    if (!fileExists) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 13, color: Color(0xFFE11D48)),
                          const SizedBox(width: 4),
                          Text(
                            'File missing or moved',
                            style: GoogleFonts.rubik(
                              fontSize: 11,
                              color: const Color(0xFFE11D48),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Options Menu & Quick Reopen Button
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    size: 20, color: Color(0xFF94A3B8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'open') {
                    if (fileExists) {
                      onOpen();
                    }
                  } else if (value == 'share') {
                    _sharePdf(context);
                  } else if (value == 'save_app') {
                    LibraryFolderService.instance
                        .savePdfToAppFolder(file.path)
                        .then((result) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.isAlreadySaved
                                ? 'This document is already in your Saved PDFs'
                                : result.success
                                    ? '✓ Saved to Smiley PDF Library'
                                    : 'Could not save file to app storage'),
                            backgroundColor: const Color(0xFF0D9488),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    });
                  } else if (value == 'info') {
                    _showFileInfo(context);
                  } else if (value == 'remove') {
                    RecentFilesService.instance.removeRecent(file.path);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'open',
                    enabled: fileExists,
                    child: Row(
                      children: [
                        const Icon(Icons.visibility_outlined,
                            size: 18, color: primaryBlue),
                        const SizedBox(width: 10),
                        Text(
                          'Open PDF',
                          style: GoogleFonts.rubik(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: fileExists ? textDark : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    enabled: fileExists,
                    child: Row(
                      children: [
                        const Icon(Icons.share_outlined,
                            size: 18, color: primaryBlue),
                        const SizedBox(width: 10),
                        Text(
                          'Share PDF',
                          style: GoogleFonts.rubik(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: fileExists ? textDark : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'save_app',
                    enabled: fileExists,
                    child: Row(
                      children: [
                        const Icon(Icons.bookmark_add_outlined,
                            size: 18, color: Color(0xFF0D9488)),
                        const SizedBox(width: 10),
                        Text(
                          'Save to Library',
                          style: GoogleFonts.rubik(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: fileExists ? textDark : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 10),
                        Text(
                          'Details',
                          style: GoogleFonts.rubik(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded,
                            size: 18, color: Color(0xFFE11D48)),
                        const SizedBox(width: 10),
                        Text(
                          'Remove from recents',
                          style: GoogleFonts.rubik(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFE11D48),
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

    return Dismissible(
      key: ValueKey('recent_${file.path}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE11D48),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 22),
            const SizedBox(width: 6),
            Text(
              'Remove',
              style: GoogleFonts.rubik(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        RecentFilesService.instance.removeRecent(file.path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${file.fileName}" from recents'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                RecentFilesService.instance.addRecent(
                  file.path,
                  pageCount: file.pageCount,
                );
              },
            ),
          ),
        );
      },
      child: cardContent,
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.picture_as_pdf_rounded,
            size: 26,
            color: Color(0xFF2596BE),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFF2596BE),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'PDF',
              style: GoogleFonts.rubik(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
