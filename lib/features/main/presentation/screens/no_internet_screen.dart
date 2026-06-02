import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
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

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: Stack(
        children: [
          // Glowing Ambient Blobs for rich modern visual interest
          Positioned(
            top: -60.h,
            left: -60.w,
            child: Container(
              width: 240.w,
              height: 240.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(isDark ? 0.08 : 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -80.h,
            right: -80.w,
            child: Container(
              width: 280.w,
              height: 280.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withOpacity(isDark ? 0.06 : 0.03),
              ),
            ),
          ),

          // Main Layout Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 20.h),
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
                            style: GoogleFonts.outfit(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.getTextMuted(context),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 60.h),

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
                              width: 170.w,
                              height: 170.h,
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
                              width: 140.w,
                              height: 140.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.error.withOpacity(0.06),
                              ),
                            ),
                          ),
                          // Core Animated Icon Container
                          Container(
                            width: 100.w,
                            height: 100.h,
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
                    SizedBox(height: 48.h),

                    // Title
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        'Connection Interrupted',
                        style: GoogleFonts.outfit(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.getText(context),
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Description text
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 300),
                      child: Text(
                        'It looks like you are not connected to the internet. Please check your network status to continue managing your expenses.',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: AppColors.getTextMuted(context),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 40.h),

                    // Steps card container
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 400),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                        decoration: BoxDecoration(
                          color: AppColors.getSurfaceContainer(context),
                          borderRadius: AppSizes.boxBorderRadius,
                          border: Border.all(
                            color: AppColors.isDark(context)
                                ? Colors.white.withOpacity(0.04)
                                : Colors.black.withOpacity(0.04),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Troubleshooting Tips:',
                              style: GoogleFonts.outfit(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.getText(context),
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(height: 14.h),
                            _buildChecklistItem(context, Icons.wifi_rounded, 'Check Wi-Fi connection'),
                            SizedBox(height: 12.h),
                            _buildChecklistItem(context, Icons.signal_cellular_alt_rounded, 'Verify cellular data status'),
                            SizedBox(height: 12.h),
                            _buildChecklistItem(context, Icons.airplanemode_inactive_rounded, 'Ensure Airplane Mode is turned off'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 48.h),

                    // Primary Retry Button
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 500),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52.h,
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
                                  style: GoogleFonts.outfit(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(BuildContext context, IconData icon, String text) {
    final isDark = AppColors.isDark(context);
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16.sp,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: AppColors.getText(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
