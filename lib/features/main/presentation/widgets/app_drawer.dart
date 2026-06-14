import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'dart:ui' as ui;
import 'package:share_plus/share_plus.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:smart_money_tracker/core/services/analytics_service.dart';
import 'package:smart_money_tracker/core/services/test_data_service.dart';

class AppDrawer extends HookConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        statusBarIconBrightness:
            Brightness.light, // White status bar icons on dark green header
        statusBarBrightness: Brightness.dark, // iOS status bar text style
        systemNavigationBarColor: AppColors.transparent,
        systemNavigationBarIconBrightness: AppColors.isDark(context)
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Drawer(
        width: AppSizes.drawerWidth,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppSizes.boxRadius),
            bottomRight: Radius.circular(AppSizes.boxRadius),
          ),
        ),
        child: Column(
          children: [
            // Header - Space Saving, Compact, and Premium Design
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                AppSizes.w16,
                MediaQuery.of(context).padding.top + AppSizes.h16,
                AppSizes.w16,
                AppSizes.h16,
              ),
              color: AppColors.primary,
              child: () {
                final profile = userProfileAsync.value;

                if (profile != null) {
                  final isAnonymous = profile['isAnonymous'] == 'true';
                  if (isAnonymous) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: AppSizes.r24,
                              backgroundColor: AppColors.white.withOpacity(0.2),
                              backgroundImage:
                                  profile['photoUrl'] != null &&
                                      profile['photoUrl']!.isNotEmpty
                                  ? NetworkImage(profile['photoUrl']!)
                                  : null,
                              child:
                                  profile['photoUrl'] == null ||
                                      profile['photoUrl']!.isEmpty
                                  ? Icon(
                                      Icons.person_outline_rounded,
                                      size: AppSizes.h24,
                                      color: AppColors.white,
                                    )
                                  : null,
                            ),
                            SizedBox(width: AppSizes.w12),
                            Expanded(
                              child: Text(
                                profile['name'] != null &&
                                        profile['name']!.isNotEmpty
                                    ? profile['name']!
                                    : 'Guest User',
                                style: AppTextStyles.heading(
                                  context,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSizes.h12),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.w12,
                            vertical: AppSizes.h8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.12),
                            borderRadius: AppSizes.cardBorderRadius,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Link account to save permanently',
                                  style: AppTextStyles.small(
                                    context,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: AppSizes.w8),
                              ElevatedButton(
                                onPressed: () async {
                                  // 1. Show a beautiful, non-dismissible loading dialog
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => PopScope(
                                      canPop: false,
                                      child: Dialog(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppSizes.r20,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: AppSizes.h32,
                                            horizontal: AppSizes.w24,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const CircularProgressIndicator(
                                                color: AppColors.primary,
                                                strokeWidth: 3,
                                              ),
                                              SizedBox(height: AppSizes.h24),
                                              Text(
                                                'Linking Account',
                                                style: AppTextStyles.heading(
                                                  context,
                                                ),
                                              ),
                                              SizedBox(height: AppSizes.h8),
                                              Text(
                                                'Securing and syncing your data safely...',
                                                style: AppTextStyles.small(
                                                  context,
                                                  color: AppColors.getTextMuted(
                                                    context,
                                                  ),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );

                                  try {
                                    final success = await ref
                                        .read(authNotifierProvider.notifier)
                                        .linkWithGoogle();

                                    if (context.mounted) {
                                      // 2. Dismiss loading dialog
                                      Navigator.pop(context);

                                      if (success) {
                                        AppToast.show(
                                          context,
                                          'Account linked successfully!',
                                        );
                                        Navigator.pop(context); // Close Drawer
                                      }
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    if (context.mounted) {
                                      // Dismiss loading dialog
                                      Navigator.pop(context);

                                      if (e.code ==
                                          'credential-already-in-use') {
                                        AppToast.show(
                                          context,
                                          'This Google account is already linked to another user.',
                                          isError: true,
                                        );
                                      } else {
                                        AppToast.show(
                                          context,
                                          e.message ??
                                              'Failed to link account.',
                                          isError: true,
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      // Dismiss loading dialog
                                      Navigator.pop(context);

                                      AppToast.show(
                                        context,
                                        'Failed to link account: $e',
                                        isError: true,
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.white,
                                  foregroundColor: AppColors.primary,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSizes.w12,
                                    vertical: AppSizes.h4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.r12,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.link, size: 12.sp),
                                    SizedBox(width: AppSizes.w4),
                                    Text(
                                      'Link',
                                      style: AppTextStyles.body(
                                        context,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: AppSizes.r24,
                        backgroundColor: AppColors.white.withOpacity(0.2),
                        backgroundImage: profile['photoUrl'] != null
                            ? NetworkImage(profile['photoUrl']!)
                            : null,
                        child: profile['photoUrl'] == null
                            ? Icon(
                                Icons.person_rounded,
                                size: AppSizes.h24,
                                color: AppColors.white,
                              )
                            : null,
                      ),
                      SizedBox(height: AppSizes.h8),
                      Text(
                        profile['name'] ?? 'User',
                        style: AppTextStyles.heading(
                          context,
                          color: AppColors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (profile['email'] != null) ...[
                        SizedBox(height: AppSizes.h2),
                        Text(
                          profile['email']!,
                          style: AppTextStyles.small(
                            context,
                            color: AppColors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  );
                }

                if (userProfileAsync.isLoading) {
                  return const SizedBox(
                    height: 48,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Error loading profile',
                        style: AppTextStyles.small(
                          context,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }(),
            ),

            // Menu Items - Matches Image List
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: AppSizes.h8),
                children: [
                  _buildSimpleTile(
                    context,
                    icon: Icons.edit_outlined,
                    title: 'Edit Profile',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/edit-profile');
                    },
                  ),
                  _buildSimpleTile(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                  // _buildSimpleTile(
                  //   context,
                  //   icon: Icons.bug_report_outlined,
                  //   title: 'Dev: Generate 1000 Transactions',
                  //   color: Colors.orange,
                  //   onTap: () async {
                  //     final userId = ref.read(authStateProvider).value?.id;
                  //     if (userId != null) {
                  //       Navigator.pop(context); // Close drawer
                  //       AppToast.show(
                  //         context,
                  //         'Generating 1000 test transactions... This may take a moment.',
                  //       );
                  //       try {
                  //         await TestDataService.generate1000Transactions(
                  //           userId,
                  //         );
                  //         if (context.mounted) {
                  //           AppToast.show(
                  //             context,
                  //             '1000 Test Transactions generated successfully! Please Force Logout and Login to test pagination.',
                  //           );
                  //         }
                  //       } catch (e) {
                  //         if (context.mounted) {
                  //           AppToast.show(
                  //             context,
                  //             'Error generating data: $e',
                  //             isError: true,
                  //           );
                  //         }
                  //       }
                  //     }
                  //   },
                  // ),
                  _buildSimpleTile(
                    context,
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Feedback',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/feedback');
                    },
                  ),
                  Divider(height: AppSizes.h32, thickness: AppSizes.tDivider),
                  _buildSimpleTile(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: 'About',
                    onTap: () => _navigateToDetail(
                      context,
                      'About',
                      AppStrings.aboutContent,
                    ),
                  ),
                  _buildSimpleTile(
                    context,
                    icon: Icons.verified_user_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _navigateToDetail(
                      context,
                      'Privacy Policy',
                      AppStrings.privacyPolicyContent,
                    ),
                  ),
                  _buildSimpleTile(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () => _navigateToDetail(
                      context,
                      'Terms & Conditions',
                      AppStrings.termsAndConditionsContent,
                    ),
                  ),
                  _buildSimpleTile(
                    context,
                    icon: Icons.share_rounded,
                    title: 'Share App',
                    onTap: () {
                      Navigator.pop(context);
                      _shareApp(context);
                    },
                  ),
                  Divider(height: AppSizes.h32, thickness: AppSizes.tDivider),
                  _buildSimpleTile(
                    context,
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    color: AppColors.error,
                    onTap: () => _showLogoutDialog(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: AppSizes.h24, color: color),
      title: Text(title, style: AppTextStyles.body(context, color: color)),
      trailing: trailing,
    );
  }

  void _navigateToDetail(BuildContext context, String title, String content) {
    context.push(
      '/settings-detail',
      extra: {'title': title, 'content': content},
    );
  }

  Future<void> _shareApp(BuildContext context) async {
    const String shareText =
        '${AppStrings.appName} is the ultimate personal finance app! 📈\n\n'
        'It automatically tracks your expenses from SMS, visualizes your spending with premium interactive charts. 📊✨\n\n'
        'Download it now from Google Play:\n'
        'https://play.google.com/store/apps/details?id=com.smart_money_tracker';

    AnalyticsService.logEvent('share_app');

    try {
      // Load the icon and add a white background
      final byteData = await rootBundle.load('assets/images/app_icon2.png');
      final codec = await ui.instantiateImageCodec(
        byteData.buffer.asUint8List(),
      );
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final bgPaint = Paint()..color = Colors.white;

      canvas.drawRect(
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        bgPaint,
      );
      canvas.drawImage(image, Offset.zero, Paint());

      final picture = recorder.endRecording();
      final img = await picture.toImage(image.width, image.height);
      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
      final finalBytes = pngBytes!.buffer.asUint8List();

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/finzo_icon.png');
      await file.writeAsBytes(finalBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: 'Manage your money smartly with ${AppStrings.appName}!',
      );
    } catch (e) {
      debugPrint('Error sharing app: $e');
      if (context.mounted) {
        AppToast.show(context, 'Failed to share app: $e', isError: true);
      }
    }
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: AppSizes.cardBorderRadius),
        child: Padding(
          padding: EdgeInsets.all(AppSizes.w24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(AppSizes.w16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.power_settings_new_rounded,
                  color: AppColors.error,
                  size: AppSizes.h32,
                ),
              ),
              SizedBox(height: AppSizes.h20),
              Text('Sign Out', style: AppTextStyles.heading(context)),
              SizedBox(height: AppSizes.h12),
              Text(
                'Are you sure you want to securely sign out of your account?',
                style: AppTextStyles.body(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSizes.h24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSizes.cardBorderRadius,
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Text('Cancel', style: AppTextStyles.body(context)),
                    ),
                  ),
                  SizedBox(width: AppSizes.w12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppSizes.cardBorderRadius,
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Sign Out',
                        style: AppTextStyles.body(
                          context,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldLogout == true) {
      AnalyticsService.logEvent('logout');
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}
