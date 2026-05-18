import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/services/update_service.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _bannerAdIsLoaded = false;

  // Google Test Banner Ad Unit IDs
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' 
      : 'ca-app-pub-3940256099942544/2934735716'; 

  @override
  void initState() {
    super.initState();
  }

  void _loadAd(bool isTestMode) {
    if (_bannerAd != null) return; 

    final adUnitToUse = isTestMode ? _adUnitId : _adUnitId; // TODO: Put production ID here

    _bannerAd = BannerAd(
      adUnitId: adUnitToUse,
      size: AdSize.largeBanner, // 320x100 banner
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('$BannerAd loaded.');
          setState(() {
            _bannerAdIsLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('$BannerAd failedToLoad: $error');
          ad.dispose();
          setState(() {
            _bannerAdIsLoaded = false;
            _bannerAd = null;
          });
        },
      ),
    )..load();
  }

  @override
  Widget build(BuildContext context) {
    final updateStateAsync = ref.watch(updateProvider);

    return updateStateAsync.when(
      data: (state) {
        final config = state.config;
        if (config == null || !config.showAds) {
          return const SizedBox.shrink();
        }

        if (!_bannerAdIsLoaded && _bannerAd == null) {
          _loadAd(config.testAds);
        }

        if (_bannerAdIsLoaded && _bannerAd != null) {
          return Container(
            alignment: Alignment.center,
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          );
        }

        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}
