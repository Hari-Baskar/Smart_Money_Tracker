import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/services/update_service.dart';
import 'package:smart_money_tracker/core/constants/app_strings.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> with WidgetsBindingObserver {
  BannerAd? _bannerAd;
  bool _bannerAdIsLoaded = false;

  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;

  // Google Test Banner Ad Unit IDs
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' 
      : 'ca-app-pub-3940256099942544/2934735716'; 

  // Google Test Native Ad Unit IDs
  final String _testNativeAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/2247696110'
      : 'ca-app-pub-3940256099942544/3986694507';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused) {
      // Release ads instantly when the device locks or the app goes to background
      // This prevents suspicious ghost ad refreshes when the user is inactive!
      _disposeAds();
    } else if (state == AppLifecycleState.resumed) {
      // Trigger a state rebuild to safely reload fresh ads when the user returns
      setState(() {});
    }
  }

  void _loadBannerAd(bool isTestMode) {
    if (_bannerAd != null) return; 

    final String prodAdUnitId = Platform.isAndroid
        ? AppStrings.androidBannerAdUnitId
        : 'ca-app-pub-3940256099942544/2934735716'; 

    final adUnitToUse = isTestMode ? _adUnitId : prodAdUnitId;

    _bannerAd = BannerAd(
      adUnitId: adUnitToUse,
      size: AdSize.banner, // 320x50 standard banner
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

  void _loadNativeAd(bool isTestMode) {
    if (_nativeAd != null) return;

    final String prodNativeAdUnitId = Platform.isAndroid
        ? AppStrings.androidNativeAdUnitId
        : 'ca-app-pub-3940256099942544/3986694507';

    final adUnitToUse = isTestMode ? _testNativeAdUnitId : prodNativeAdUnitId;

    _nativeAd = NativeAd(
      adUnitId: adUnitToUse,
      factoryId: 'listTile', // Matches NativeAdFactory registered in MainActivity.kt
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          debugPrint('$NativeAd loaded.');
          setState(() {
            _nativeAdIsLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('$NativeAd failedToLoad: $error');
          ad.dispose();
          setState(() {
            _nativeAdIsLoaded = false;
            _nativeAd = null;
          });
        },
      ),
    )..load();
  }

  void _disposeAds() {
    if (_bannerAd != null) {
      _bannerAd?.dispose();
      _bannerAd = null;
      _bannerAdIsLoaded = false;
    }
    if (_nativeAd != null) {
      _nativeAd?.dispose();
      _nativeAd = null;
      _nativeAdIsLoaded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final updateStateAsync = ref.watch(updateProvider);

    return updateStateAsync.when(
      data: (state) {
        final config = state.config;
        if (config == null || !config.showAds) {
          _disposeAds();
          return const SizedBox.shrink();
        }

        if (config.isNative) {
          // Dispose of Banner Ad if we are in Native Mode
          if (_bannerAd != null) {
            _bannerAd?.dispose();
            _bannerAd = null;
            _bannerAdIsLoaded = false;
          }
          if (!_nativeAdIsLoaded && _nativeAd == null) {
            _loadNativeAd(config.testAds);
          }
        } else {
          // Dispose of Native Ad if we are in Banner Mode
          if (_nativeAd != null) {
            _nativeAd?.dispose();
            _nativeAd = null;
            _nativeAdIsLoaded = false;
          }
          if (!_bannerAdIsLoaded && _bannerAd == null) {
            _loadBannerAd(config.testAds);
          }
        }

        if (config.isNative && _nativeAdIsLoaded && _nativeAd != null) {
          return Container(
            alignment: Alignment.center,
            width: double.infinity,
            height: 340, // Height matching our redesigned card layout in my_native_ad.xml
            child: AdWidget(ad: _nativeAd!),
          );
        } else if (!config.isNative && _bannerAdIsLoaded && _bannerAd != null) {
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
    WidgetsBinding.instance.removeObserver(this);
    _bannerAd?.dispose();
    _nativeAd?.dispose();
    super.dispose();
  }
}
