import 'dart:io';

class RecentFile {
  final String path;
  final String fileName;
  final int lastOpenedMs;
  final int fileSizeBytes;
  final int? pageCount;
  final String? thumbnailPath;

  const RecentFile({
    required this.path,
    required this.fileName,
    required this.lastOpenedMs,
    required this.fileSizeBytes,
    this.pageCount,
    this.thumbnailPath,
  });

  DateTime get lastOpened => DateTime.fromMillisecondsSinceEpoch(lastOpenedMs);

  bool get exists => File(path).existsSync();

  String get formattedSize {
    if (fileSizeBytes <= 0) return '';
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(lastOpened);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24 && now.day == lastOpened.day) {
      final hour = lastOpened.hour % 12 == 0 ? 12 : lastOpened.hour % 12;
      final minute = lastOpened.minute.toString().padLeft(2, '0');
      final period = lastOpened.hour >= 12 ? 'PM' : 'AM';
      return 'Today, $hour:$minute $period';
    }
    if (diff.inDays < 2) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[lastOpened.month - 1]} ${lastOpened.day}, ${lastOpened.year}';
  }

  String get metadataSummary {
    final parts = <String>[];
    if (pageCount != null && pageCount! > 0) {
      parts.add(pageCount == 1 ? '1 page' : '$pageCount pages');
    }
    final size = formattedSize;
    if (size.isNotEmpty) {
      parts.add(size);
    }
    parts.add(formattedDate);
    return parts.join(' • ');
  }

  RecentFile copyWith({
    String? path,
    String? fileName,
    int? lastOpenedMs,
    int? fileSizeBytes,
    int? pageCount,
    String? thumbnailPath,
  }) {
    return RecentFile(
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      lastOpenedMs: lastOpenedMs ?? this.lastOpenedMs,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      pageCount: pageCount ?? this.pageCount,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }

  Map<String, dynamic> toJson() => {
    'path': path,
    'fileName': fileName,
    'lastOpenedMs': lastOpenedMs,
    'fileSizeBytes': fileSizeBytes,
    if (pageCount != null) 'pageCount': pageCount,
    if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
  };

  factory RecentFile.fromJson(Map<String, dynamic> json) {
    return RecentFile(
      path: json['path'] as String,
      fileName: json['fileName'] as String? ??
          json['path'].toString().split(RegExp(r'[\\/]')).last,
      lastOpenedMs: json['lastOpenedMs'] as int? ??
          DateTime.now().millisecondsSinceEpoch,
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      pageCount: json['pageCount'] as int?,
      thumbnailPath: json['thumbnailPath'] as String?,
    );
  }
}
