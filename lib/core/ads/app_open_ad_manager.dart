import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_service.dart';

class AppOpenAdManager {
  AppOpenAdManager._();
  static final AppOpenAdManager instance = AppOpenAdManager._();

  AppOpenAd? _appOpenAd;
  bool _isLoadingAd = false;
  bool _isShowingAd = false;

  /// Tracks when the ad was loaded to enforce 4-hour expiry.
  DateTime? _adLoadTime;

  bool get _isAdAvailable {
    return _appOpenAd != null &&
        _adLoadTime != null &&
        DateTime.now().subtract(const Duration(hours: 4)).isBefore(_adLoadTime!);
  }

  void loadAd() {
    if (_isLoadingAd || _isAdAvailable) return;
    _isLoadingAd = true;

    AppOpenAd.load(
      adUnitId: AdService.instance.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isLoadingAd = false;
          _adLoadTime = DateTime.now();
          debugPrint('[AppOpenAd] Loaded');
        },
        onAdFailedToLoad: (error) {
          _isLoadingAd = false;
          debugPrint('[AppOpenAd] Failed to load: ${error.message}');
        },
      ),
    );
  }

  Future<void> showAdIfAvailable() async {
    if (!_isAdAvailable || _isShowingAd) {
      if (!_isAdAvailable) loadAd();
      return;
    }

    _isShowingAd = true;

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AppOpenAd] Showing');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AppOpenAd] Failed to show: ${error.message}');
        _isShowingAd = false;
        _appOpenAd = null;
        loadAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AppOpenAd] Dismissed');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );

    await _appOpenAd!.show();
  }
}
