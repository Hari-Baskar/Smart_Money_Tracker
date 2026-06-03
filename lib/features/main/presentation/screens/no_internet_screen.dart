import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/services/connectivity_service.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';

class ConnectivityWrapper extends ConsumerWidget {
  final Widget child;

  const ConnectivityWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider);

    if (status == NetworkStatus.disconnected) {
      return const NoInternetScreen();
    }
    return child;
  }
}

class NoInternetScreen extends ConsumerWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider);
    final isDark = AppColors.isDark(context);
    final screenWidth = AppSizes.screenWidth;
    final screenHeight = AppSizes.screenHeight;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: Stack(
        children: [
          // Glowing Ambient Blobs for rich modern visual interest
          Positioned(
            top: -screenHeight * 0.08,
            left: -screenWidth * 0.16,
            child: Container(
              width: screenWidth * 0.65,
              height: screenWidth * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(isDark ? 0.08 : 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -screenHeight * 0.1,
            right: -screenWidth * 0.22,
            child: Container(
              width: screenWidth * 0.75,
              height: screenWidth * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withOpacity(isDark ? 0.06 : 0.03),
              ),
            ),
          ),

          // Main Layout Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.07,
                  vertical: screenHeight * 0.03,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.025),
                    // Elegant subtle app logo marker
                    FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 18.sp,
                            color: AppColors.primary.withOpacity(0.7),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'SMART MONEY TRACKER',
                            style: AppTextStyles.small(
                              context,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getTextMuted(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),

                    // Main Glowing Illustration Container (Wifi off indicator)
                    ElasticIn(
                      duration: const Duration(milliseconds: 1000),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer ambient circular rings
                          Pulse(
                            infinite: true,
                            duration: const Duration(seconds: 3),
                            child: Container(
                              width: screenWidth * 0.45,
                              height: screenWidth * 0.45,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.error.withOpacity(0.04),
                              ),
                            ),
                          ),
                          Pulse(
                            infinite: true,
                            duration: const Duration(seconds: 3),
                            delay: const Duration(milliseconds: 800),
                            child: Container(
                              width: screenWidth * 0.38,
                              height: screenWidth * 0.38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.error.withOpacity(0.06),
                              ),
                            ),
                          ),
                          // Core Animated Icon Container
                          Container(
                            width: screenWidth * 0.27,
                            height: screenWidth * 0.27,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.error.withOpacity(0.12),
                                  AppColors.error.withOpacity(0.06),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: AppColors.error.withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.error.withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Pulse(
                                infinite: true,
                                duration: const Duration(seconds: 2),
                                child: Icon(
                                  Icons.wifi_off_rounded,
                                  size: 46.sp,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.06),

                    // Title
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        'Connection Interrupted',
                        style: AppTextStyles.heading(
                          context,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getText(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),

                    // Description text
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 300),
                      child: Text(
                        'Please check your internet connection to continue.',
                        style: AppTextStyles.body(
                          context,
                          fontSize: 14.sp,
                          color: AppColors.getTextMuted(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Spacer(),

                    // Primary Retry Button
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 400),
                      child: SizedBox(
                        width: double.infinity,
                        height: screenHeight * 0.065,
                        child: ElevatedButton(
                          onPressed: status == NetworkStatus.checking
                              ? null
                              : () async {
                                  final isConnected = await ref
                                      .read(networkStatusProvider.notifier)
                                      .checkConnection();
                                  if (context.mounted) {
                                    if (isConnected) {
                                      AppToast.show(
                                        context,
                                        'Back online! Welcome back.',
                                        isError: false,
                                      );
                                    } else {
                                      AppToast.show(
                                        context,
                                        'Still offline. Please check your internet connection.',
                                        isError: true,
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSizes.boxBorderRadius,
                            ),
                          ),
                          child: status == NetworkStatus.checking
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Try Again',
                                  style: AppTextStyles.body(
                                    context,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.025),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
