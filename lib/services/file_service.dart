import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/file_model.dart';

class FileService extends ChangeNotifier {
  List<FileModel> _currentFiles = [];
  List<FileModel> _recentFiles = [];
  String _currentPath = '/storage/emulated/0';
  bool _isLoading = false;
  String? _error;

  // ─── Copy / Move State Handling ───
  List<String> _selectedPaths = []; // మల్టిపుల్ సెలెక్షన్ కోసం 🛠️
  List<String> _clipboardPaths = []; // కాపీ/కట్ చేసిన ఫైల్స్ దాచడానికి
  bool _isMoveOperation = false; // కాపీనా లేక కట్ (మూవ్) ఆ అని గుర్తుంచుకోవడానికి

  List<FileModel> get currentFiles => _currentFiles;
  List<FileModel> get recentFiles => _recentFiles;
  String get currentPath => _currentPath;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get canGoBack => _currentPath != '/storage/emulated/0' && _currentPath != '/';
  
  List<String> get selectedPaths => _selectedPaths;
  List<String> get clipboardPaths => _clipboardPaths;
  bool get hasClipboardItems => _clipboardPaths.isNotEmpty;

  // ─── మల్టిపుల్ సెలెక్షన్ మేనేజ్మెంట్ ───
  void toggleSelection(String path) {
    if (_selectedPaths.contains(path)) {
      _selectedPaths.remove(path);
    } else {
      _selectedPaths.add(path);
    }
    for (var file in _currentFiles) {
      if (file.path == path) {
        file.isSelected = _selectedPaths.contains(path);
      }
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedPaths.clear();
    for (var file in _currentFiles) {
      file.isSelected = false;
    }
    notifyListeners();
  }

  // ─── 1. ఫైల్స్ & ఫోల్డర్స్ లోడింగ్ ───
  Future<void> loadFiles(String path) async {
    _isLoading = true;
    _error = null;
    _currentPath = path;
    _selectedPaths.clear(); // ఫోల్డర్ మారినప్పుడు సెలెక్షన్ క్లియర్ అవుతుంది
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

          if (name.startsWith('.')) continue;

          filesList.add(FileModel(
            path: entity.path,
            name: name,
            size: isDirectory ? 0 : stat.size,
            lastModified: stat.modified,
            category: isDirectory ? FileCategory.other : FileModel.fromFile(File(entity.path)).category,
            isSelected: false,
            isFavorite: false,
          ));
        } catch (_) {}
      }

      filesList.sort((a, b) {
        final aIsDir = Directory(a.path).existsSync();
        final bIsDir = Directory(b.path).existsSync();
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      _currentFiles = filesList;
      
      final onlyFiles = filesList.where((f) => !Directory(f.path).existsSync()).toList();
      if (onlyFiles.isNotEmpty) {
        _recentFiles = (List<FileModel>.from(onlyFiles)
          ..sort((a, b) => b.lastModified.compareTo(a.lastModified))).take(20).toList();
      }

    } catch (e) {
      _error = 'Cannot access directory';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRootDirectory() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.request().isGranted || 
          await Permission.storage.request().isGranted) {
        await loadFiles('/storage/emulated/0');
        return;
      }
      _error = 'Storage permission required';
      notifyListeners();
    } else {
      await loadFiles('/storage/emulated/0');
    }
  }

  // ─── 2. కొత్త ఫోల్డర్ క్రియేషన్ (New Folder) ───
  Future<bool> createFolder(String folderName) async {
    try {
      final newDir = Directory('$_currentPath/$folderName');
      if (await newDir.exists()) return false; // ఆల్రెడీ ఉంటే క్రియేట్ చేయదు
      await newDir.create();
      await loadFiles(_currentPath); // స్క్రీన్ రిఫ్రెష్
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── 3. క్లిప్‌బోర్డ్ యాక్షన్స్ (Copy / Cut Trigger) ───
  void initCopy() {
    _clipboardPaths = List.from(_selectedPaths);
    _isMoveOperation = false;
    clearSelection();
  }

  void initMove() {
    _clipboardPaths = List.from(_selectedPaths);
    _isMoveOperation = true;
    clearSelection();
  }

  void cancelPaste() {
    _clipboardPaths.clear();
    notifyListeners();
  }

  // ─── 4. పేస్ట్ లాజిక్ (Execute Copy/Move) ───
  Future<void> pasteFiles() async {
    if (_clipboardPaths.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    for (final sourcePath in _clipboardPaths) {
      try {
        final sourceFile = File(sourcePath);
        if (!await sourceFile.exists()) continue;

        final name = sourceFile.uri.pathSegments.last;
        final destPath = '$_currentPath/$name';

        // ఫైల్ ని కాపీ చేస్తుంది
        await sourceFile.copy(destPath);

        // ఒకవేళ కట్ (Move) ఆపరేషన్ అయితే పాత ఫైల్ ని డిలీట్ చేస్తుంది 🛠️
        if (_isMoveOperation) {
          await sourceFile.delete();
        }
      } catch (e) {
        debugPrint('[FileService] Paste Error: $e');
      }
    }

    _clipboardPaths.clear();
    await loadFiles(_currentPath); // అప్‌డేటెడ్ లిస్ట్‌ని లోడ్ చేస్తుంది
  }

  // ─── 5. మల్టిపుల్ లేదా సింగిల్ డిలీట్ లాజిక్ ───
  Future<bool> deleteFile(String path) async {
    try {
      final isDir = Directory(path).existsSync();
      if (isDir) {
        await Directory(path).delete(recursive: true);
      } else {
        await File(path).delete();
      }
      _currentFiles.removeWhere((f) => f.path == path);
      _selectedPaths.remove(path);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteSelectedFiles() async {
    if (_selectedPaths.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    for (final path in List.from(_selectedPaths)) {
      await deleteFile(path);
    }

    _selectedPaths.clear();
    await loadFiles(_currentPath);
  }

  // ─── సెర్చ్ & మీడియా క్వెరీస్ ───
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
}
