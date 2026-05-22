import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // 🛠️ URL లాంచర్ ఇంపోర్ట్ యాడ్ చేసాం
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // ─── 🛠️ లింక్ ఓపెన్ చేయడానికి సేఫ్ ఫంక్షన్ ───
  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://inshoert.blogspot.com/p/one-privacy-policy.html?m=1');
    try {
      // externalApplication ద్వారా బ్రౌజర్‌లో క్లీన్ గా ఓపెన్ అవుతుంది
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch policy URL');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<AppThemeNotifier>();

    return Scaffold(
      backgroundColor: AppTheme.amoledBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.amoledBlack,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('APPEARANCE', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: AppTheme.primaryColor,
                  title: const Text('AMOLED Dark Mode', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: const Text('True black background for OLED screens', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  value: themeNotifier.themeMode == ThemeMode.dark,
                  onChanged: (val) {
                    themeNotifier.setAmoledMode();
                  },
                ),
                const Divider(color: Colors.white10, height: 1, indent: 16),
                SwitchListTile(
                  activeColor: AppTheme.primaryColor,
                  title: const Text('Light Mode', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: const Text('Switch to light theme context', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  value: themeNotifier.themeMode == ThemeMode.light,
                  onChanged: (val) {
                    themeNotifier.toggleTheme();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('STORAGE', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16)),
            child: const ListTile(
              leading: Icon(Icons.folder_open_rounded, color: AppTheme.accentColor),
              title: Text('Default Browse Location', style: TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: Text('/storage/emulated/0', style: TextStyle(color: Colors.white38, fontSize: 11)),
              trailing: Icon(Icons.chevron_right_rounded, color: Colors.white24),
            ),
          ),
          const SizedBox(height: 24),
          const Text('ABOUT', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(color: AppTheme.cardDark, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded, color: Colors.white38),
                  title: Text('Version', style: TextStyle(color: Colors.white, fontSize: 14)),
                  trailing: Text('1.0.0', style: TextStyle(color: Colors.white38, fontSize: 14)),
                ),
                const Divider(color: Colors.white10, height: 1, indent: 16),
                
                // ─── 🛠️ ప్రైవసీ పాలసీ వర్కింగ్ బటన్ ───
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryColor),
                  title: const Text('Privacy Policy', style: TextStyle(color: Colors.white, fontSize: 14)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                  onTap: () {
                    // క్లిక్ చేయగానే మీ బ్లాగ్ లింక్ ఓపెన్ అవుతుంది
                    _launchPrivacyPolicy();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
