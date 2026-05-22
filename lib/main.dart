import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'core/ads/ad_service.dart';
import 'core/ads/app_open_ad_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_lifecycle_observer.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/file_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Init AdMob
  await MobileAds.instance.initialize();

  // Init services
  await AdService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FileService()),
        ChangeNotifierProvider(create: (_) => StorageService()),
        ChangeNotifierProvider(create: (_) => AppThemeNotifier()),
      ],
      child: const CleanVaultApp(),
    ),
  );
}

class CleanVaultApp extends StatefulWidget {
  const CleanVaultApp({super.key});

  @override
  State<CleanVaultApp> createState() => _CleanVaultAppState();
}

class _CleanVaultAppState extends State<CleanVaultApp> {
  late AppLifecycleObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = AppLifecycleObserver(
      onForeground: () => AppOpenAdManager.instance.showAdIfAvailable(),
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    AppOpenAdManager.instance.loadAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<AppThemeNotifier>();

    return MaterialApp(
      title: 'CleanVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.themeMode,
      home: const SplashScreen(),
    );
  }
}
