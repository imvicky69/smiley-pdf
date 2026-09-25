import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FolderCategory {
  final String id;
  final String name;
  final String subtitle;
  final String path;
  final bool exists;
  final bool requiresPermission;

  const FolderCategory({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.path,
    required this.exists,
    this.requiresPermission = false,
  });
}

class LibraryFolderService {
  LibraryFolderService._();
  static final LibraryFolderService instance = LibraryFolderService._();

  static const String _linkedFoldersPrefix = 'smiley_pdf_linked_folder_';

  /// Standard Play Store compliant storage permission check.
  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.storage.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking permission: $e');
      return false;
    }
  }

  /// Request standard storage permission.
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.storage.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      return false;
    }
  }

  /// Check if the user has permanently denied permission (to show open app settings).
  Future<bool> isPermanentlyDenied() async {
    if (!Platform.isAndroid) return false;
    try {
      return await Permission.storage.isPermanentlyDenied;
    } catch (_) {
      return false;
    }
  }

  /// Exclusive app folder for saved PDFs (always accessible).
  Future<Directory> getAppSavedDirectory() async {
    // 1. Try public Documents/Smiley PDF if external storage is granted
    try {
      if (await hasPermission()) {
        final publicDir = Directory('/storage/emulated/0/Documents/Smiley PDF');
        if (!publicDir.existsSync()) {
          publicDir.createSync(recursive: true);
        }
        return publicDir;
      }
    } catch (_) {}

    // 2. Fallback to app external files dir (always accessible without permission)
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final savedDir = Directory('${extDir.path}/Saved PDFs');
        if (!savedDir.existsSync()) {
          savedDir.createSync(recursive: true);
        }
        return savedDir;
      }
    } catch (_) {}

    // 3. Fallback to app doc dir
    final appDocDir = await getApplicationDocumentsDirectory();
    final savedDir = Directory('${appDocDir.path}/Saved PDFs');
    if (!savedDir.existsSync()) {
      savedDir.createSync(recursive: true);
    }
    return savedDir;
  }

  /// Copies any PDF (from cache, picker, etc.) into the exclusive app saved folder.
  Future<File?> savePdfToAppFolder(String sourcePath) async {
    try {
      final source = File(sourcePath);
      if (!source.existsSync()) return null;

      final savedDir = await getAppSavedDirectory();
      final fileName = source.path.split(RegExp(r'[\\/]')).last;
      String destinationPath = '${savedDir.path}/$fileName';

      int counter = 1;
      while (File(destinationPath).existsSync()) {
        final dotIndex = fileName.lastIndexOf('.');
        if (dotIndex > 0) {
          final base = fileName.substring(0, dotIndex);
          destinationPath = '${savedDir.path}/${base}_$counter.pdf';
        } else {
          destinationPath = '${savedDir.path}/${fileName}_$counter.pdf';
        }
        counter++;
      }

      return await source.copy(destinationPath);
    } catch (e) {
      debugPrint('Error saving PDF to app folder: $e');
      return null;
    }
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

    // 1. Exclusive App Saved PDFs (Requires NO permission)
    final savedDir = await getAppSavedDirectory();
    categories.add(FolderCategory(
      id: 'saved',
      name: 'Saved PDFs',
      subtitle: 'Exclusive app storage',
      path: savedDir.path,
      exists: true,
      requiresPermission: false,
    ));

    // 2. WhatsApp Documents (Auto-detects modern Android/media and legacy paths)
    final customWhatsApp = await getLinkedFolder('whatsapp');
    if (customWhatsApp != null && Directory(customWhatsApp).existsSync()) {
      categories.add(FolderCategory(
        id: 'whatsapp',
        name: 'WhatsApp',
        subtitle: 'Received & Sent',
        path: customWhatsApp,
        exists: true,
        requiresPermission: true,
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
        subtitle: 'Received & Sent',
        path: foundWhatsAppPath ?? whatsAppCandidates.first,
        exists: foundWhatsAppPath != null,
        requiresPermission: true,
      ));
    }

    // 3. Download Folder
    final customDownload = await getLinkedFolder('downloads');
    if (customDownload != null && Directory(customDownload).existsSync()) {
      categories.add(FolderCategory(
        id: 'downloads',
        name: 'Downloads',
        subtitle: 'Device downloads',
        path: customDownload,
        exists: true,
        requiresPermission: true,
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
        subtitle: 'Device downloads',
        path: foundDownload ?? downloadCandidates.first,
        exists: foundDownload != null,
        requiresPermission: true,
      ));
    }

    // 4. Documents Folder
    final customDocs = await getLinkedFolder('documents');
    if (customDocs != null && Directory(customDocs).existsSync()) {
      categories.add(FolderCategory(
        id: 'documents',
        name: 'Documents',
        subtitle: 'Device documents',
        path: customDocs,
        exists: true,
        requiresPermission: true,
      ));
    } else {
      const docsCandidate = '/storage/emulated/0/Documents';
      categories.add(FolderCategory(
        id: 'documents',
        name: 'Documents',
        subtitle: 'Device documents',
        path: docsCandidate,
        exists: Directory(docsCandidate).existsSync(),
        requiresPermission: true,
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
          await for (final entity
              in dir.list(recursive: false, followLinks: false)) {
            if (entity is File &&
                entity.path.toLowerCase().endsWith('.pdf')) {
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

  Future<File?> copyPdfToFolder(
      String sourceFilePath, String targetFolderPath) async {
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
          destinationPath = '$targetFolderPath/${fileName}_$counter.pdf';
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
