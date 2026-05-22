import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import '../../core/ads/ad_service.dart';
import '../../core/ads/native_ad_widget.dart';
import '../../core/theme/app_theme.dart';
import '../../models/file_model.dart';
import '../../services/file_service.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<String> _subDirs = [];
  bool _loadingDirs = false;
  List<FileModel> _selectedFiles = [];
  bool get _isSelecting => _selectedFiles.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadSubDirs();
  }

  Future<void> _loadSubDirs() async {
    setState(() => _loadingDirs = true);
    final fileService = context.read<FileService>();
    final dirs = await fileService.loadDirectories(fileService.currentPath);
    if (mounted) {
      setState(() {
        _subDirs = dirs;
        _loadingDirs = false;
      });
    }
  }

  Future<void> _navigateTo(String path) async {
    final fileService = context.read<FileService>();
    await fileService.navigateTo(path);
    await _loadSubDirs();
    setState(() => _selectedFiles.clear());
  }

  Future<void> _deleteSelected() async {
    final paths = _selectedFiles.map((f) => f.path).toList();
    final totalSize =
        _selectedFiles.fold<int>(0, (s, f) => s + f.size);

    // Confirm
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Files', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete ${paths.length} file(s)?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final fileService = context.read<FileService>();
    await fileService.deleteFiles(paths);
    setState(() => _selectedFiles.clear());

    // Show interstitial after large deletion (> 10MB freed)
    if (totalSize > 10 * 1024 * 1024) {
      await AdService.instance.showInterstitial();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Deleted ${paths.length} files • ${FileModel._formatSize(totalSize)} freed'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final fileService = context.watch<FileService>();

    return Scaffold(
      backgroundColor: AppTheme.amoledBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.amoledBlack,
        leading: fileService.canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () async {
                  await fileService.navigateUp();
                  await _loadSubDirs();
                  setState(() => _selectedFiles.clear());
                },
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSelecting
                  ? '${_selectedFiles.length} selected'
                  : fileService.currentPath
                      .split('/')
                      .where((s) => s.isNotEmpty)
                      .last,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (!_isSelecting)
              Text(
                '${_subDirs.length} folders • ${fileService.currentFiles.length} files',
                style: const TextStyle(fontSize: 12, color: Colors.white38),
              ),
          ],
        ),
        actions: [
          if (_isSelecting) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent),
              onPressed: _deleteSelected,
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => setState(() => _selectedFiles.clear()),
            ),
          ] else ...[
            IconButton(
              icon:
                  const Icon(Icons.sort_rounded, color: Colors.white70),
              onPressed: () {},
            ),
          ],
        ],
      ),
      body: fileService.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primaryColor),
            )
          : fileService.error != null
              ? Center(
                  child: Text(fileService.error!,
                      style: const TextStyle(color: Colors.white54)),
                )
              : _buildContent(fileService),
    );
  }

  Widget _buildContent(FileService fileService) {
    final dirs = _subDirs;
    final files = fileService.currentFiles;
    final itemCount = dirs.length + files.length;

    if (itemCount == 0) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_rounded, size: 64, color: Colors.white12),
            SizedBox(height: 12),
            Text('Empty folder', style: TextStyle(color: Colors.white38)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: itemCount + (files.length ~/ 10), // inject native ads
      itemBuilder: (context, index) {
        // Inject native ad every 10 file items
        if (index > dirs.length && (index - dirs.length) % 11 == 10) {
          return const NativeAdWidget();
        }

        // Adjust index for injected ads
        final adsInserted =
            index > dirs.length ? (index - dirs.length) ~/ 11 : 0;
        final realIndex = index - adsInserted;

        if (realIndex < dirs.length) {
          return _FolderTile(
            path: dirs[realIndex],
            onTap: () => _navigateTo(dirs[realIndex]),
          ).animate(delay: Duration(milliseconds: realIndex * 20)).slideX(
                begin: -0.1,
                end: 0,
                duration: 300.ms,
              ).fadeIn();
        }

        final fileIndex = realIndex - dirs.length;
        if (fileIndex >= files.length) return const SizedBox.shrink();
        final file = files[fileIndex];

        return _FileTile(
          file: file,
          isSelected: _selectedFiles.contains(file),
          onTap: () {
            if (_isSelecting) {
              setState(() {
                if (_selectedFiles.contains(file)) {
                  _selectedFiles.remove(file);
                } else {
                  _selectedFiles.add(file);
                }
              });
            } else {
              OpenFile.open(file.path);
            }
          },
          onLongPress: () {
            setState(() {
              if (!_selectedFiles.contains(file)) {
                _selectedFiles.add(file);
              }
            });
          },
        ).animate(delay: Duration(milliseconds: fileIndex * 15)).slideX(
              begin: 0.05,
              end: 0,
              duration: 250.ms,
            ).fadeIn();
      },
    );
  }
}

class _FolderTile extends StatelessWidget {
  final String path;
  final VoidCallback onTap;

  const _FolderTile({required this.path, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = path.split('/').where((s) => s.isNotEmpty).last;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.folder_rounded,
            color: AppTheme.primaryColor, size: 24),
      ),
      title: Text(
        name,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: Colors.white24, size: 20),
    );
  }
}

class _FileTile extends StatelessWidget {
  final FileModel file;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _FileTile({
    required this.file,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      tileColor: isSelected
          ? AppTheme.primaryColor.withOpacity(0.1)
          : Colors.transparent,
      leading: isSelected
          ? Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 24),
            )
          : Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _colorForCategory(file.category).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconForCategory(file.category),
                color: _colorForCategory(file.category),
                size: 24,
              ),
            ),
      title: Text(
        file.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text(
        '${file.formattedSize} • ${file.formattedDate}',
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      trailing: file.isLarge
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.warningColor.withOpacity(0.4)),
              ),
              child: Text(
                'LARGE',
                style: TextStyle(
                  color: AppTheme.warningColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
    );
  }

  Color _colorForCategory(FileCategory cat) {
    switch (cat) {
      case FileCategory.image:
        return AppTheme.primaryColor;
      case FileCategory.video:
        return AppTheme.warningColor;
      case FileCategory.audio:
        return AppTheme.successColor;
      case FileCategory.document:
        return AppTheme.goldColor;
      case FileCategory.apk:
        return const Color(0xFF00D4FF);
      case FileCategory.whatsapp:
        return const Color(0xFF25D366);
      case FileCategory.download:
        return const Color(0xFF8B5CF6);
      default:
        return Colors.white38;
    }
  }

  IconData _iconForCategory(FileCategory cat) {
    switch (cat) {
      case FileCategory.image:
        return Icons.image_rounded;
      case FileCategory.video:
        return Icons.videocam_rounded;
      case FileCategory.audio:
        return Icons.music_note_rounded;
      case FileCategory.document:
        return Icons.description_rounded;
      case FileCategory.apk:
        return Icons.android_rounded;
      case FileCategory.whatsapp:
        return Icons.chat_bubble_rounded;
      case FileCategory.download:
        return Icons.download_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}
