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
    return PopScope(
      canPop: _selectedIndex == 0, 
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0); // వేరే ట్యాబ్ లో బ్యాక్ నొక్కితే హోమ్ ట్యాబ్ కి తెస్తుంది 🛠️
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.amoledBlack,
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: GlassNavBar(
          selectedIndex: _selectedIndex,
          onItemSelected: (index) => setState(() => _selectedIndex = index),
        ),
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
          expandedHeight: 90,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            title: const Text(
              'CleanVault',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
              onPressed: () {
                showSearch(context: context, delegate: FileSearchDelegate(context.read<FileService>()));
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Minimal Storage Card View
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const StorageCard(),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Quick Clean', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white70)),
              ),
              const SizedBox(height: 12),
              
              // Cleaned Minimal Grid Actions 
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        label: 'Duplicates',
                        icon: Icons.copy_all_rounded,
                        color: const Color(0xFFFF6B6B),
                        onTap: () {
                          parentState?.setTab(2);
                          context.read<StorageService>().findDuplicates();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        label: 'Large Files',
                        icon: Icons.data_usage_rounded,
                        color: const Color(0xFF8B5CF6),
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
                child: Text('Browse Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white70)),
              ),
              const SizedBox(height: 12),

              // Horizontal Category List
              SizedBox(
                height: 85,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _CategoryItem('Images', Icons.image_rounded, AppTheme.primaryColor, () {
                      parentState?.setTab(1);
                      context.read<FileService>().loadFiles('/storage/emulated/0/DCIM');
                    }),
                    const SizedBox(width: 16),
                    _CategoryItem('Videos', Icons.videocam_rounded, const Color(0xFFFF6B6B), () {
                      parentState?.setTab(1);
                      context.read<FileService>().loadFiles('/storage/emulated/0/Movies');
                    }),
                    const SizedBox(width: 16),
                    _CategoryItem('Music', Icons.music_note_rounded, const Color(0xFF4ECDC4), () {
                      parentState?.setTab(1);
                      context.read<FileService>().loadFiles('/storage/emulated/0/Music');
                    }),
                    const SizedBox(width: 16),
                    _CategoryItem('Docs', Icons.description_rounded, const Color(0xFFFFD700), () {
                      parentState?.setTab(1);
                      context.read<FileService>().loadFiles('/storage/emulated/0/Documents');
                    }),
                    const SizedBox(width: 16),
                    _CategoryItem('Downloads', Icons.download_rounded, const Color(0xFF8B5CF6), () {
                      parentState?.setTab(1);
                      context.read<FileService>().loadFiles('/storage/emulated/0/Download');
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Recent Files', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white70)),
              ),
              const SizedBox(height: 12),
              const _RecentFilesSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CategoryItem(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.15)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
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
      return const Padding(padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16), child: Text('No recent files loaded', style: TextStyle(color: Colors.white38, fontSize: 13)));
    }
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: files.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final file = files[index];
          return Container(
            width: 110,
            decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.04))),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.insert_drive_file_rounded, color: AppTheme.primaryColor, size: 20),
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
        inputDecorationTheme: const InputDecorationTheme(hintStyle: TextStyle(color: Colors.white38, fontSize: 14), border: InputBorder.none),
        appBarTheme: const AppBarTheme(backgroundColor: AppTheme.amoledBlack, elevation: 0),
        textTheme: const TextTheme(titleLarge: TextStyle(color: Colors.white, fontSize: 15)),
      );

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear, color: Colors.white), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => close(context, null));

  @override
  Widget buildSuggestions(BuildContext context) => Container();

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
            title: Text(results[i].name, style: const TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: Text(results[i].formattedSize, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ),
        );
      },
    );
  }
}
