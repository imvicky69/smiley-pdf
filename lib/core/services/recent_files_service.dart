import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/recent_file.dart';

class RecentFilesService {
  RecentFilesService._();
  static final RecentFilesService instance = RecentFilesService._();

  static const String _prefsKey = 'smiley_pdf_recent_files_v1';
  static const int _maxRecents = 20;

  final ValueNotifier<List<RecentFile>> recentFilesNotifier =
      ValueNotifier<List<RecentFile>>([]);

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_prefsKey) ?? [];

      final List<RecentFile> files = [];
      for (final raw in rawList) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final recent = RecentFile.fromJson(map);
          // Never keep deleted / missing files in recent opened
          if (File(recent.path).existsSync()) {
            files.add(recent);
          }
        } catch (e) {
          debugPrint('Error parsing recent file entry: $e');
        }
      }

      // Sort newest first
      files.sort((a, b) => b.lastOpenedMs.compareTo(a.lastOpenedMs));
      recentFilesNotifier.value = files;
      _isInitialized = true;

      // Re-persist if any deleted files were filtered out
      if (files.length != rawList.length) {
        await _persist(files);
      }

      // In the background, ensure thumbnails exist for items missing thumbnails
      _ensureThumbnails(files);
    } catch (e) {
      debugPrint('Error initializing RecentFilesService: $e');
    }
  }

  /// Removes any files that no longer exist on disk
  Future<void> purgeMissingFiles() async {
    try {
      final currentList = List<RecentFile>.from(recentFilesNotifier.value);
      final validList =
          currentList.where((e) => File(e.path).existsSync()).toList();
      if (validList.length != currentList.length) {
        recentFilesNotifier.value = validList;
        await _persist(validList);
        debugPrint(
            '[RecentFilesService] Purged ${currentList.length - validList.length} deleted files');
      }
    } catch (e) {
      debugPrint('Error purging missing recent files: $e');
    }
  }

  Future<void> addRecent(String filePath, {int? pageCount}) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        // Do not add non-existent or deleted files
        return;
      }

      final int sizeBytes = tryGetFileSize(file) ?? 0;
      final fileName = filePath.split(RegExp(r'[\\/]')).last;

      // Filter out any missing files at the same time
      final currentList = recentFilesNotifier.value
          .where((e) => File(e.path).existsSync())
          .toList();

      RecentFile? existing;
      final existingIndex = currentList.indexWhere((e) => e.path == filePath);
      if (existingIndex >= 0) {
        existing = currentList.removeAt(existingIndex);
      }

      final recent = RecentFile(
        path: filePath,
        fileName: fileName.isNotEmpty ? fileName : 'Document.pdf',
        lastOpenedMs: DateTime.now().millisecondsSinceEpoch,
        fileSizeBytes: sizeBytes > 0 ? sizeBytes : (existing?.fileSizeBytes ?? 0),
        pageCount: pageCount ?? existing?.pageCount,
        thumbnailPath: existing?.thumbnailPath,
      );

      currentList.insert(0, recent);
      if (currentList.length > _maxRecents) {
        currentList.removeRange(_maxRecents, currentList.length);
      }

      recentFilesNotifier.value = currentList;
      await _persist(currentList);

      // Asynchronously generate thumbnail if not available
      if (recent.thumbnailPath == null ||
          !File(recent.thumbnailPath!).existsSync()) {
        _generateAndStoreThumbnail(filePath);
      }
    } catch (e) {
      debugPrint('Error adding recent file: $e');
    }
  }

  Future<void> updateFilePath(String oldPath, String newPath,
      {String? newFileName}) async {
    try {
      final currentList = List<RecentFile>.from(recentFilesNotifier.value);
      final index = currentList.indexWhere((e) => e.path == oldPath);
      if (index >= 0) {
        final item = currentList[index];
        final name = newFileName ?? newPath.split(RegExp(r'[\\/]')).last;
        final newFile = File(newPath);
        final size = newFile.existsSync()
            ? (tryGetFileSize(newFile) ?? item.fileSizeBytes)
            : item.fileSizeBytes;
        currentList[index] = item.copyWith(
          path: newPath,
          fileName: name,
          fileSizeBytes: size,
        );
        recentFilesNotifier.value = currentList;
        await _persist(currentList);
      }
    } catch (e) {
      debugPrint('Error updating file path in recents: $e');
    }
  }

  Future<void> updatePageCount(String filePath, int pageCount) async {
    try {
      final currentList = List<RecentFile>.from(recentFilesNotifier.value);
      final index = currentList.indexWhere((e) => e.path == filePath);
      if (index >= 0) {
        final item = currentList[index];
        if (item.pageCount != pageCount) {
          currentList[index] = item.copyWith(pageCount: pageCount);
          recentFilesNotifier.value = currentList;
          await _persist(currentList);
        }
      }
    } catch (e) {
      debugPrint('Error updating page count: $e');
    }
  }

  Future<void> removeRecent(String filePath) async {
    try {
      final currentList = List<RecentFile>.from(recentFilesNotifier.value);
      final index = currentList.indexWhere((e) => e.path == filePath);
      if (index >= 0) {
        final removed = currentList.removeAt(index);
        if (removed.thumbnailPath != null) {
          final thumbFile = File(removed.thumbnailPath!);
          if (thumbFile.existsSync()) {
            try {
              thumbFile.deleteSync();
            } catch (_) {}
          }
        }
        recentFilesNotifier.value = currentList;
        await _persist(currentList);
      }
    } catch (e) {
      debugPrint('Error removing recent file: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      recentFilesNotifier.value = [];
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (e) {
      debugPrint('Error clearing recent files: $e');
    }
  }

  Future<void> _persist(List<RecentFile> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = list.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_prefsKey, rawList);
    } catch (e) {
      debugPrint('Error persisting recent files: $e');
    }
  }

  int? tryGetFileSize(File file) {
    try {
      return file.lengthSync();
    } catch (_) {
      return null;
    }
  }

  void _ensureThumbnails(List<RecentFile> files) {
    for (final file in files) {
      if (file.thumbnailPath == null || !File(file.thumbnailPath!).existsSync()) {
        _generateAndStoreThumbnail(file.path);
      }
    }
  }

  Future<void> _generateAndStoreThumbnail(String filePath) async {
    PdfDocument? doc;
    try {
      final file = File(filePath);
      if (!file.existsSync()) return;

      final tempDir = await getTemporaryDirectory();
      final thumbsDir = Directory('${tempDir.path}/pdf_thumbnails');
      if (!thumbsDir.existsSync()) {
        await thumbsDir.create(recursive: true);
      }

      final safeName =
          'thumb_${filePath.hashCode.toRadixString(16).replaceAll('-', 'm')}.png';
      final thumbFile = File('${thumbsDir.path}/$safeName');

      if (thumbFile.existsSync() && thumbFile.lengthSync() > 0) {
        _updateRecentThumbnail(filePath, thumbFile.path, null);
        return;
      }

      doc = await PdfDocument.openFile(filePath);
      if (doc.pages.isEmpty) return;

      final pageCount = doc.pages.length;
      final page = doc.pages.first;

      // Scale thumbnail to around 160px width
      final double targetWidth = 160;
      final double aspectRatio = page.width / max(1.0, page.height);
      final double targetHeight = targetWidth / aspectRatio;

      final pdfImage = await page.render(
        fullWidth: targetWidth,
        fullHeight: targetHeight,
      );

      if (pdfImage == null) return;

      try {
        final uiImage = await pdfImage.createImage();
        try {
          final byteData =
              await uiImage.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            await thumbFile.writeAsBytes(byteData.buffer.asUint8List(),
                flush: true);
            _updateRecentThumbnail(filePath, thumbFile.path, pageCount);
          }
        } finally {
          uiImage.dispose();
        }
      } finally {
        pdfImage.dispose();
      }
    } catch (e) {
      debugPrint('Thumbnail generation failed for $filePath: $e');
    } finally {
      try {
        doc?.dispose();
      } catch (_) {}
    }
  }

  void _updateRecentThumbnail(
      String filePath, String thumbPath, int? pageCount) {
    final currentList = List<RecentFile>.from(recentFilesNotifier.value);
    final index = currentList.indexWhere((e) => e.path == filePath);
    if (index >= 0) {
      final current = currentList[index];
      currentList[index] = current.copyWith(
        thumbnailPath: thumbPath,
        pageCount: pageCount ?? current.pageCount,
      );
      recentFilesNotifier.value = currentList;
      _persist(currentList);
    }
  }
}
