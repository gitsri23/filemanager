import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/ads/native_ad_widget.dart';
import '../../core/theme/app_theme.dart';
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
      context.read<StorageService>().analyzeStorage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
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
                  child: const Icon(Icons.folder_special_rounded,
                      size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text(
                  'CleanVault',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.white70),
              onPressed: () {},
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Storage card
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: StorageCard(),
              ).animate().slideY(begin: 0.2, end: 0, duration: 500.ms).fadeIn(),

              const SizedBox(height: 24),

              // Quick actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  'Quick Clean',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const _QuickActionsGrid(),

              const SizedBox(height: 24),

              // Native ad
              const NativeAdWidget(),

              const SizedBox(height: 24),

              // Categories
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Browse by Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const _CategoryGrid(),

              const SizedBox(height: 24),

              // Recent files
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Recent Files',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
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

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        label: 'Duplicates',
        icon: Icons.copy_all_rounded,
        gradient: AppTheme.warmGradient,
        onTap: () {},
      ),
      _QuickAction(
        label: 'Large Files',
        icon: Icons.data_usage_rounded,
        gradient: AppTheme.purpleGradient,
        onTap: () {},
      ),
      _QuickAction(
        label: 'WhatsApp',
        icon: Icons.chat_bubble_rounded,
        gradient: AppTheme.greenGradient,
        onTap: () {},
      ),
      _QuickAction(
        label: 'APK Files',
        icon: Icons.android_rounded,
        gradient: AppTheme.goldGradient,
        onTap: () {},
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: actions
            .asMap()
            .entries
            .map((e) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: e.key < actions.length - 1 ? 10 : 0,
                    ),
                    child: e.value,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  @override
  Widget build(BuildContext context) {
    final cats = [
      _Category('Images', Icons.image_rounded, AppTheme.primaryColor),
      _Category('Videos', Icons.videocam_rounded, const Color(0xFFFF6B6B)),
      _Category('Music', Icons.music_note_rounded, const Color(0xFF4ECDC4)),
      _Category('Docs', Icons.description_rounded, const Color(0xFFFFD700)),
      _Category('Downloads', Icons.download_rounded, const Color(0xFF8B5CF6)),
      _Category('APKs', Icons.android_rounded, const Color(0xFF00D4FF)),
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => cats[index],
      ),
    );
  }
}

class _Category extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Category(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
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
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No recent files',
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: files.take(20).length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final file = files[index];
          return Container(
            width: 100,
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  _iconForCategory(file.category),
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
                Text(
                  file.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _iconForCategory(dynamic cat) {
    switch (cat.toString()) {
      case 'FileCategory.image':
        return Icons.image_rounded;
      case 'FileCategory.video':
        return Icons.videocam_rounded;
      case 'FileCategory.audio':
        return Icons.music_note_rounded;
      case 'FileCategory.document':
        return Icons.description_rounded;
      case 'FileCategory.apk':
        return Icons.android_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}
