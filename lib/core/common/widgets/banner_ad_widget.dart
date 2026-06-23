import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/services/update_service.dart';
import 'package:smart_money_tracker/core/constants/app_strings.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/history_screen.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  final bool forceBanner;
  const BannerAdWidget({super.key, this.forceBanner = false});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> with WidgetsBindingObserver {
  BannerAd? _bannerAd;
  bool _bannerAdIsLoaded = false;

  // Google Test Banner Ad Unit IDs
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' 
      : 'ca-app-pub-3940256099942544/2934735716';

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



  void _disposeAds() {
    if (_bannerAd != null) {
      _bannerAd?.dispose();
      _bannerAd = null;
      _bannerAdIsLoaded = false;
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

        if (!_bannerAdIsLoaded && _bannerAd == null) {
          _loadBannerAd(config.testAds);
        }

        final isInsideHistory = context.findAncestorWidgetOfExactType<HistoryScreen>() != null;
        final double hMargin = isInsideHistory ? AppSizes.w(20) : 0;

        if (_bannerAdIsLoaded && _bannerAd != null) {
          return Center(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: hMargin, vertical: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'ADVERTISEMENT',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ],
              ),
            ),
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
    super.dispose();
  }
}
