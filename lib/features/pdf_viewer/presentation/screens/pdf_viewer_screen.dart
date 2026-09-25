import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatelessWidget {
  final String filePath;

  const PdfViewerScreen({super.key, required this.filePath});

  String get _fileName {
    final name = filePath.split(RegExp(r'[\\/]')).last;
    return name.isNotEmpty ? name : 'Document';
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
              child: Text(
                _fileName,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.prompt(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
            ),
            const SizedBox(width: 16),
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
      body: SfPdfViewer.file(File(filePath)),
    );
  }
}
