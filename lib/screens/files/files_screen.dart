import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      canPop: !fileService.canGoBack, // రూట్ ఫోల్డర్ లో ఉంటేనే యాప్ క్లోజ్ అవుతుంది
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (fileService.canGoBack) {
          // సబ్-ఫోల్డర్ లో బ్యాక్ నొక్కితే వెనక ఫోల్డర్ కి వస్తుంది
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
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white10),
                        onTap: () async {
                          if (isDir) {
                            // ఫోల్డర్ క్లిక్ చేస్తే లోపలికి వెళ్తుంది 🛠️
                            await fileService.loadFiles(item.path);
                          }
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
