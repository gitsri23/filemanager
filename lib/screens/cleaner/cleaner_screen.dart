import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/ads/ad_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/file_model.dart';
import '../../services/storage_service.dart';

class CleanerScreen extends StatefulWidget {
  const CleanerScreen({super.key});

  @override
  State<CleanerScreen> createState() => _CleanerScreenState();
}

class _CleanerScreenState extends State<CleanerScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final storage = context.watch<StorageService>();

    return Scaffold(
      backgroundColor: AppTheme.amoledBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.amoledBlack,
        title: const Text(
          'Storage Cleaner',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () => storage.analyzeStorage(),
          ),
        ],
      ),
      body: storage.isAnalyzing
          ? _AnalyzingView(
              progress: storage.analyzeProgress,
              status: storage.analyzeStatus,
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                // Storage ring
                if (storage.storageInfo != null) ...[
                  _StorageRingCard(info: storage.storageInfo!),
                  const SizedBox(height: 16),
                  _CategoryBreakdown(info: storage.storageInfo!),
                ],

                const SizedBox(height: 16),

                // Cleaner actions
                _CleanerActionCard(
                  title: 'Find Duplicates',
                  subtitle: storage.duplicateGroups.isEmpty
                      ? 'Tap to scan for duplicate files'
                      : '${storage.duplicateGroups.length} groups found • ${_fmt(storage.totalDuplicateWaste)} wasted',
                  icon: Icons.copy_all_rounded,
                  gradient: AppTheme.warmGradient,
                  onTap: () => _findDuplicates(context, storage),
                ),

                _CleanerActionCard(
                  title: 'Large Files',
                  subtitle: storage.largeFiles.isEmpty
                      ? 'Tap to find large files'
                      : '${storage.largeFiles.length} files • ${_fmt(storage.totalLargeFileSize)}',
                  icon: Icons.data_usage_rounded,
                  gradient: AppTheme.purpleGradient,
                  onTap: () => _showLargeFiles(context, storage),
                ),

                // Deep clean - rewarded ad
                _CleanerActionCard(
                  title: '🔐 Deep Clean',
                  subtitle: 'Watch an ad to unlock deep cache cleaning',
                  icon: Icons.cleaning_services_rounded,
                  gradient: AppTheme.primaryGradient,
                  badge: 'REWARDED',
                  onTap: () => _deepCleanWithAd(context, storage),
                ),

                _CleanerActionCard(
                  title: 'WhatsApp Media',
                  subtitle: 'Clean old WhatsApp images & videos',
                  icon: Icons.chat_bubble_rounded,
                  gradient: AppTheme.greenGradient,
                  onTap: () => _cleanWhatsApp(context),
                ),

                _CleanerActionCard(
                  title: 'APK Manager',
                  subtitle: 'Find and remove unused APK files',
                  icon: Icons.android_rounded,
                  gradient: AppTheme.goldGradient,
                  onTap: () => _manageApks(context),
                ),

                // Duplicate list
                if (storage.duplicateGroups.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Duplicate Files',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                  ...storage.duplicateGroups.take(5).map((group) =>
                      _DuplicateGroupTile(
                        group: group,
                        onDelete: () async {
                          final freed = await storage
                              .deleteDuplicates([group]);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Freed ${_fmt(freed)}'),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                          }
                        },
                      )),
                ],

                // Large files list
                if (storage.largeFiles.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Large Files',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                  ...storage.largeFiles.take(10).map((f) => _LargeFileTile(file: f)),
                ],
              ],
            ),
    );
  }

  Future<void> _findDuplicates(
      BuildContext context, StorageService storage) async {
    await storage.findDuplicates();
  }

  Future<void> _showLargeFiles(
      BuildContext context, StorageService storage) async {
    if (storage.storageInfo == null) {
      await storage.analyzeStorage();
    }
    // Large files already loaded in analyzeStorage
    setState(() {});
  }

  Future<void> _deepCleanWithAd(
      BuildContext context, StorageService storage) async {
    // Show rewarded ad first
    final shown = await AdService.instance.showRewarded(
      onRewarded: (reward) async {
        final freed = await storage.deepClean();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deep clean complete! Freed ${_fmt(freed)}'),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );

    if (!shown && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad not ready yet. Try again in a moment.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _cleanWhatsApp(BuildContext context) async {
    // Navigate to whatsapp media screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Loading WhatsApp media...')),
    );
  }

  Future<void> _manageApks(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Loading APK files...')),
    );
  }

  static String _fmt(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    if (b < 1024 * 1024 * 1024) {
      return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(b / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class _AnalyzingView extends StatelessWidget {
  final double progress;
  final String status;

  const _AnalyzingView({required this.progress, required this.status});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation(
                          AppTheme.primaryColor),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageRingCard extends StatelessWidget {
  final StorageInfo info;
  const _StorageRingCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.2),
            AppTheme.accentColor.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: info.usagePercent,
                    strokeWidth: 8,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation(
                      info.usagePercent > 0.8
                          ? AppTheme.warningColor
                          : AppTheme.primaryColor,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(info.usagePercent * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'used',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StorageStat(
                    label: 'Total', value: info.formattedTotal, color: Colors.white70),
                const SizedBox(height: 8),
                _StorageStat(
                    label: 'Used',
                    value: info.formattedUsed,
                    color: AppTheme.warningColor),
                const SizedBox(height: 8),
                _StorageStat(
                    label: 'Free',
                    value: info.formattedFree,
                    color: AppTheme.successColor),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }
}

class _StorageStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StorageStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final StorageInfo info;
  const _CategoryBreakdown({required this.info});

  @override
  Widget build(BuildContext context) {
    final entries = info.categoryBreakdown.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'By Category',
            style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...entries.take(5).map((e) {
            final pct = info.usedSpace > 0
                ? e.value / info.usedSpace
                : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        e.key.name.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        FileModel._formatSize(e.value),
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation(
                          AppTheme.primaryColor),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CleanerActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final String? badge;
  final VoidCallback onTap;

  const _CleanerActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.goldColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppTheme.goldColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              color: AppTheme.goldColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DuplicateGroupTile extends StatelessWidget {
  final DuplicateGroup group;
  final VoidCallback onDelete;

  const _DuplicateGroupTile(
      {required this.group, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.warningColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '×${group.count}',
              style: TextStyle(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.files.first.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Text(
                  'Wasted: ${FileModel._formatSize(group.wastedSpace)}',
                  style: TextStyle(
                      color: AppTheme.warningColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: AppTheme.warningColor),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _LargeFileTile extends StatelessWidget {
  final FileModel file;
  const _LargeFileTile({required this.file});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.insert_drive_file_rounded,
            color: AppTheme.warningColor, size: 22),
      ),
      title: Text(
        file.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        file.formattedSize,
        style: TextStyle(
            color: AppTheme.warningColor,
            fontWeight: FontWeight.w600,
            fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38),
        onPressed: () {},
      ),
    );
  }
}
