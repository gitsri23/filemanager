import 'dart:io';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';

enum FileCategory {
  image,
  video,
  audio,
  document,
  apk,
  archive,
  whatsapp,
  download,
  other,
}

class FileModel {
  final String path;
  final String name;
  final int size;
  final DateTime lastModified;
  final FileCategory category;
  bool isFavorite;
  bool isSelected;

  FileModel({
    required this.path,
    required this.name,
    required this.size,
    required this.lastModified,
    required this.category,
    this.isFavorite = false,
    this.isSelected = false,
  });

  factory FileModel.fromFile(File file) {
    final stat = file.statSync();
    return FileModel(
      path: file.path,
      name: file.uri.pathSegments.last,
      size: stat.size,
      lastModified: stat.modified,
      category: _detectCategory(file.path),
    );
  }

  static FileCategory _detectCategory(String path) {
    final lower = path.toLowerCase();
    final mime = lookupMimeType(path) ?? '';

    if (lower.contains('/whatsapp/')) return FileCategory.whatsapp;
    if (lower.contains('/download/')) return FileCategory.download;
    if (lower.endsWith('.apk')) return FileCategory.apk;
    if (mime.startsWith('image/')) return FileCategory.image;
    if (mime.startsWith('video/')) return FileCategory.video;
    if (mime.startsWith('audio/')) return FileCategory.audio;
    if (['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.txt']
        .any((ext) => lower.endsWith(ext))) {
      return FileCategory.document;
    }
    if (['.zip', '.rar', '.7z', '.tar', '.gz']
        .any((ext) => lower.endsWith(ext))) {
      return FileCategory.archive;
    }
    return FileCategory.other;
  }

  String get formattedSize => _formatSize(size);
  String get formattedDate =>
      DateFormat('MMM dd, yyyy').format(lastModified);
  String get extension => name.contains('.')
      ? name.split('.').last.toUpperCase()
      : 'FILE';

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  bool get isImage => category == FileCategory.image;
  bool get isVideo => category == FileCategory.video;
  bool get isApk => category == FileCategory.apk;
  bool get isLarge => size > 100 * 1024 * 1024; // > 100MB

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is FileModel && path == other.path);

  @override
  int get hashCode => path.hashCode;
}

class FolderModel {
  final String path;
  final String name;
  int fileCount;
  int totalSize;
  final DateTime lastModified;

  FolderModel({
    required this.path,
    required this.name,
    required this.fileCount,
    required this.totalSize,
    required this.lastModified,
  });

  String get formattedSize => FileModel._formatSize(totalSize);
}
