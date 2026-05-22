import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Central ad service — all AdMob unit IDs in one place.
/// Replace test IDs with real ones before publishing.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;

  // ─── Ad Unit IDs ──────────────────────────────────────────────────────────
  // TODO: Replace with real production IDs from AdMob dashboard

  String get _appOpenId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/9257395921' // Test
      : 'ca-app-pub-3940256099942544/5575463023';

  String get _bannerUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' // Test
      : 'ca-app-pub-3940256099942544/2934735716';

  String get _interstitialUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712' // Test
      : 'ca-app-pub-3940256099942544/4411468910';

  String get _rewardedUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917' // Test
      : 'ca-app-pub-3940256099942544/1712485313';

  String get _nativeUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/2247696110' // Test
      : 'ca-app-pub-3940256099942544/3986624511';

  // ─── Getters (public) ────────────────────────────────────────────────────
  String get appOpenAdUnitId => _appOpenId;
  String get bannerAdUnitId => _bannerUnitId;
  String get interstitialAdUnitId => _interstitialUnitId;
  String get rewardedAdUnitId => _rewardedUnitId;
  String get nativeAdUnitId => _nativeUnitId;

  // ─── Cached ads ──────────────────────────────────────────────────────────
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialLoading = false;
  bool _isRewardedLoading = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
    _preloadInterstitial();
    _preloadRewarded();
    debugPrint('[AdService] Initialized');
  }

  // ─── Interstitial ────────────────────────────────────────────────────────

  void _preloadInterstitial() {
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          debugPrint('[AdService] Interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          debugPrint('[AdService] Interstitial failed: ${error.message}');
        },
      ),
    );
  }

  Future<bool> showInterstitial({VoidCallback? onDismissed}) async {
    if (_interstitialAd == null) {
      _preloadInterstitial();
      return false;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _preloadInterstitial();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _preloadInterstitial();
        debugPrint('[AdService] Interstitial show failed: ${error.message}');
      },
    );

    await _interstitialAd!.show();
    return true;
  }

  // ─── Rewarded ────────────────────────────────────────────────────────────

  void _preloadRewarded() {
    if (_isRewardedLoading || _rewardedAd != null) return;
    _isRewardedLoading = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
          debugPrint('[AdService] Rewarded loaded');
        },
        onAdFailedToLoad: (error) {
          _isRewardedLoading = false;
          debugPrint('[AdService] Rewarded failed: ${error.message}');
        },
      ),
    );
  }

  Future<bool> showRewarded({
    required void Function(RewardItem reward) onRewarded,
    VoidCallback? onDismissed,
  }) async {
    if (_rewardedAd == null) {
      _preloadRewarded();
      return false;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _preloadRewarded();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _preloadRewarded();
      },
    );

    await _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      onRewarded(reward);
    });
    return true;
  }

  // ─── Banner ──────────────────────────────────────────────────────────────

  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    );
  }

  // ─── Native ──────────────────────────────────────────────────────────────

  NativeAd createNativeAd({
    required NativeAdListener listener,
    required NativeTemplateStyle templateStyle,
  }) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      listener: listener,
      request: const AdRequest(),
      nativeTemplateStyle: templateStyle,
    );
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
