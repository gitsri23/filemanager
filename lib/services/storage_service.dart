import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../models/file_model.dart';

class StorageInfo {
  final int totalSpace;
  final int freeSpace;
  final int usedSpace;
  final Map<FileCategory, int> categoryBreakdown;

  StorageInfo({
    required this.totalSpace,
    required this.freeSpace,
    required this.usedSpace,
    required this.categoryBreakdown,
  });

  double get usagePercent => totalSpace > 0 ? usedSpace / totalSpace : 0;
  String get formattedTotal => _fmt(totalSpace);
  String get formattedFree => _fmt(freeSpace);
  String get formattedUsed => _fmt(usedSpace);

  static String _fmt(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    if (b < 1024 * 1024 * 1024) {
      return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(b / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class DuplicateGroup {
  final String hash;
  final List<FileModel> files;
  int get count => files.length;
  int get wastedSpace =>
      files.skip(1).fold(0, (sum, f) => sum + f.size);

  DuplicateGroup({required this.hash, required this.files});
}

class StorageService extends ChangeNotifier {
  StorageInfo? _storageInfo;
  List<FileModel> _largeFiles = [];
  List<DuplicateGroup> _duplicateGroups = [];
  bool _isAnalyzing = false;
  double _analyzeProgress = 0;
  String _analyzeStatus = '';

  StorageInfo? get storageInfo => _storageInfo;
  List<FileModel> get largeFiles => _largeFiles;
  List<DuplicateGroup> get duplicateGroups => _duplicateGroups;
  bool get isAnalyzing => _isAnalyzing;
  double get analyzeProgress => _analyzeProgress;
  String get analyzeStatus => _analyzeStatus;

  int get totalDuplicateWaste =>
      _duplicateGroups.fold(0, (s, g) => s + g.wastedSpace);
  int get totalLargeFileSize =>
      _largeFiles.fold(0, (s, f) => s + f.size);

  // ─── Storage Info ─────────────────────────────────────────────────────────

  Future<void> analyzeStorage() async {
    _isAnalyzing = true;
    _analyzeProgress = 0;
    _analyzeStatus = 'Reading storage info...';
    notifyListeners();

    try {
      // Get disk space via stat
      final stat = await _getStorageStat();
      _analyzeProgress = 0.1;
      _analyzeStatus = 'Scanning files...';
      notifyListeners();

      // Scan all files
      final allFiles = await _scanAllFiles(
        onProgress: (progress, status) {
          _analyzeProgress = 0.1 + progress * 0.6;
          _analyzeStatus = status;
          notifyListeners();
        },
      );

      _analyzeProgress = 0.7;
      _analyzeStatus = 'Finding large files...';
      notifyListeners();

      _largeFiles = allFiles
          .where((f) => f.size > 50 * 1024 * 1024) // > 50MB
          .toList()
        ..sort((a, b) => b.size.compareTo(a.size));

      _analyzeProgress = 0.8;
      _analyzeStatus = 'Building category breakdown...';
      notifyListeners();

      final breakdown = <FileCategory, int>{};
      for (final cat in FileCategory.values) {
        breakdown[cat] =
            allFiles.where((f) => f.category == cat).fold(0, (s, f) => s + f.size);
      }

      _storageInfo = StorageInfo(
        totalSpace: stat['total'] ?? 0,
        freeSpace: stat['free'] ?? 0,
        usedSpace: stat['used'] ?? 0,
        categoryBreakdown: breakdown,
      );

      _analyzeProgress = 1.0;
      _analyzeStatus = 'Done';
    } catch (e) {
      debugPrint('[StorageService] Analyze error: $e');
    }

    _isAnalyzing = false;
    notifyListeners();
  }

  Future<Map<String, int>> _getStorageStat() async {
    try {
      // Use df command to get disk stats
      final result = await Process.run('df', ['/storage/emulated/0']);
      final lines = result.stdout.toString().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].trim().split(RegExp(r'\s+'));
        if (parts.length >= 4) {
          final total = int.tryParse(parts[1]) ?? 0;
          final used = int.tryParse(parts[2]) ?? 0;
          final free = int.tryParse(parts[3]) ?? 0;
          return {
            'total': total * 1024,
            'used': used * 1024,
            'free': free * 1024,
          };
        }
      }
    } catch (_) {}

    // Fallback: statfs via File
    try {
      final dir = Directory('/storage/emulated/0');
      final stat = await dir.stat();
      // Rough estimate
      return {'total': 64 * 1024 * 1024 * 1024, 'free': 0, 'used': 0};
    } catch (_) {}

    return {'total': 0, 'free': 0, 'used': 0};
  }

  Future<List<FileModel>> _scanAllFiles({
    void Function(double progress, String status)? onProgress,
  }) async {
    final files = <FileModel>[];
    final rootDir = Directory('/storage/emulated/0');
    int scanned = 0;

    try {
      await for (final entity in rootDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            files.add(FileModel.fromFile(entity));
            scanned++;
            if (scanned % 500 == 0) {
              onProgress?.call(
                (scanned / 10000).clamp(0.0, 1.0),
                'Scanned $scanned files...',
              );
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    return files;
  }

  // ─── Duplicate Finder ────────────────────────────────────────────────────

  Future<void> findDuplicates({
    FileCategory? category,
    int minSize = 1024, // Skip tiny files
  }) async {
    _isAnalyzing = true;
    _analyzeProgress = 0;
    _analyzeStatus = 'Scanning for duplicates...';
    notifyListeners();

    try {
      final allFiles = await _scanAllFiles(
        onProgress: (p, s) {
          _analyzeProgress = p * 0.6;
          _analyzeStatus = s;
          notifyListeners();
        },
      );

      final filtered = allFiles.where((f) {
        if (f.size < minSize) return false;
        if (category != null && f.category != category) return false;
        return true;
      }).toList();

      // Group by size first (quick filter)
      final sizeGroups = <int, List<FileModel>>{};
      for (final file in filtered) {
        sizeGroups.putIfAbsent(file.size, () => []).add(file);
      }

      final candidates = sizeGroups.values
          .where((group) => group.length > 1)
          .expand((g) => g)
          .toList();

      _analyzeProgress = 0.7;
      _analyzeStatus = 'Computing checksums (${candidates.length} files)...';
      notifyListeners();

      // Hash candidates
      final hashGroups = <String, List<FileModel>>{};
      int processed = 0;

      for (final file in candidates) {
        try {
          final hash = await _computeHash(file.path);
          if (hash != null) {
            hashGroups.putIfAbsent(hash, () => []).add(file);
          }
        } catch (_) {}

        processed++;
        if (processed % 50 == 0) {
          _analyzeProgress = 0.7 + (processed / candidates.length) * 0.3;
          _analyzeStatus = 'Hashing $processed/${candidates.length}...';
          notifyListeners();
        }
      }

      _duplicateGroups = hashGroups.entries
          .where((e) => e.value.length > 1)
          .map((e) => DuplicateGroup(hash: e.key, files: e.value))
          .toList()
        ..sort((a, b) => b.wastedSpace.compareTo(a.wastedSpace));

      _analyzeProgress = 1.0;
      _analyzeStatus = 'Found ${_duplicateGroups.length} duplicate groups';
    } catch (e) {
      debugPrint('[StorageService] Duplicate finder error: $e');
    }

    _isAnalyzing = false;
    notifyListeners();
  }

  Future<String?> _computeHash(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      return md5.convert(bytes).toString();
    } catch (_) {
      return null;
    }
  }

  // ─── Deep Clean ──────────────────────────────────────────────────────────

  Future<int> deepClean() async {
    int freed = 0;

    // Clean cache directories
    final cacheDirs = [
      '/storage/emulated/0/Android/data',
    ];

    for (final dirPath in cacheDirs) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) continue;

      await for (final entity in dir.list(recursive: false)) {
        if (entity is Directory) {
          final cacheDir =
              Directory('${entity.path}/cache');
          if (await cacheDir.exists()) {
            final size = await _dirSize(cacheDir);
            try {
              await cacheDir.delete(recursive: true);
              freed += size;
            } catch (_) {}
          }
        }
      }
    }

    return freed;
  }

  Future<int> _dirSize(Directory dir) async {
    int size = 0;
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    } catch (_) {}
    return size;
  }

  // ─── Delete duplicates ───────────────────────────────────────────────────

  Future<int> deleteDuplicates(List<DuplicateGroup> groups) async {
    int freed = 0;
    for (final group in groups) {
      // Keep first, delete rest
      for (final file in group.files.skip(1)) {
        try {
          await File(file.path).delete();
          freed += file.size;
        } catch (_) {}
      }
    }
    _duplicateGroups.removeWhere((g) => groups.contains(g));
    notifyListeners();
    return freed;
  }
}
