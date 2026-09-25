import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class FolderCategory {
  final String id;
  final String name;
  final String path;
  final bool exists;

  const FolderCategory({
    required this.id,
    required this.name,
    required this.path,
    required this.exists,
  });
}

class LibraryFolderService {
  LibraryFolderService._();
  static final LibraryFolderService instance = LibraryFolderService._();

  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final manage = await Permission.manageExternalStorage.status;
      if (manage.isGranted) return true;

      final storage = await Permission.storage.status;
      if (storage.isGranted) return true;
    } catch (e) {
      debugPrint('Error checking permission: $e');
    }
    return false;
  }

  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      // For Android 11+ (API 30+)
      final manage = await Permission.manageExternalStorage.request();
      if (manage.isGranted) return true;

      // For Android <= 10
      final storage = await Permission.storage.request();
      return storage.isGranted;
    } catch (e) {
      debugPrint('Error requesting permission: $e');
    }
    return false;
  }

  List<FolderCategory> getDetectedFolders() {
    final List<FolderCategory> categories = [];

    // 1. Download Folder
    final downloadCandidates = [
      '/storage/emulated/0/Download',
      '/sdcard/Download',
    ];
    for (final p in downloadCandidates) {
      final d = Directory(p);
      if (d.existsSync()) {
        categories.add(FolderCategory(
          id: 'downloads',
          name: 'Downloads',
          path: d.path,
          exists: true,
        ));
        break;
      }
    }
    if (!categories.any((c) => c.id == 'downloads')) {
      categories.add(const FolderCategory(
        id: 'downloads',
        name: 'Downloads',
        path: '/storage/emulated/0/Download',
        exists: false,
      ));
    }

    // 2. WhatsApp Documents
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

    // 3. WhatsApp Business (Optional)
    final wbCandidate =
        '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/WhatsApp Business Documents';
    if (Directory(wbCandidate).existsSync()) {
      categories.add(FolderCategory(
        id: 'whatsapp_business',
        name: 'WhatsApp Business',
        path: wbCandidate,
        exists: true,
      ));
    }

    // 4. Documents Folder
    final docsCandidate = '/storage/emulated/0/Documents';
    categories.add(FolderCategory(
      id: 'documents',
      name: 'Documents',
      path: docsCandidate,
      exists: Directory(docsCandidate).existsSync(),
    ));

    return categories;
  }

  Future<List<File>> getPdfsInFolder(String folderPath) async {
    try {
      final dir = Directory(folderPath);
      if (!dir.existsSync()) return [];

      final List<File> pdfFiles = [];
      await for (final entity in dir.list(recursive: false, followLinks: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
          pdfFiles.add(entity);
        }
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

  Future<bool> renamePdf(File file, String newFileName) async {
    try {
      final sanitizedName =
          newFileName.endsWith('.pdf') ? newFileName : '$newFileName.pdf';
      final parentDir = file.parent.path;
      final newPath = '$parentDir/$sanitizedName';

      if (File(newPath).existsSync()) {
        return false; // Already exists
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

      // Avoid overwriting
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
