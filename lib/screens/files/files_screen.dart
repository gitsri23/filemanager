import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../services/file_service.dart';
import '../../models/file_model.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FileService>().loadRootDirectory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fileService = context.watch<FileService>();

    return PopScope(
      canPop: !fileService.canGoBack,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (fileService.canGoBack) {
          final parentPath = Directory(fileService.currentPath).parent.path;
          await fileService.loadFiles(parentPath);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.amoledBlack,
        appBar: AppBar(
          backgroundColor: AppTheme.amoledBlack,
          elevation: 0,
          leading: fileService.canGoBack 
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () async {
                    final parentPath = Directory(fileService.currentPath).parent.path;
                    await fileService.loadFiles(parentPath);
                  },
                )
              : null,
          title: Text(
            fileService.currentPath == '/storage/emulated/0'
                ? 'Internal Storage'
                : fileService.currentPath.split('/').last,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: fileService.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : fileService.currentFiles.isEmpty
                ? const Center(child: Text('This folder is empty', style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: fileService.currentFiles.length,
                    itemBuilder: (context, index) {
                      final item = fileService.currentFiles[index];
                      final isDir = Directory(item.path).existsSync();

                      return ListTile(
                        leading: Icon(
                          isDir ? Icons.folder_rounded : Icons.insert_drive_file_rounded,
                          color: isDir ? Colors.amber : AppTheme.primaryColor,
                          size: 28,
                        ),
                        title: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        subtitle: isDir 
                            ? null 
                            : Text(item.formattedSize, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        trailing: const Icon(Icons.more_vert_rounded, color: Colors.white24, size: 18),
                        onTap: () async {
                          if (isDir) {
                            await fileService.loadFiles(item.path);
                          } else {
                            await OpenFile.open(item.path);
                          }
                        },
                        onLongPress: () {
                          _showActionMenu(context, item, isDir);
                        },
                      );
                    },
                  ),
      ),
    );
  }

  void _showActionMenu(BuildContext context, FileModel item, bool isDir) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              const Divider(color: Colors.white10, height: 1),
              if (!isDir)
                ListTile(
                  leading: const Icon(Icons.share_rounded, color: AppTheme.successColor),
                  // 🛠️ ఇక్కడ 'whitee' ని 'white' గా ఫిక్స్ చేశాం!
                  title: const Text('Share File', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Share.shareXFiles([XFile(item.path)]);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: AppTheme.accentColor),
                title: const Text('Details Info', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showDetailsDialog(context, item, isDir);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.warningColor),
                title: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await context.read<FileService>().deleteFile(item.path);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File deleted successfully')));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDetailsDialog(BuildContext context, FileModel item, bool isDir) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('File Information', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${item.name}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Text('Path: ${item.path}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 8),
            if (!isDir) Text('Size: ${item.formattedSize}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Text('Modified: ${item.formattedDate}', style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}
