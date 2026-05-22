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

class _CleanerScreenState extends State<CleanerScreen> with AutomaticKeepAliveClientMixin {
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
        title: const Text('Storage Cleaner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () => storage.analyzeStorage(),
          ),
        ],
      ),
      body: storage.isAnalyzing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primaryColor),
                  const SizedBox(height: 16),
                  Text(storage.analyzeStatus, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                if (storage.storageInfo != null) _buildStorageRingCard(storage.storageInfo!),

                const SizedBox(height: 16),
                
                // ─── 3 మెయిన్ రియల్ ఫీచర్స్ మాత్రమే ఉంచాం ───
                _CleanerActionCard(
                  title: 'Find Duplicates',
                  subtitle: storage.duplicateGroups.isEmpty ? 'Tap to scan for duplicate files' : '${storage.duplicateGroups.length} groups found • ${FileModel.formatSize(storage.totalDuplicateWaste)} wasted',
                  icon: Icons.copy_all_rounded,
                  gradient: AppTheme.warmGradient,
                  onTap: () => storage.findDuplicates(),
                ),

                _CleanerActionCard(
                  title: 'Large Files',
                  subtitle: storage.largeFiles.isEmpty ? 'Tap to find large files' : '${storage.largeFiles.length} files found • ${FileModel.formatSize(storage.totalLargeFileSize)}',
                  icon: Icons.data_usage_rounded,
                  gradient: AppTheme.purpleGradient,
                  onTap: () => setState(() {}),
                ),

                _CleanerActionCard(
                  title: '🔐 Deep Clean',
                  subtitle: 'Watch an ad to unlock deep cache cleaning',
                  icon: Icons.cleaning_services_rounded,
                  gradient: AppTheme.primaryGradient,
                  badge: 'REWARDED',
                  onTap: () => _deepCleanWithAd(context, storage),
                ),

                // Duplicate lists rendering mapping
                if (storage.duplicateGroups.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text('Duplicate Files', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white70)),
                  ),
                  ...storage.duplicateGroups.map((group) => _DuplicateGroupTile(
                        group: group,
                        onDelete: () async {
                          final freed = await storage.deleteDuplicates([group]);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Freed ${FileModel.formatSize(freed)}'), backgroundColor: AppTheme.successColor));
                          }
                        },
                      )),
                ],

                // Large lists rendering mapping
                if (storage.largeFiles.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text('Large Files (> 50MB)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white70)),
                  ),
                  ...storage.largeFiles.take(10).map((f) => ListTile(
                        leading: const Icon(Icons.insert_drive_file_rounded, color: Colors.redWithOpacity, size: 24),
                        title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        subtitle: Text(f.formattedSize, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      )),
                ],
              ],
            ),
    );
  }

  Future<void> _deepCleanWithAd(BuildContext context, StorageService storage) async {
    final shown = await AdService.instance.showRewarded(
      onRewarded: (reward) async {
        final freed = await storage.deepClean();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deep clean complete! Freed ${FileModel.formatSize(freed)}'), backgroundColor: AppTheme.successColor));
        }
      },
    );
    if (!shown && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ad not ready yet. Try again.'), backgroundColor: Colors.orange));
    }
  }

  Widget _buildStorageRingCard(StorageInfo info) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(
        children: [
          Text('${(info.usagePercent * 100).toInt()}% USED', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('Free: ${info.formattedFree} / Total: ${info.formattedTotal}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _CleanerActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final String? badge;
  final VoidCallback onTap;
  const _CleanerActionCard({required this.title, required this.subtitle, required this.icon, required this.gradient, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.03))),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            if (badge != null) Text(badge!, style: const TextStyle(color: AppTheme.goldColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _DuplicateGroupTile extends StatelessWidget {
  final DuplicateGroup group;
  final VoidCallback onDelete;
  const _DuplicateGroupTile({required this.group, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(group.files.first.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13)),
      subtitle: Text('Wasted: ${FileModel.formatSize(group.wastedSpace)}', style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
      trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: onDelete),
    );
  }
}
