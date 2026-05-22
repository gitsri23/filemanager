import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../services/storage_service.dart';

class StorageCard extends StatelessWidget {
  const StorageCard({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final info = storage.storageInfo;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.25),
            AppTheme.accentColor.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage_rounded,
                  color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Storage',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (storage.isAnalyzing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          if (info == null) ...[
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Analyzing storage...',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ] else ...[
            // Usage bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    color: Colors.white12,
                  ),
                  FractionallySizedBox(
                    widthFactor: info.usagePercent.clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: info.usagePercent > 0.85
                            ? AppTheme.warmGradient
                            : AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _StorageStat(
                    label: 'Used',
                    value: info.formattedUsed,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _StorageStat(
                    label: 'Free',
                    value: info.formattedFree,
                    color: AppTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _StorageStat(
                    label: 'Total',
                    value: info.formattedTotal,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }
}
