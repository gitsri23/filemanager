import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file_model.dart';

class FileService extends ChangeNotifier {
  // ─── State ───────────────────────────────────────────────────────────────
  List<FileModel> _currentFiles = [];
  List<FileModel> _recentFiles = [];
  List<String> _favorites = [];
  List<FileModel> _recycleBin = [];
  String _currentPath = '/';
  bool _isLoading = false;
  String? _error;

  // ─── Getters ─────────────────────────────────────────────────────────────
  List<FileModel> get currentFiles => _currentFiles;
  List<FileModel> get recentFiles => _recentFiles;
  List<FileModel> get recycleBin => _recycleBin;
  List<FileModel> get favorites =>
      _currentFiles.where((f) => _favorites.contains(f.path)).toList();
  String get currentPath => _currentPath;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get canGoBack => _currentPath != _getRootPath();

  // ─── 🛠️ Static Size Formatter Utility Fix ───────────────────────────────
  // Mee screens lo 'FileModel._formatSize' call valla vachina error ని ఇది బైపాస్ చేస్తుంది.
  static String formatSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double wSize = bytes.toDouble();
    while (wSize >= 1024 && i < suffixes.length - 1) {
      wSize /= 1024;
      i++;
    }
    return "${wSize.toStringAsFixed(1)} ${suffixes[i]}";
  }

  // ─── Permissions ─────────────────────────────────────────────────────────

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final sdkInt = await _getAndroidSdkInt();
      if (sdkInt >= 30) {
        final status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true;
  }

  Future<int> _getAndroidSdkInt() async {
    try {
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse(result.stdout.toString().trim()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ─── Navigation ──────────────────────────────────────────────────────────

  Future<void> navigateTo(String path) async {
    _currentPath = path;
    await loadFiles(path);
  }

  Future<void> navigateUp() async {
    if (!canGoBack) return;
    final parent = Directory(_currentPath).parent.path;
    await navigateTo(parent);
  }

  String _getRootPath() {
    return '/storage/emulated/0';
  }

  Future<void> loadRootDirectory() async {
    final hasPermission = await requestStoragePermission();
    if (!hasPermission) {
      _error = 'Storage permission required';
      notifyListeners();
      return;
    }
    await navigateTo(_getRootPath());
  }

  // ─── File Loading ────────────────────────────────────────────────────────

  Future<void> loadFiles(String path) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        _error = 'Directory not found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final entities = await dir.list(followLinks: false).toList();
      final files = <FileModel>[];

      for (final entity in entities) {
        try {
          if (entity is File) {
            files.add(FileModel.fromFile(entity));
          }
        } catch (_) {
          // Skip inaccessible files
        }
      }

      // Sort: dirs first, then by name
      files.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      _currentFiles = files;
      _isLoading = false;
      notifyListeners();

      // Update recents in background
      _updateRecentFiles(files);
    } catch (e) {
      _error = 'Cannot access this directory';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<String>> loadDirectories(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return [];

    final dirs = <String>[];
    try {
      await for (final entity
          in dir.list(followLinks: false, recursive: false)) {
        if (entity is Directory) {
          final name = entity.uri.pathSegments
              .where((s) => s.isNotEmpty)
              .last;
          if (!name.startsWith('.')) {
            dirs.add(entity.path);
          }
        }
      }
    } catch (_) {}
    dirs.sort();
    return dirs;
  }

  // ─── Search ──────────────────────────────────────────────────────────────

  Future<List<FileModel>> searchFiles(String query,
      {String? rootPath}) async {
    final results = <FileModel>[];
    final searchRoot = rootPath ?? _getRootPath();

    try {
      await _searchRecursive(Directory(searchRoot), query.toLowerCase(), results);
    } catch (_) {}

    return results;
  }

  Future<void> _searchRecursive(
      Directory dir, String query, List<FileModel> results) async {
    try {
      await for (final entity
          in dir.list(followLinks: false, recursive: false)) {
        if (entity is File) {
          final name = entity.uri.pathSegments.last.toLowerCase();
          if (name.contains(query)) {
            results.add(FileModel.fromFile(entity));
          }
        } else if (entity is Directory) {
          await _searchRecursive(entity, query, results);
        }
      }
    } catch (_) {}
  }

  // ─── Favorites ───────────────────────────────────────────────────────────

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favorites = prefs.getStringList('favorites') ?? [];
    notifyListeners();
  }

  Future<void> toggleFavorite(String path) async {
    final prefs = await SharedPreferences.getInstance();
    if (_favorites.contains(path)) {
      _favorites.remove(path);
    } else {
      _favorites.add(path);
    }
    await prefs.setStringList('favorites', _favorites);
    notifyListeners();
  }

  bool isFavorite(String path) => _favorites.contains(path);

  // ─── Recycle Bin ─────────────────────────────────────────────────────────

  Future<void> moveToRecycleBin(FileModel file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final binDir = Directory('${appDir.path}/.recycle_bin');
    if (!await binDir.exists()) await binDir.create(recursive: true);

    final destPath = '${binDir.path}/${file.name}';
    try {
      await File(file.path).copy(destPath);
      await File(file.path).delete();
      _recycleBin.add(file);
      _currentFiles.removeWhere((f) => f.path == file.path);
      notifyListeners();
    } catch (e) {
      debugPrint('[FileService] Recycle bin error: $e');
    }
  }

  Future<void> restoreFromRecycleBin(FileModel file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final binPath = '${appDir.path}/.recycle_bin/${file.name}';
    try {
      await File(binPath).copy(file.path);
      await File(binPath).delete();
      _recycleBin.removeWhere((f) => f.name == file.name);
      notifyListeners();
    } catch (e) {
      debugPrint('[FileService] Restore error: $e');
    }
  }

  Future<void> emptyRecycleBin() async {
    final appDir = await getApplicationDocumentsDirectory();
    final binDir = Directory('${appDir.path}/.recycle_bin');
    if (await binDir.exists()) {
      await binDir.delete(recursive: true);
    }
    _recycleBin.clear();
    notifyListeners();
  }

  // ─── Recent Files ────────────────────────────────────────────────────────

  void _updateRecentFiles(List<FileModel> files) {
    final sorted = List<FileModel>.from(files)
      ..sort((a, b) => b.lastModified.compareTo(a.lastModified));
    _recentFiles = sorted.take(50).toList();
  }

  // ─── File Operations ─────────────────────────────────────────────────────

  Future<bool> deleteFile(String path) async {
    try {
      await File(path).delete();
      _currentFiles.removeWhere((f) => f.path == path);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteFiles(List<String> paths) async {
    bool allSuccess = true;
    for (final path in paths) {
      final success = await deleteFile(path);
      if (!success) allSuccess = false;
    }
    return allSuccess;
  }

  Future<bool> renameFile(String oldPath, String newName) async {
    try {
      final file = File(oldPath);
      final parent = file.parent.path;
      await file.rename('$parent/$newName');
      await loadFiles(_currentPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── WhatsApp Media ──────────────────────────────────────────────────────

  Future<List<FileModel>> getWhatsAppMedia() async {
    final paths = [
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Images',
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Video',
      '/storage/emulated/0/WhatsApp/Media/WhatsApp Documents',
      '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media',
    ];

    final files = <FileModel>[];
    for (final path in paths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            try {
              files.add(FileModel.fromFile(entity));
            } catch (_) {}
          }
        }
      }
    }
    return files;
  }

  // ─── APK Manager ─────────────────────────────────────────────────────────

  Future<List<FileModel>> getApkFiles() async {
    return searchFiles('.apk');
  }

  // ─── Download Cleaner ────────────────────────────────────────────────────

  Future<List<FileModel>> getDownloadFiles() async {
    const downloadsPath = '/storage/emulated/0/Download';
    final files = <FileModel>[];
    final dir = Directory(downloadsPath);
    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: false)) {
        if (entity is File) {
          try {
            files.add(FileModel.fromFile(entity));
          } catch (_) {}
        }
      }
    }
    files.sort((a, b) => b.size.compareTo(a.size));
    return files;
  }
}
