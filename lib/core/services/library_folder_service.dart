import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'recent_files_service.dart';

class SavePdfResult {
  final File? file;
  final bool isAlreadySaved;
  final bool success;

  const SavePdfResult({
    this.file,
    required this.isAlreadySaved,
    required this.success,
  });
}

class LibraryFolderService {
  LibraryFolderService._();
  static final LibraryFolderService instance = LibraryFolderService._();

  static const String defaultPdfName = 'Welcome to Smiley PDF.pdf';

  /// Notifier bumped whenever saved files are added, renamed, or deleted
  final ValueNotifier<int> savedChangeNotifier = ValueNotifier<int>(0);

  void _notifySavedChanged() {
    savedChangeNotifier.value++;
  }

  /// Exclusive app folder for saved PDFs (always accessible without permissions).
  Future<Directory> getAppSavedDirectory() async {
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final savedDir = Directory('${extDir.path}/Saved PDFs');
        if (!savedDir.existsSync()) {
          savedDir.createSync(recursive: true);
        }
        return savedDir;
      }
    } catch (e) {
      debugPrint('Error getting external storage dir: $e');
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final savedDir = Directory('${appDocDir.path}/Saved PDFs');
    if (!savedDir.existsSync()) {
      savedDir.createSync(recursive: true);
    }
    return savedDir;
  }

  /// Ensures the default welcome PDF guide is present in the saved folder.
  Future<File?> ensureDefaultPdfExists() async {
    try {
      final savedDir = await getAppSavedDirectory();
      final defaultFile = File('${savedDir.path}/$defaultPdfName');

      if (!defaultFile.existsSync() || defaultFile.lengthSync() == 0) {
        final byteData =
            await rootBundle.load('assets/documents/welcome_smiley_pdf.pdf');
        final bytes = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        await defaultFile.writeAsBytes(bytes, flush: true);
        debugPrint('[LibraryFolderService] Installed default welcome PDF');
        _notifySavedChanged();
      }
      return defaultFile;
    } catch (e) {
      debugPrint('[LibraryFolderService] Could not install default PDF: $e');
      return null;
    }
  }

  /// Returns all PDF files in the Saved PDFs directory, sorted by last modified descending.
  Future<List<File>> getSavedPdfs() async {
    try {
      await ensureDefaultPdfExists();

      final savedDir = await getAppSavedDirectory();
      if (!savedDir.existsSync()) return [];

      final List<File> pdfs = [];
      await for (final entity in savedDir.list(recursive: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
          pdfs.add(entity);
        }
      }

      // Sort newest first
      pdfs.sort((a, b) {
        try {
          return b.lastModifiedSync().compareTo(a.lastModifiedSync());
        } catch (_) {
          return 0;
        }
      });

      return pdfs;
    } catch (e) {
      debugPrint('[LibraryFolderService] Error getting saved PDFs: $e');
      return [];
    }
  }

  /// Checks if a file is already in the saved directory.
  /// Returns the existing saved File if found, or null.
  Future<File?> getMatchingSavedFile(String sourcePath) async {
    try {
      final source = File(sourcePath);
      final savedDir = await getAppSavedDirectory();
      if (!savedDir.existsSync()) return null;

      final normalizedSource = source.path.replaceAll('\\', '/');
      final normalizedSaved = savedDir.path.replaceAll('\\', '/');

      // 1. Direct check: the file is already inside the saved directory
      if (normalizedSource.startsWith(normalizedSaved)) {
        return source.existsSync() ? source : null;
      }

      if (!source.existsSync()) return null;
      final sourceSize = source.lengthSync();
      final fileName = source.path.split(RegExp(r'[\\/]')).last;

      // 2. Check if a saved file with exact same name exists and has identical size
      final exactCandidate = File('${savedDir.path}/$fileName');
      if (exactCandidate.existsSync() && exactCandidate.lengthSync() == sourceSize) {
        return exactCandidate;
      }

      // 3. Check if any numbered duplicate (e.g. document_1.pdf) has identical size and base name
      final dotIndex = fileName.lastIndexOf('.');
      final baseName = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;

      await for (final entity in savedDir.list(recursive: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
          final entityName = entity.path.split(RegExp(r'[\\/]')).last;
          if (entityName.startsWith(baseName) && entity.lengthSync() == sourceSize) {
            return entity;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error finding matching saved file: $e');
      return null;
    }
  }

  /// Returns true if the given file is already saved in the app's saved folder.
  Future<bool> isPdfSaved(String sourcePath) async {
    final match = await getMatchingSavedFile(sourcePath);
    return match != null;
  }

  /// Copies any PDF into the app's saved folder.
  /// If it is ALREADY saved, it returns the existing file with isAlreadySaved: true
  /// and DOES NOT create a duplicate copy!
  Future<SavePdfResult> savePdfToAppFolder(String sourcePath) async {
    try {
      final source = File(sourcePath);
      if (!source.existsSync()) {
        return const SavePdfResult(isAlreadySaved: false, success: false);
      }

      // 1. First check if it is already saved
      final existing = await getMatchingSavedFile(sourcePath);
      if (existing != null) {
        debugPrint('[LibraryFolderService] File already saved at: ${existing.path}');
        return SavePdfResult(file: existing, isAlreadySaved: true, success: true);
      }

      final savedDir = await getAppSavedDirectory();
      final fileName = source.path.split(RegExp(r'[\\/]')).last;
      String destinationPath = '${savedDir.path}/$fileName';

      // 2. If a different file exists with the same name, append counter
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

      final copiedFile = await source.copy(destinationPath);
      debugPrint('[LibraryFolderService] Saved new PDF to ${copiedFile.path}');
      _notifySavedChanged();
      return SavePdfResult(file: copiedFile, isAlreadySaved: false, success: true);
    } catch (e) {
      debugPrint('Error saving PDF to app folder: $e');
      return const SavePdfResult(isAlreadySaved: false, success: false);
    }
  }

  /// Removes a saved PDF corresponding to the source path.
  Future<bool> removeSavedPdfBySource(String sourcePath) async {
    try {
      final savedFile = await getMatchingSavedFile(sourcePath);
      if (savedFile != null && savedFile.existsSync()) {
        await savedFile.delete();
        debugPrint('[LibraryFolderService] Removed saved PDF: ${savedFile.path}');
        _notifySavedChanged();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error removing saved PDF by source: $e');
      return false;
    }
  }

  /// Renames a PDF in the saved folder.
  Future<bool> renamePdf(File file, String newFileName) async {
    try {
      final sanitizedName =
          newFileName.endsWith('.pdf') ? newFileName : '$newFileName.pdf';
      final parentDir = file.parent.path;
      final newPath = '$parentDir/$sanitizedName';

      if (File(newPath).existsSync()) {
        return false;
      }

      final oldPath = file.path;
      await file.rename(newPath);
      RecentFilesService.instance
          .updateFilePath(oldPath, newPath, newFileName: sanitizedName);
      _notifySavedChanged();
      return true;
    } catch (e) {
      debugPrint('Error renaming PDF: $e');
      return false;
    }
  }

  /// Deletes a PDF file.
  Future<bool> deletePdf(File file) async {
    try {
      if (file.existsSync()) {
        final path = file.path;
        await file.delete();
        RecentFilesService.instance.removeRecent(path);
        await RecentFilesService.instance.purgeMissingFiles();
        _notifySavedChanged();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting PDF: $e');
    }
    return false;
  }

  /// Helper to copy a PDF to a specific destination folder.
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
