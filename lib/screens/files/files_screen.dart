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
  final TextEditingController _folderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FileService>().loadRootDirectory();
    });
  }

  @override
  void dispose() {
    _folderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fileService = context.watch<FileService>();
    final isMultiSelectMode = fileService.selectedPaths.isNotEmpty;

    return PopScope(
      canPop: !fileService.canGoBack && !isMultiSelectMode,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (isMultiSelectMode) {
          fileService.clearSelection(); // సెలెక్షన్ మోడ్ ఆన్ లో ఉంటే ముందు అది క్లోజ్ అవుతుంది 🛠️
          return;
        }
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
          leading: isMultiSelectMode
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => fileService.clearSelection(),
                )
              : fileService.canGoBack 
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () async {
                        final parentPath = Directory(fileService.currentPath).parent.path;
                        await fileService.loadFiles(parentPath);
                      },
                    )
                  : null,
          title: Text(
            isMultiSelectMode
                ? '${fileService.selectedPaths.length} Selected'
                : (fileService.currentPath == '/storage/emulated/0' ? 'Internal Storage' : fileService.currentPath.split('/').last),
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actions: [
            if (!isMultiSelectMode)
              IconButton(
                icon: const Icon(Icons.create_new_folder_rounded, color: AppTheme.primaryColor),
                onPressed: () => _showNewFolderDialog(context, fileService),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            fileService.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : fileService.currentFiles.isEmpty
                    ? const Center(child: Text('This folder is empty', style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: fileService.currentFiles.length,
                        itemBuilder: (context, index) {
                          final item = fileService.currentFiles[index];
                          final isDir = Directory(item.path).existsSync();
                          final isSelected = fileService.selectedPaths.contains(item.path);

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: AppTheme.primaryColor.withOpacity(0.08),
                            leading: Icon(
                              isDir ? Icons.folder_rounded : Icons.insert_drive_file_rounded,
                              color: isSelected ? AppTheme.primaryColor : (isDir ? Colors.amber : AppTheme.primaryColor),
                              size: 26,
                            ),
                            title: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: isSelected ? AppTheme.primaryColor : Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            subtitle: isDir 
                                ? null 
                                : Text(item.formattedSize, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            trailing: isMultiSelectMode
                                ? Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: AppTheme.primaryColor, size: 20)
                                : const Icon(Icons.more_vert_rounded, color: Colors.white24, size: 16),
                            onTap: () async {
                              if (isMultiSelectMode) {
                                fileService.toggleSelection(item.path);
                              } else if (isDir) {
                                await fileService.loadFiles(item.path);
                              } else {
                                await OpenFile.open(item.path);
                              }
                            },
                            onLongPress: () {
                              fileService.toggleSelection(item.path); // లాంగ్ ప్రెస్ చేయగానే సెలెక్షన్ మోడ్ ఆన్ అవుతుంది 🛠️
                            },
                          );
                        },
                      ),

            // ─── 🛠️ మల్టిపుల్ సెలెక్షన్ కింద వచ్చే బార్ (AMOLED Action Bottom Bar) ───
            if (isMultiSelectMode)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(color: AppTheme.surfaceDark, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActionButton(icon: Icons.copy_rounded, label: 'Copy', onTap: () => fileService.initCopy()),
                      _ActionButton(icon: Icons.cut_rounded, label: 'Move', onTap: () => fileService.initMove()),
                      _ActionButton(icon: Icons.delete_outline_rounded, label: 'Delete', onTap: () => _showDeleteConfirmDialog(context, fileService)),
                    ],
                  ),
                ),
              ),

            // ─── 🛠️ కాపీ/కట్ చేశాక వచ్చే ఫ్లోటింగ్ పేస్ట్ బార్ (Paste Menu Trigger) ───
            if (fileService.hasClipboardItems && !isMultiSelectMode)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Text('${fileService.clipboardPaths.length} items ready to paste', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(onPressed: () => fileService.cancelPaste(), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () => fileService.pasteFiles(),
                        child: const Text('Paste Here', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // న్యూ ఫోల్డర్ డైలాగ్ బాక్స్
  void _showNewFolderDialog(BuildContext context, FileService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Create New Folder', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _folderController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Folder Name', hintStyle: TextStyle(color: Colors.white38), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () async {
              if (_folderController.text.trim().isNotEmpty) {
                await service.createFolder(_folderController.text.trim());
                _folderController.clear();
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // సెలెక్ట్ చేసిన ఫైల్స్ డిలీట్ కన్ఫర్మేషన్
  void _showDeleteConfirmDialog(BuildContext context, FileService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Confirm Delete', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete these ${service.selectedPaths.length} items?', style: const TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await service.deleteSelectedFiles();
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
