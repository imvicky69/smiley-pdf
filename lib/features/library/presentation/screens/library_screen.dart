import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
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

class _LibraryScreenState extends State<LibraryScreen>
    with WidgetsBindingObserver {
  bool _hasPermission = false;
  bool _isLoading = true;
  List<FolderCategory> _folders = [];
  int _selectedFolderIndex = 0;
  List<File> _currentFiles = [];
  bool _isLoadingFiles = false;

  // Track counts per folder category
  final Map<String, int> _folderCounts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionAndLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndLoad();
    }
  }

  Future<void> _checkPermissionAndLoad() async {
    setState(() => _isLoading = true);
    final hasPerm = await LibraryFolderService.instance.hasPermission();
    final folders = await LibraryFolderService.instance.getDetectedFolders();

    if (!mounted) return;
    setState(() {
      _hasPermission = hasPerm;
      _folders = folders;
      _isLoading = false;
    });

    await _loadFilesInSelectedFolder();
    _refreshFolderCounts();
  }

  Future<void> _refreshFolderCounts() async {
    for (final folder in _folders) {
      if (!folder.requiresPermission || _hasPermission) {
        final count =
            (await LibraryFolderService.instance.getPdfsInFolder(folder.path))
                .length;
        if (mounted) {
          setState(() {
            _folderCounts[folder.id] = count;
          });
        }
      }
    }
  }

  Future<void> _requestPermission() async {
    final granted = await LibraryFolderService.instance.requestPermission();
    if (!mounted) return;

    setState(() {
      _hasPermission = granted;
    });

    if (granted) {
      await _loadFilesInSelectedFolder();
      _refreshFolderCounts();
    } else {
      final isPermDenied =
          await LibraryFolderService.instance.isPermanentlyDenied();
      if (!mounted) return;
      if (isPermDenied) {
        _showSettingsDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Storage permission is required to read WhatsApp and device folders.',
              style: GoogleFonts.rubik(fontSize: 13),
            ),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Permission Needed',
          style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Storage permission was previously denied. Please enable it in Settings to let Smiley PDF view your WhatsApp and Downloads folders.',
          style: GoogleFonts.rubik(fontSize: 14, color: const Color(0xFF64748B)),
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
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2596BE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Open Settings',
              style: GoogleFonts.rubik(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadFilesInSelectedFolder() async {
    if (_folders.isEmpty) return;
    final folder = _folders[_selectedFolderIndex];

    if (folder.requiresPermission && !_hasPermission) {
      setState(() {
        _currentFiles = [];
        _isLoadingFiles = false;
      });
      return;
    }

    setState(() => _isLoadingFiles = true);
    final files =
        await LibraryFolderService.instance.getPdfsInFolder(folder.path);
    if (!mounted) return;

    setState(() {
      _currentFiles = files;
      _folderCounts[folder.id] = files.length;
      _isLoadingFiles = false;
    });
  }

  Future<void> _linkCustomFolder() async {
    final folder = _folders.isNotEmpty ? _folders[_selectedFolderIndex] : null;
    final selectedDir = await FilePicker.getDirectoryPath(
      dialogTitle: 'Select ${folder?.name ?? "PDF"} Folder',
    );

    if (selectedDir != null) {
      if (folder != null) {
        await LibraryFolderService.instance
            .saveLinkedFolder(folder.id, selectedDir);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Linked folder: $selectedDir'),
            backgroundColor: const Color(0xFF0D9488),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _checkPermissionAndLoad();
      }
    }
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

  Future<void> _renamePdf(File file) async {
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
              backgroundColor: const Color(0xFF2596BE),
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
          _loadFilesInSelectedFolder();
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

  Future<void> _deletePdf(File file) async {
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
          'Are you sure you want to permanently delete "$fileName" from your device?',
          style: GoogleFonts.rubik(fontSize: 14, color: const Color(0xFF64748B)),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "$fileName"'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
          _loadFilesInSelectedFolder();
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

  Future<void> _importPdfToCurrentFolder() async {
    if (_folders.isEmpty) return;
    final folder = _folders[_selectedFolderIndex];

    final List<PlatformFile> files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (files.isNotEmpty && files.first.path != null) {
      final copied = await LibraryFolderService.instance
          .copyPdfToFolder(files.first.path!, folder.path);
      if (mounted) {
        if (copied != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to ${folder.name}'),
              backgroundColor: const Color(0xFF0D9488),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
          _loadFilesInSelectedFolder();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to copy file into folder.')),
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
    const Color textDark = Color(0xFF1E293B);

    final selectedFolder =
        _folders.isNotEmpty ? _folders[_selectedFolderIndex] : null;
    final bool isFolderBlockedByPermission =
        selectedFolder?.requiresPermission == true && !_hasPermission;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(
          'Library',
          style: GoogleFonts.prompt(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Refresh',
            onPressed: () {
              _checkPermissionAndLoad();
            },
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prominent Category Tiles
                if (_folders.isNotEmpty) _buildCategoryTiles(primaryBlue),

                const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),

                // Content list or permission prompt
                Expanded(
                  child: isFolderBlockedByPermission
                      ? _buildPermissionPrompt(selectedFolder!, primaryBlue)
                      : _isLoadingFiles
                          ? const Center(child: CircularProgressIndicator())
                          : _currentFiles.isEmpty
                              ? _buildEmptyFolderState(
                                  selectedFolder!, primaryBlue)
                              : _buildFileList(primaryBlue),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryTiles(Color primaryBlue) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FOLDERS',
                style: GoogleFonts.prompt(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.8,
                ),
              ),
              InkWell(
                onTap: _linkCustomFolder,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.add_link_rounded,
                          size: 14, color: Color(0xFF2596BE)),
                      const SizedBox(width: 4),
                      Text(
                        'Link Folder',
                        style: GoogleFonts.rubik(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2596BE),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _folders.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final folder = _folders[index];
                final isSelected = _selectedFolderIndex == index;
                final count = _folderCounts[folder.id];
                final isLocked = folder.requiresPermission && !_hasPermission;

                Color themeColor;
                IconData icon;
                if (folder.id == 'saved') {
                  themeColor = const Color(0xFF2596BE);
                  icon = Icons.bookmark_added_rounded;
                } else if (folder.id == 'whatsapp') {
                  themeColor = const Color(0xFF22C55E);
                  icon = Icons.chat_rounded;
                } else if (folder.id == 'downloads') {
                  themeColor = const Color(0xFF0284C7);
                  icon = Icons.download_rounded;
                } else {
                  themeColor = const Color(0xFF8B5CF6);
                  icon = Icons.description_rounded;
                }

                return Material(
                  color: isSelected
                      ? themeColor.withValues(alpha: 0.08)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () {
                      if (_selectedFolderIndex != index) {
                        setState(() => _selectedFolderIndex = index);
                        _loadFilesInSelectedFolder();
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 130,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? themeColor
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.6 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: themeColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  icon,
                                  color: themeColor,
                                  size: 18,
                                ),
                              ),
                              if (isLocked)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.lock_rounded,
                                    size: 12,
                                    color: Color(0xFFDC2626),
                                  ),
                                )
                              else if (count != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: themeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: GoogleFonts.rubik(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: themeColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                folder.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.prompt(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                folder.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.rubik(
                                  fontSize: 9.5,
                                  color: const Color(0xFF64748B),
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

  Widget _buildPermissionPrompt(FolderCategory folder, Color primaryBlue) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_shared_rounded,
                size: 40,
                color: Color(0xFF16A34A),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Permission Required for ${folder.name}',
              textAlign: TextAlign.center,
              style: GoogleFonts.prompt(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                folder.id == 'whatsapp'
                    ? 'Allow Smiley PDF to access your device storage to automatically read and display both received and sent WhatsApp PDFs.'
                    : 'Allow Smiley PDF storage access to automatically browse and manage PDFs in your ${folder.name} folder.',
                textAlign: TextAlign.center,
                style: GoogleFonts.rubik(
                  fontSize: 13.5,
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _requestPermission,
                icon: const Icon(Icons.lock_open_rounded, size: 18),
                label: const Text('Grant Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.rubik(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: widget.onPickManual,
              icon: const Icon(Icons.folder_open_rounded, size: 16),
              label: const Text('Pick PDF Manually (No Permission)'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                textStyle: GoogleFonts.rubik(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFolderState(FolderCategory folder, Color primaryBlue) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.description_outlined,
                  size: 32, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            Text(
              'No PDFs in ${folder.name}',
              style: GoogleFonts.prompt(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              folder.id == 'saved'
                  ? 'PDFs saved or imported in Smiley PDF will appear here in your exclusive app storage.'
                  : 'Import a PDF or link a specific folder path to view files here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.rubik(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _importPdfToCurrentFolder,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(folder.id == 'saved' ? 'Save PDF Here' : 'Add PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: GoogleFonts.rubik(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (folder.id != 'saved') ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _linkCustomFolder,
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    label: const Text('Change Path'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryBlue,
                      side: BorderSide(color: primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: GoogleFonts.rubik(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList(Color primaryBlue) {
    final folder = _folders[_selectedFolderIndex];

    return Column(
      children: [
        // Action header: Count & Import button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currentFiles.length} ${_currentFiles.length == 1 ? "document" : "documents"} in ${folder.name}',
                style: GoogleFonts.rubik(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              TextButton.icon(
                onPressed: _importPdfToCurrentFolder,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add PDF'),
                style: TextButton.styleFrom(
                  foregroundColor: primaryBlue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: GoogleFonts.rubik(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Files list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            itemCount: _currentFiles.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final file = _currentFiles[index];
              final fileName = file.path.split(RegExp(r'[\\/]')).last;
              final isSent =
                  LibraryFolderService.instance.isSentFile(file.path);

              int size = 0;
              DateTime? modified;
              try {
                size = file.lengthSync();
                modified = file.lastModifiedSync();
              } catch (_) {}

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => _openPdf(file.path),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFFE2E8F0), width: 1),
                    ),
                    child: Row(
                      children: [
                        // PDF icon
                        Container(
                          width: 40,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFE2E8F0), width: 0.8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.picture_as_pdf_rounded,
                                  color: Color(0xFF2596BE), size: 20),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2596BE),
                                  borderRadius: BorderRadius.circular(3),
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
                        const SizedBox(width: 12),

                        // File details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.prompt(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (isSent) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: const Color(0xFFBFDBFE),
                                            width: 0.8),
                                      ),
                                      child: Text(
                                        'Sent',
                                        style: GoogleFonts.rubik(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  if (size > 0)
                                    Text(
                                      _formatSize(size),
                                      style: GoogleFonts.rubik(
                                        fontSize: 11.5,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  if (size > 0 && modified != null)
                                    Text(
                                      ' • ',
                                      style: GoogleFonts.rubik(
                                        fontSize: 11.5,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  if (modified != null)
                                    Text(
                                      _formatDate(modified),
                                      style: GoogleFonts.rubik(
                                        fontSize: 11.5,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // CRUD Actions Popup Menu
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded,
                              size: 18, color: Color(0xFF94A3B8)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            if (value == 'open') {
                              _openPdf(file.path);
                            } else if (value == 'share') {
                              _sharePdf(file);
                            } else if (value == 'rename') {
                              _renamePdf(file);
                            } else if (value == 'delete') {
                              _deletePdf(file);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'open',
                              child: Row(
                                children: [
                                  const Icon(Icons.visibility_outlined,
                                      size: 18, color: Color(0xFF2596BE)),
                                  const SizedBox(width: 10),
                                  Text('Open',
                                      style: GoogleFonts.rubik(fontSize: 13)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  const Icon(Icons.share_outlined,
                                      size: 18, color: Color(0xFF2596BE)),
                                  const SizedBox(width: 10),
                                  Text('Share',
                                      style: GoogleFonts.rubik(fontSize: 13)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'rename',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_outlined,
                                      size: 18, color: Color(0xFF64748B)),
                                  const SizedBox(width: 10),
                                  Text('Rename',
                                      style: GoogleFonts.rubik(fontSize: 13)),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline_rounded,
                                      size: 18, color: Color(0xFFE11D48)),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Delete',
                                    style: GoogleFonts.rubik(
                                      fontSize: 13,
                                      color: const Color(0xFFE11D48),
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
    );
  }
}
