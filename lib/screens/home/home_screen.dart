import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/ads/native_ad_widget.dart';
import '../../core/theme/app_theme.dart';
import '../../models/file_model.dart';
import '../../services/file_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/storage_card.dart';
import '../../widgets/glass_navbar.dart';
import '../files/files_screen.dart';
import '../cleaner/cleaner_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final _screens = const [
    _HomeTab(),
    FilesScreen(),
    CleanerScreen(),
    SettingsScreen(),
  ];

  void setTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.amoledBlack,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: GlassNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FileService>().loadRootDirectory();
      context.read<StorageService>().analyzeStorage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final parentState = context.findAncestorStateOfType<_HomeScreenState>();

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppTheme.amoledBlack,
          expandedHeight: 100,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_special_rounded, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text('CleanVault', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.white70),
              onPressed: () {
                showSearch(context: context, delegate: FileSearchDelegate(context.read<FileService>()));
              },
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: StorageCard(),
              ).animate().slideY(begin: 0.2, end: 0, duration: 500.ms).fadeIn(),

              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Quick Clean', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(height: 12),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _QuickAction(
                          label: 'Duplicates',
                          icon: Icons.copy_all_rounded,
                          gradient: AppTheme.warmGradient,
                          onTap: () {
                            parentState?.setTab(2);
                            context.read<StorageService>().findDuplicates();
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _QuickAction(
                          label: 'Large Files',
                          icon: Icons.data_usage_rounded,
                          gradient: AppTheme.purpleGradient,
                          onTap: () => parentState?.setTab(2),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _QuickAction(
                          label: 'WhatsApp',
                          icon: Icons.chat_bubble_rounded,
                          gradient: AppTheme.greenGradient,
                          onTap: () => parentState?.setTab(2),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _QuickAction(
                        label: 'APK Files',
                        icon: Icons.android_rounded,
                        gradient: AppTheme.goldGradient,
                        onTap: () => parentState?.setTab(2),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const NativeAdWidget(),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Browse by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _Category('Images', Icons.image_rounded, AppTheme.primaryColor, () {
                      parentState?.setTab(1);
                      context.read<FileService>().loadFiles('/storage/emulated/0/DCIM');
                    }),
                    const SizedBox(width: 12),
                    _Category('Videos', Icons.videocam_rounded, const Color(0xFFFF6B6B), () {
                      parentState?.setTab(1);
                      context.read<FileService>().loadFiles('/storage/emulated/0/Movies');
                    }),
                    const SizedBox(width: 12),
                    _Category('Music', Icons.music_note_rounded, const Color(0xFF4ECDC4), () {
                      parentState?.setTab(1);
                      context.read<FileService>().loadFiles('/storage/emulated/0/Music');
                    }),
                    const SizedBox(width: 12),
                    _Category('Docs', Icons.description_rounded, const Color(0xFFFFD700), () {
                      parentState?.setTab(1);
                      context.read<FileService>().loadFiles('/storage/emulated/0/Documents');
                    }),
                    const SizedBox(width: 12),
                    _Category('Downloads', Icons.download_rounded, const Color(0xFF8B5CF6), () {
                      parentState?.setTab(1);
                      context.read<FileService>().loadFiles('/storage/emulated/0/Download');
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Recent Files', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(height: 8),
              const _RecentFilesSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  const _QuickAction({required this.label, required this.icon, required this.gradient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _Category extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Category(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3), width: 1)),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _RecentFilesSection extends StatelessWidget {
  const _RecentFilesSection();

  @override
  Widget build(BuildContext context) {
    final files = context.watch<FileService>().recentFiles;
    if (files.isEmpty) {
      return const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No recent files loaded', style: TextStyle(color: Colors.white38))));
    }
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: files.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final file = files[index];
          return Container(
            width: 100,
            decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.06), width: 1)),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.insert_drive_file_rounded, color: AppTheme.primaryColor, size: 24),
                Text(file.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FileSearchDelegate extends SearchDelegate {
  final FileService fileService;
  FileSearchDelegate(this.fileService);

  @override
  ThemeData appBarTheme(BuildContext context) => ThemeData(
        scaffoldBackgroundColor: AppTheme.amoledBlack,
        inputDecorationTheme: const InputDecorationTheme(hintStyle: TextStyle(color: Colors.white38)),
        appBarTheme: const AppBarTheme(backgroundColor: AppTheme.amoledBlack),
        textTheme: const TextTheme(titleLarge: TextStyle(color: Colors.white, fontSize: 16)),
      );

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear, color: Colors.white), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => [IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => close(context, null))];

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<FileModel>>(
      future: fileService.searchFiles(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final results = snapshot.data!;
        if (results.isEmpty) return const Center(child: Text('No matching files found.', style: TextStyle(color: Colors.white38)));
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, i) => ListTile(
            leading: const Icon(Icons.insert_drive_file, color: AppTheme.primaryColor),
            title: Text(results[i].name, style: const TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: Text(results[i].formattedSize, style: const TextStyle(color: Colors.white38)),
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => Container();
}
