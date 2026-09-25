import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickToolsSection extends StatelessWidget {
  const QuickToolsSection({super.key});

  void _showComingSoonSnackBar(BuildContext context, String toolName, String description) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$toolName • Coming Soon',
                    style: GoogleFonts.prompt(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.rubik(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Tools',
                style: GoogleFonts.prompt(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2596BE).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'UPCOMING',
                  style: GoogleFonts.rubik(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2596BE),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // OCR Tool
              Expanded(
                child: _buildToolCard(
                  context: context,
                  title: 'OCR',
                  subtitle: 'Extract text',
                  icon: Icons.document_scanner_rounded,
                  accentColor: const Color(0xFF6366F1),
                  bgColor: const Color(0xFFEEF2FF),
                  onTap: () => _showComingSoonSnackBar(
                    context,
                    'OCR Text Scanner',
                    'Extract and copy text from any scanned PDF.',
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Scan Document Tool
              Expanded(
                child: _buildToolCard(
                  context: context,
                  title: 'Scan Doc',
                  subtitle: 'To PDF',
                  icon: Icons.camera_enhance_rounded,
                  accentColor: const Color(0xFF0D9488),
                  bgColor: const Color(0xFFF0FDFA),
                  onTap: () => _showComingSoonSnackBar(
                    context,
                    'Scan Document',
                    'Capture paper pages with camera and convert to PDF.',
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Protect PDF Tool
              Expanded(
                child: _buildToolCard(
                  context: context,
                  title: 'Protect',
                  subtitle: 'Password',
                  icon: Icons.lock_outline_rounded,
                  accentColor: const Color(0xFFE11D48),
                  bgColor: const Color(0xFFFFF1F2),
                  onTap: () => _showComingSoonSnackBar(
                    context,
                    'Protect PDF',
                    'Encrypt your sensitive PDFs with strong passwords.',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'SOON',
                      style: GoogleFonts.rubik(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.prompt(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.rubik(
                  fontSize: 10.5,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
