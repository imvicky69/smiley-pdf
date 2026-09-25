import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdfrx/pdfrx.dart';

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

  @override
  void dispose() {
    _pageNumber.dispose();
    _pageCount.dispose();
    super.dispose();
  }

  String get _fileName {
    final name = widget.filePath.split(RegExp(r'[\\/]')).last;
    return name.isNotEmpty ? name : 'Document';
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _fileName,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.prompt(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: _pageCount,
                    builder: (_, count, _) {
                      if (count == 0) return const SizedBox.shrink();
                      return ValueListenableBuilder<int>(
                        valueListenable: _pageNumber,
                        builder: (_, page, _) => Text(
                          'Page $page of $count',
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
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: PdfViewer.file(
        widget.filePath,
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

          // Page change fires only when the visible page actually changes —
          // zero rebuilds during zoom/pan, only on page transitions
          onPageChanged: (pageNumber) {
            if (pageNumber != null) {
              _pageNumber.value = pageNumber;
              // Grab pageCount from controller on first page change (doc is ready)
              if (_pageCount.value == 0 && _controller.isReady) {
                _pageCount.value = _controller.pageCount;
              }
            }
          },
          // Text selection is disabled by default (textSelectionParams not set)
          // — keeps gesture handling lightweight
        ),
      ),
    );
  }
}

