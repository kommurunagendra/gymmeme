import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../core/constants/app_constants.dart';

class AdService {
  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;
  int _saveCount = 0;

  // Load interstitial on startup — show every 3rd meme save
  void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: AppConstants.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialReady = false;
              loadInterstitial(); // Pre-load next one
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              ad.dispose();
              _isInterstitialReady = false;
            },
          );
        },
        onAdFailedToLoad: (_) {
          _isInterstitialReady = false;
        },
      ),
    );
  }

  /// Call after every meme save — shows ad every 3rd save
  void onMemeSaved() {
    _saveCount++;
    if (_saveCount % 3 == 0) {
      showInterstitial();
    }
  }

  void showInterstitial() {
    if (_isInterstitialReady && _interstitialAd != null) {
      _interstitialAd!.show();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}

// Singleton provider — use in main.dart
final adServiceInstance = AdService();

// ─── Banner Ad Widget ────────────────────────────────────────────────────────

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: AppConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isLoaded = true),
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
