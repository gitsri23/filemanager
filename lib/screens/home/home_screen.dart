import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/file_model.dart';

class FileService extends ChangeNotifier {
  List<FileModel> _currentFiles = [];
  List<FileModel> _recentFiles = [];
  List<String> _favorites = [];
  List<FileModel> _recycleBin = [];
  String _currentPath = '/storage/emulated/0'; // Default root path
  bool _isLoading = false;
  String? _error;

  List<FileModel> get currentFiles => _currentFiles;
  List<FileModel> get recentFiles => _recentFiles;
  List<FileModel> get recycleBin => _recycleBin;
  List<String> get favorites => _favorites;
  String get currentPath => _currentPath;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get canGoBack => _currentPath != '/storage/emulated/0';

  // ─── 1. ఫోల్డర్స్ & ఫైల్స్ రెండింటినీ లోడ్ చేసే పక్కా లాజిక్ ───
  Future<void> loadFiles(String path) async {
    _isLoading = true;
    _error = null;
    _currentPath = path;
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
      final filesList = <FileModel>[];

      for (final entity in entities) {
        try {
          final isDirectory = entity is Directory;
          final stat = entity.statSync();
          final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;

          // దాచిన ఫైల్స్ (.thumbnails లాంటివి) స్కిప్ చేయడానికి
          if (name.startsWith('.')) continue;

          filesList.add(FileModel(
            path: entity.path,
            name: name,
            size: isDirectory ? 0 : stat.size,
            lastModified: stat.modified,
            category: isDirectory ? FileCategory.other : FileModel.detectCategory(entity.path),
            isSelected: false,
            isFavorite: _favorites.contains(entity.path),
          ));
        } catch (_) {}
      }

      // ఫోల్డర్స్ ఫస్ట్ వచ్చేలా, ఆ తర్వాత ఫైల్స్ పేరు బట్టి సార్ట్ చేస్తాం
      filesList.sort((a, b) {
        final aIsDir = Directory(a.path).existsSync();
        final bIsDir = Directory(b.path).existsSync();
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      _currentFiles = filesList;
      
      // రీసెంట్ ఫైల్స్ అప్‌డేట్
      final onlyFiles = filesList.where((f) => !Directory(f.path).existsSync()).toList();
      if (onlyFiles.isNotEmpty) {
        _recentFiles = (List<FileModel>.from(onlyFiles)..sort((a, b) => b.lastModified.compareTo(a.lastModified))).take(20).toList();
      }

    } catch (e) {
      _error = 'Access Denied';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRootDirectory() async {
    final hasPermission = await requestStoragePermission();
    if (!hasPermission) {
      _error = 'Permission Required';
      notifyListeners();
      return;
    }
    await loadFiles('/storage/emulated/0');
  }

  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.request().isGranted) return true;
      if (await Permission.storage.request().isGranted) return true;
      return false;
    }
    return true;
  }

  // ─── 5. సెర్చ్ ఫంక్షనాలిటీ (పనిచేసేలా ఫిక్స్) ───
  Future<List<FileModel>> searchFiles(String query) async {
    if (query.isEmpty) return [];
    final results = <FileModel>[];
    final targetDirs = ['Download', 'DCIM', 'Pictures', 'Movies', 'Documents'];

    for (final folder in targetDirs) {
      final dir = Directory('/storage/emulated/0/$folder');
      if (!await dir.exists()) continue;
      try {
        final entities = await dir.list(recursive: true, followLinks: false).toList();
        for (final entity in entities) {
          if (entity is File && entity.uri.pathSegments.last.toLowerCase().contains(query.toLowerCase())) {
            results.add(FileModel.fromFile(entity));
          }
        }
      } catch (_) {}
    }
    return results;
  }

  // ─── క్విక్ యాక్షన్స్ సపోర్టెడ్ ఫిల్టర్స్ ───
  Future<List<FileModel>> getWhatsAppMedia() async {
    final files = <FileModel>[];
    final waPath = Directory('/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media');
    if (await waPath.exists()) {
      try {
        final entities = await waPath.list(recursive: true).toList();
        for (final e in entities) {
          if (e is File) files.add(FileModel.fromFile(e));
        }
      } catch (_) {}
    }
    return files;
  }

  Future<List<FileModel>> getApkFiles() async {
    final files = <FileModel>[];
    final dir = Directory('/storage/emulated/0');
    try {
      final entities = await dir.list(recursive: true).toList();
      for (final e in entities) {
        if (e is File && e.path.endsWith('.apk')) files.add(FileModel.fromFile(e));
      }
    } catch (_) {}
    return files;
  }

  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        _currentFiles.removeWhere((f) => f.path == path);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
