import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FolderCategory {
  final String id;
  final String name;
  final String path;
  final bool exists;
  final bool isCustomLinked;

  const FolderCategory({
    required this.id,
    required this.name,
    required this.path,
    required this.exists,
    this.isCustomLinked = false,
  });
}

class LibraryFolderService {
  LibraryFolderService._();
  static final LibraryFolderService instance = LibraryFolderService._();

  static const String _linkedFoldersPrefix = 'smiley_pdf_linked_folder_';

  /// Play Store compliant permission check.
  /// Uses standard storage permission (no MANAGE_EXTERNAL_STORAGE).
  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final storage = await Permission.storage.status;
      if (storage.isGranted) return true;

      // On some Android 11+ devices, test if public folder is directly accessible
      final testDir = Directory('/storage/emulated/0/Download');
      if (testDir.existsSync()) {
        try {
          testDir.listSync();
          return true;
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error checking permission: $e');
    }
    return false;
  }

  /// Request standard storage permission (100% Google Play Store safe).
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final storage = await Permission.storage.request();
      if (storage.isGranted) return true;

      // Check if direct access works regardless
      final testDir = Directory('/storage/emulated/0/Download');
      if (testDir.existsSync()) {
        try {
          testDir.listSync();
          return true;
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error requesting permission: $e');
    }
    return false;
  }

  Future<void> saveLinkedFolder(String id, String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_linkedFoldersPrefix$id', path);
    } catch (e) {
      debugPrint('Error saving linked folder: $e');
    }
  }

  Future<String?> getLinkedFolder(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_linkedFoldersPrefix$id');
    } catch (e) {
      return null;
    }
  }

  Future<List<FolderCategory>> getDetectedFolders() async {
    final List<FolderCategory> categories = [];

    // 1. Download Folder
    final customDownload = await getLinkedFolder('downloads');
    if (customDownload != null && Directory(customDownload).existsSync()) {
      categories.add(FolderCategory(
        id: 'downloads',
        name: 'Downloads',
        path: customDownload,
        exists: true,
        isCustomLinked: true,
      ));
    } else {
      final downloadCandidates = [
        '/storage/emulated/0/Download',
        '/sdcard/Download',
      ];
      String? foundDownload;
      for (final p in downloadCandidates) {
        if (Directory(p).existsSync()) {
          foundDownload = p;
          break;
        }
      }
      categories.add(FolderCategory(
        id: 'downloads',
        name: 'Downloads',
        path: foundDownload ?? downloadCandidates.first,
        exists: foundDownload != null,
      ));
    }

    // 2. WhatsApp Documents (Auto-detects modern scoped path & legacy path)
    final customWhatsApp = await getLinkedFolder('whatsapp');
    if (customWhatsApp != null && Directory(customWhatsApp).existsSync()) {
      categories.add(FolderCategory(
        id: 'whatsapp',
        name: 'WhatsApp',
        path: customWhatsApp,
        exists: true,
        isCustomLinked: true,
      ));
    } else {
      final whatsAppCandidates = [
        '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Documents',
        '/storage/emulated/0/WhatsApp/Media/WhatsApp Documents',
      ];
      String? foundWhatsAppPath;
      for (final p in whatsAppCandidates) {
        if (Directory(p).existsSync()) {
          foundWhatsAppPath = p;
          break;
        }
      }
      categories.add(FolderCategory(
        id: 'whatsapp',
        name: 'WhatsApp',
        path: foundWhatsAppPath ?? whatsAppCandidates.first,
        exists: foundWhatsAppPath != null,
      ));
    }

    // 3. WhatsApp Business (Optional)
    final customWb = await getLinkedFolder('whatsapp_business');
    if (customWb != null && Directory(customWb).existsSync()) {
      categories.add(FolderCategory(
        id: 'whatsapp_business',
        name: 'WhatsApp Business',
        path: customWb,
        exists: true,
        isCustomLinked: true,
      ));
    } else {
      final wbCandidates = [
        '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/WhatsApp Business Documents',
        '/storage/emulated/0/WhatsApp Business/Media/WhatsApp Business Documents',
      ];
      String? foundWb;
      for (final p in wbCandidates) {
        if (Directory(p).existsSync()) {
          foundWb = p;
          break;
        }
      }
      if (foundWb != null) {
        categories.add(FolderCategory(
          id: 'whatsapp_business',
          name: 'WhatsApp Business',
          path: foundWb,
          exists: true,
        ));
      }
    }

    // 4. Documents Folder
    final customDocs = await getLinkedFolder('documents');
    if (customDocs != null && Directory(customDocs).existsSync()) {
      categories.add(FolderCategory(
        id: 'documents',
        name: 'Documents',
        path: customDocs,
        exists: true,
        isCustomLinked: true,
      ));
    } else {
      const docsCandidate = '/storage/emulated/0/Documents';
      categories.add(FolderCategory(
        id: 'documents',
        name: 'Documents',
        path: docsCandidate,
        exists: Directory(docsCandidate).existsSync(),
      ));
    }

    return categories;
  }

  /// Scans folder AND subfolders (such as Sent and Private for WhatsApp)
  /// and mixes them together into a unified list.
  Future<List<File>> getPdfsInFolder(String folderPath) async {
    try {
      final rootDir = Directory(folderPath);
      if (!rootDir.existsSync()) return [];

      final List<File> pdfFiles = [];

      Future<void> scanDirectory(Directory dir) async {
        if (!dir.existsSync()) return;
        try {
          await for (final entity in dir.list(recursive: false, followLinks: false)) {
            if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
              pdfFiles.add(entity);
            }
          }
        } catch (e) {
          debugPrint('Error scanning ${dir.path}: $e');
        }
      }

      // 1. Scan primary folder (Received documents)
      await scanDirectory(rootDir);

      // 2. Scan "Sent" subfolder if present (e.g. for WhatsApp sent PDFs)
      final sentDir = Directory('$folderPath/Sent');
      if (sentDir.existsSync()) {
        await scanDirectory(sentDir);
      }

      // 3. Scan "Private" subfolder if present (e.g. for WhatsApp private chats)
      final privateDir = Directory('$folderPath/Private');
      if (privateDir.existsSync()) {
        await scanDirectory(privateDir);
      }

      // Sort by last modified date, newest first
      pdfFiles.sort((a, b) {
        try {
          return b.lastModifiedSync().compareTo(a.lastModifiedSync());
        } catch (_) {
          return 0;
        }
      });

      return pdfFiles;
    } catch (e) {
      debugPrint('Error listing PDFs in $folderPath: $e');
      return [];
    }
  }

  /// Helper to check if a PDF is from the WhatsApp Sent folder
  bool isSentFile(String filePath) {
    return filePath.contains('/Sent/') || filePath.contains('\\Sent\\');
  }

  Future<bool> renamePdf(File file, String newFileName) async {
    try {
      final sanitizedName =
          newFileName.endsWith('.pdf') ? newFileName : '$newFileName.pdf';
      final parentDir = file.parent.path;
      final newPath = '$parentDir/$sanitizedName';

      if (File(newPath).existsSync()) {
        return false;
      }

      await file.rename(newPath);
      return true;
    } catch (e) {
      debugPrint('Error renaming PDF: $e');
      return false;
    }
  }

  Future<bool> deletePdf(File file) async {
    try {
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting PDF: $e');
    }
    return false;
  }

  Future<File?> copyPdfToFolder(String sourceFilePath, String targetFolderPath) async {
    try {
      final source = File(sourceFilePath);
      if (!source.existsSync()) return null;

      final targetDir = Directory(targetFolderPath);
      if (!targetDir.existsSync()) {
        await targetDir.create(recursive: true);
      }

      final fileName = source.path.split(RegExp(r'[\\/]')).last;
      String destinationPath = '$targetFolderPath/$fileName';

      int counter = 1;
      while (File(destinationPath).existsSync()) {
        final dotIndex = fileName.lastIndexOf('.');
        if (dotIndex > 0) {
          final base = fileName.substring(0, dotIndex);
          destinationPath = '$targetFolderPath/${base}_$counter.pdf';
        } else {
          destinationPath = '$targetFolderPath/${fileName}_$counter';
        }
        counter++;
      }

      return await source.copy(destinationPath);
    } catch (e) {
      debugPrint('Error copying PDF: $e');
      return null;
    }
  }
}
