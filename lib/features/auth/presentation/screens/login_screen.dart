import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/services/security_service.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter/gestures.dart';
import 'package:smart_money_tracker/core/constants/app_strings.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/restore_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGoogleLoading = useState(false);
    final isCheckingAuth = useState(true);
    final isDark = AppColors.isDark(context);

    useEffect(() {
      Future<void> checkAuth() async {
        try {
          final user = ref.read(authRepositoryProvider).currentUser;
          if (user != null) {
            final prefs = await SharedPreferences.getInstance();
            final disclosed = prefs.getBool('permissions_disclosed') ?? false;
            final securityService = ref.read(securityServiceProvider);
            final targetRoute = disclosed ? '/dashboard' : '/permissions';
            final requiresLock = await securityService
                .isAppLockEnabledOnLaunch();

            if (!context.mounted) return;

            if (requiresLock) {
              context.go('/app-lock', extra: targetRoute);
            } else {
              context.go(targetRoute);
            }
            return;
          }
        } catch (e) {
          debugPrint('Auth check error: $e');
        }

        if (context.mounted) {
          isCheckingAuth.value = false;
        }
      }

      checkAuth();
      return null;
    }, []);

    Future<void> handlePostLoginNavigation() async {
      final user = ref.read(authStateProvider).value;
      if (user != null && !user.isAnonymous) {
        final deviceInfo = DeviceInfoPlugin();
        final firebaseUser = FirebaseAuth.instance.currentUser;

        final isNewUser =
            firebaseUser != null &&
            firebaseUser.metadata.creationTime != null &&
            firebaseUser.metadata.lastSignInTime != null &&
            firebaseUser.metadata.creationTime!
                    .difference(firebaseUser.metadata.lastSignInTime!)
                    .inSeconds
                    .abs() <
                5;

        final results = await Future.wait([
          isNewUser
              ? Future.value(null)
              : ref.read(authRepositoryProvider).getUserSettings(user.id),
          ref
              .read(transactionRepositoryProvider)
              .getLocalTransactionCount(user.id),
          isNewUser
              ? Future.value(0)
              : ref
                    .read(transactionRepositoryProvider)
                    .getRemoteTransactionCount(user.id),
          Platform.isAndroid ? deviceInfo.androidInfo : Future.value(null),
          Platform.isIOS ? deviceInfo.iosInfo : Future.value(null),
          SharedPreferences.getInstance(),
        ]);

        var settings = results[0] as Map<String, dynamic>?;
        final localCount = results[1] as int;
        final remoteCount = results[2] as int;
        final androidInfo = results[3] as AndroidDeviceInfo?;
        final iosInfo = results[4] as IosDeviceInfo?;
        final prefs = results[5] as SharedPreferences;

        String? currentDeviceId;
        String? currentDeviceName;

        if (androidInfo != null) {
          currentDeviceId = androidInfo.id;
          currentDeviceName =
              '${androidInfo.manufacturer} ${androidInfo.model}';
        } else if (iosInfo != null) {
          currentDeviceId = iosInfo.identifierForVendor;
          currentDeviceName = iosInfo.name;
        }

        if (settings != null && settings.containsKey('active_device_id')) {
          final activeDeviceId = settings['active_device_id'] as String?;
          final activeDeviceName = settings['active_device_name'] as String?;

          if (activeDeviceId != null && activeDeviceId != currentDeviceId) {
            bool forceLogin = false;
            if (context.mounted) {
              forceLogin =
                  await context.push<bool>(
                    '/force-logout',
                    extra: activeDeviceName,
                  ) ??
                  false;
            }

            if (!forceLogin) {
              await ref.read(authNotifierProvider.notifier).signOut();
              return;
            }
          }
        }

        if (currentDeviceId != null) {
          ref.read(authRepositoryProvider).saveUserSettings(user.id, {
            'active_device_id': currentDeviceId,
            'active_device_name': currentDeviceName,
          });
        }

        if (settings != null) {
          if (settings.containsKey('permissions_disclosed')) {
            prefs.setBool(
              'permissions_disclosed',
              settings['permissions_disclosed'] as bool,
            );
          }
          if (settings.containsKey('sms_consent')) {
            prefs.setBool('sms_consent', settings['sms_consent'] as bool);
          }
        }

        ref
            .read(transactionRepositoryProvider)
            .fetchIgnoredTransactionsFromCloud(user.id)
            .catchError((e) {
              debugPrint('Error fetching ignored transactions silently: $e');
            });

        if (localCount == 0 && remoteCount > 0) {
          await ref
              .read(restoreNotifierProvider.notifier)
              .setRestoreCount(remoteCount);
          if (context.mounted) context.go('/sync-disclosure');
          return;
        } else if (remoteCount > localCount) {
          ref
              .read(transactionRepositoryProvider)
              .restoreTransactions(user.id)
              .catchError((e) {
                debugPrint('Error during background delta sync: $e');
              });
        }

        final disclosed = prefs.getBool('permissions_disclosed') ?? false;
        if (context.mounted) {
          if (!disclosed) {
            context.go('/permissions');
          } else {
            context.go('/dashboard');
          }
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        final disclosed = prefs.getBool('permissions_disclosed') ?? false;
        if (context.mounted) {
          if (!disclosed) {
            context.go('/permissions');
          } else {
            context.go('/dashboard');
          }
        }
      }
    }

    Future<void> loginWithGoogle() async {
      isGoogleLoading.value = true;
      try {
        final success = await ref
            .read(authNotifierProvider.notifier)
            .signInWithGoogle();
        if (!success) return;

        await handlePostLoginNavigation();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      } finally {
        isGoogleLoading.value = false;
      }
    }

    final termsRecognizer = useMemoized(
      () => TapGestureRecognizer()
        ..onTap = () {
          if (context.mounted) {
            context.push(
              '/settings-detail',
              extra: {
                'title': 'Terms & Conditions',
                'content': AppStrings.termsAndConditionsContent,
              },
            );
          }
        },
    );

    final privacyRecognizer = useMemoized(
      () => TapGestureRecognizer()
        ..onTap = () {
          if (context.mounted) {
            context.push(
              '/settings-detail',
              extra: {
                'title': 'Privacy Policy',
                'content': AppStrings.privacyPolicyContent,
              },
            );
          }
        },
    );

    if (isCheckingAuth.value) {
      return Scaffold(
        backgroundColor: AppColors.getSurfaceContainerLowest(context),
        body: const SizedBox.shrink(),
      );
    }

    final bgMainColor = isDark
        ? AppColors.backgroundDark
        : const Color(0xFFF9FAF8);
    final titleTextColor = isDark
        ? const Color(0xFFE8F5E9)
        : const Color(0xFF173024);
    final subtitleColor = isDark
        ? const Color(0xFFA5C1B2)
        : const Color(0xFF5A7265);
    final buttonBg = isDark ? const Color(0xFF2C3E34) : const Color(0xFFFFFFFF);
    final buttonTextColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF132A1F);

    return Scaffold(
      backgroundColor: bgMainColor,
      body: Stack(
        children: [
          // Bottom organic wavy hills
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 220.h,
            child: CustomPaint(
              painter: _BottomHillsPainter(isDark: isDark),
              size: Size(double.infinity, 220.h),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 36.h),

                  // Title: Finzo
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      AppStrings.baseAppName,
                      style: AppTextStyles.heading(
                        context,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: titleTextColor,
                      ).copyWith(letterSpacing: -0.5),
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Subtitle: Track your money. / Build a better you.
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      'Track your money.\nBuild a better you.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.subHeading(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ).copyWith(height: 1.35),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Center Financial Growth Illustration
                  FadeIn(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 700),
                    child: Center(
                      child: CustomPaint(
                        size: Size(220.w, 180.h),
                        painter: _GrowthIllustrationPainter(isDark: isDark),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // 3 Column Features Row
                  FadeInUp(
                    delay: const Duration(milliseconds: 300),
                    duration: const Duration(milliseconds: 600),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildFeatureColumn(
                          context,
                          'Understand',
                          'your spending',
                          subtitleColor,
                        ),
                        _buildVerticalDivider(isDark),
                        _buildFeatureColumn(
                          context,
                          'Stay within',
                          'your budget',
                          subtitleColor,
                        ),
                        _buildVerticalDivider(isDark),
                        _buildFeatureColumn(
                          context,
                          'Reach your',
                          'goals',
                          subtitleColor,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // "Continue with Google" Pill Button
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      width: double.infinity,
                      height: 44.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.35 : 0.08,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isGoogleLoading.value
                            ? null
                            : loginWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonBg,
                          foregroundColor: buttonTextColor,
                          elevation: 0,
                          shape: const StadiumBorder(),
                          splashFactory: InkRipple.splashFactory,
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                        ),
                        child: isGoogleLoading.value
                            ? SizedBox(
                                height: 24.r,
                                width: 24.r,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primary,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/google.png',
                                    height: 24.r,
                                    width: 24.r,
                                  ),
                                  SizedBox(width: 14.w),
                                  Text(
                                    'Continue with Google',
                                    style: AppTextStyles.body(
                                      context,

                                      fontWeight: FontWeight.w500,
                                      color: buttonTextColor,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Terms & Privacy Links Footer
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    duration: const Duration(milliseconds: 600),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTextStyles.body(
                          context,

                          color: subtitleColor,
                        ).copyWith(height: 1.45),
                        children: [
                          const TextSpan(
                            text: 'By continuing, you agree to Finzo’s\n',
                          ),
                          TextSpan(
                            text: 'Terms and Conditions',
                            style: AppTextStyles.body(
                              context,

                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF66BB6A)
                                  : AppColors.primary,
                            ),
                            recognizer: termsRecognizer,
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: AppTextStyles.body(
                              context,

                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF66BB6A)
                                  : AppColors.primary,
                            ),
                            recognizer: privacyRecognizer,
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom > 0
                        ? MediaQuery.of(context).padding.bottom + 4.h
                        : 16.h,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureColumn(
    BuildContext context,
    String topText,
    String bottomText,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          topText,
          textAlign: TextAlign.center,
          style: AppTextStyles.small(
            context,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: color,
          ).copyWith(height: 1.25),
        ),
        SizedBox(height: 2.h),
        Text(
          bottomText,
          textAlign: TextAlign.center,
          style: AppTextStyles.small(
            context,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: color,
          ).copyWith(height: 1.25),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      width: 1.w,
      height: 24.h,
      color: isDark
          ? Colors.white.withValues(alpha: 0.15)
          : const Color(0xFFD4DEC9),
    );
  }
}

/// Custom painter for the organic growth bar chart illustration
class _GrowthIllustrationPainter extends CustomPainter {
  final bool isDark;

  _GrowthIllustrationPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Background Organic Blob
    final blobPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1E3528).withValues(alpha: 0.6)
          : const Color(0xFFE8F1EA)
      ..style = PaintingStyle.fill;

    final blobPath = Path();
    blobPath.moveTo(w * 0.28, h * 0.24);
    blobPath.cubicTo(
      w * 0.40,
      h * 0.12,
      w * 0.70,
      h * 0.16,
      w * 0.76,
      h * 0.35,
    );
    blobPath.cubicTo(
      w * 0.82,
      h * 0.52,
      w * 0.88,
      h * 0.78,
      w * 0.68,
      h * 0.88,
    );
    blobPath.cubicTo(
      w * 0.48,
      h * 0.98,
      w * 0.22,
      h * 0.92,
      w * 0.16,
      h * 0.68,
    );
    blobPath.cubicTo(
      w * 0.10,
      h * 0.44,
      w * 0.16,
      h * 0.32,
      w * 0.28,
      h * 0.24,
    );
    blobPath.close();
    canvas.drawPath(blobPath, blobPaint);

    final baseY = h * 0.84;

    // 2. Bar charts (3 ascending bars)
    final barPaint = Paint()
      ..color = isDark ? const Color(0xFF4E8268) : const Color(0xFF86B49C)
      ..style = PaintingStyle.fill;

    final barRadius = Radius.circular(w * 0.035);

    // Bar 1 (left/smallest)
    final bar1Rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.28, baseY - (h * 0.30), w * 0.11, h * 0.30),
      barRadius,
    );
    canvas.drawRRect(bar1Rect, barPaint);

    // Bar 2 (middle)
    final bar2Rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.43, baseY - (h * 0.46), w * 0.11, h * 0.46),
      barRadius,
    );
    canvas.drawRRect(bar2Rect, barPaint);

    // Bar 3 (right/tallest)
    final bar3Paint = Paint()
      ..color = isDark ? const Color(0xFF387355) : const Color(0xFF558E72)
      ..style = PaintingStyle.fill;
    final bar3Rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.58, baseY - (h * 0.60), w * 0.11, h * 0.60),
      barRadius,
    );
    canvas.drawRRect(bar3Rect, bar3Paint);

    // 3. Baseline horizontal stroke
    final linePaint = Paint()
      ..color = isDark ? const Color(0xFF387355) : const Color(0xFF32624B)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.20, baseY),
      Offset(w * 0.80, baseY),
      linePaint,
    );

    // 4. Upward growth trend curve
    final arrowPaint = Paint()
      ..color = isDark ? const Color(0xFF81C784) : const Color(0xFF1E4633)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final curvePath = Path();
    curvePath.moveTo(w * 0.30, baseY - (h * 0.42));
    curvePath.quadraticBezierTo(
      w * 0.48,
      baseY - (h * 0.48),
      w * 0.60,
      baseY - (h * 0.72),
    );
    canvas.drawPath(curvePath, arrowPaint);

    // Spark / shine dashes near top of arrow
    final sparkPaint = Paint()
      ..color = isDark ? const Color(0xFF81C784) : const Color(0xFF1E4633)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Spark 1
    canvas.drawLine(
      Offset(w * 0.68, baseY - (h * 0.76)),
      Offset(w * 0.69, baseY - (h * 0.81)),
      sparkPaint,
    );
    // Spark 2
    canvas.drawLine(
      Offset(w * 0.72, baseY - (h * 0.71)),
      Offset(w * 0.77, baseY - (h * 0.73)),
      sparkPaint,
    );

    // 5. Sprout plant with 2 leaves
    final sproutPaint = Paint()
      ..color = isDark ? const Color(0xFF81C784) : const Color(0xFF28553F)
      ..style = PaintingStyle.fill;

    // Sprout stem
    final stemPaint = Paint()
      ..color = isDark ? const Color(0xFF81C784) : const Color(0xFF28553F)
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final stemPath = Path();
    stemPath.moveTo(w * 0.74, baseY);
    stemPath.quadraticBezierTo(
      w * 0.74,
      baseY - (h * 0.16),
      w * 0.73,
      baseY - (h * 0.22),
    );
    canvas.drawPath(stemPath, stemPaint);

    // Right leaf
    final rightLeafPath = Path();
    rightLeafPath.moveTo(w * 0.74, baseY - (h * 0.12));
    rightLeafPath.cubicTo(
      w * 0.80,
      baseY - (h * 0.16),
      w * 0.88,
      baseY - (h * 0.28),
      w * 0.85,
      baseY - (h * 0.32),
    );
    rightLeafPath.cubicTo(
      w * 0.78,
      baseY - (h * 0.30),
      w * 0.74,
      baseY - (h * 0.20),
      w * 0.74,
      baseY - (h * 0.12),
    );
    rightLeafPath.close();
    canvas.drawPath(rightLeafPath, sproutPaint);

    // Left leaf
    final leftLeafPath = Path();
    leftLeafPath.moveTo(w * 0.73, baseY - (h * 0.18));
    leftLeafPath.cubicTo(
      w * 0.69,
      baseY - (h * 0.22),
      w * 0.66,
      baseY - (h * 0.30),
      w * 0.68,
      baseY - (h * 0.34),
    );
    leftLeafPath.cubicTo(
      w * 0.72,
      baseY - (h * 0.30),
      w * 0.73,
      baseY - (h * 0.24),
      w * 0.73,
      baseY - (h * 0.18),
    );
    leftLeafPath.close();
    canvas.drawPath(leftLeafPath, sproutPaint);
  }

  @override
  bool shouldRepaint(covariant _GrowthIllustrationPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

/// Custom painter for the layered soft organic hills at the bottom
class _BottomHillsPainter extends CustomPainter {
  final bool isDark;

  _BottomHillsPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Back Hill
    final backPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1B2E24).withValues(alpha: 0.6)
          : const Color(0xFFE5EFE7)
      ..style = PaintingStyle.fill;

    final backPath = Path();
    backPath.moveTo(0, h * 0.35);
    backPath.cubicTo(w * 0.30, h * 0.45, w * 0.65, h * 0.10, w, h * 0.25);
    backPath.lineTo(w, h);
    backPath.lineTo(0, h);
    backPath.close();
    canvas.drawPath(backPath, backPaint);

    // Front Hill
    final frontPaint = Paint()
      ..color = isDark
          ? const Color(0xFF223B2E).withValues(alpha: 0.7)
          : const Color(0xFFD6E8DA)
      ..style = PaintingStyle.fill;

    final frontPath = Path();
    frontPath.moveTo(0, h * 0.40);
    frontPath.cubicTo(w * 0.40, h * 0.70, w * 0.70, h * 0.75, w, h * 0.50);
    frontPath.lineTo(w, h);
    frontPath.lineTo(0, h);
    frontPath.close();
    canvas.drawPath(frontPath, frontPaint);
  }

  @override
  bool shouldRepaint(covariant _BottomHillsPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
