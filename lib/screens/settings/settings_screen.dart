import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<AppThemeNotifier>();

    return Scaffold(
      backgroundColor: AppTheme.amoledBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.amoledBlack,
        title: const Text(
          'Settings',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: ListView(
        children: [
          _Section(
            title: 'Appearance',
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_rounded,
                iconColor: AppTheme.primaryColor,
                title: 'AMOLED Dark Mode',
                subtitle: 'True black background for OLED screens',
                trailing: Switch(
                  value: themeNotifier.isAmoled,
                  onChanged: (_) => themeNotifier.setAmoledMode(),
                  activeColor: AppTheme.primaryColor,
                ),
              ),
              _SettingsTile(
                icon: Icons.light_mode_rounded,
                iconColor: AppTheme.goldColor,
                title: 'Light Mode',
                subtitle: 'Switch to light theme',
                trailing: Switch(
                  value: themeNotifier.themeMode == ThemeMode.light,
                  onChanged: (_) => themeNotifier.toggleTheme(),
                  activeColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          _Section(
            title: 'Storage',
            children: [
              _SettingsTile(
                icon: Icons.folder_rounded,
                iconColor: AppTheme.successColor,
                title: 'Default Browse Location',
                subtitle: '/storage/emulated/0',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.delete_sweep_rounded,
                iconColor: AppTheme.warningColor,
                title: 'Recycle Bin',
                subtitle: 'Manage deleted files',
                onTap: () {},
              ),
            ],
          ),
          _Section(
            title: 'About',
            children: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                iconColor: Colors.white38,
                title: 'Version',
                subtitle: '1.0.0',
              ),
              _SettingsTile(
                icon: Icons.policy_outlined,
                iconColor: Colors.white38,
                title: 'Privacy Policy',
                subtitle: 'View our privacy policy',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.star_outline_rounded,
                iconColor: AppTheme.goldColor,
                title: 'Rate CleanVault',
                subtitle: 'Enjoying the app? Leave a review!',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10, width: 1),
          ),
          child: Column(
            children: children
                .asMap()
                .entries
                .map((e) => Column(
                      children: [
                        e.value,
                        if (e.key < children.length - 1)
                          const Divider(
                            height: 1,
                            color: Color(0xFF1A1A1A),
                            indent: 60,
                          ),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded,
                  color: Colors.white24, size: 18)
              : null),
    );
  }
}
