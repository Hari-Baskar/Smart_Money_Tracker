import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/settings_detail_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/edit_profile_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/feedback_screen.dart';
import 'package:smart_money_tracker/core/constants/app_strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';

class AppDrawer extends HookConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // White status bar icons on dark green header
        statusBarBrightness: Brightness.dark,      // iOS status bar text style
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: AppColors.isDark(context) ? Brightness.light : Brightness.dark,
      ),
      child: Drawer(
        width: AppSizes.drawerWidth,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppSizes.r20),
            bottomRight: Radius.circular(AppSizes.r20),
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
                              backgroundImage: profile['photoUrl'] != null && profile['photoUrl']!.isNotEmpty
                                  ? NetworkImage(profile['photoUrl']!)
                                  : null,
                              child: profile['photoUrl'] == null || profile['photoUrl']!.isEmpty
                                  ? Icon(
                                      Icons.person_outline_rounded,
                                      size: AppSizes.h24,
                                      color: AppColors.white,
                                    )
                                  : null,
                            ),
                            SizedBox(width: AppSizes.w12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    profile['name'] != null && profile['name']!.isNotEmpty
                                        ? profile['name']!
                                        : 'Guest User',
                                    style: AppTextStyles.headline(
                                      context,
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'Data is saved locally',
                                    style: AppTextStyles.small(
                                      context,
                                      color: AppColors.white.withOpacity(0.9),
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ],
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
                                    fontSize: 9.sp,
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
                                        backgroundColor: Theme.of(context).colorScheme.surface,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppSizes.r20),
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
                                                style: AppTextStyles.headline(
                                                  context,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14.sp,
                                                ),
                                              ),
                                              SizedBox(height: AppSizes.h8),
                                              Text(
                                                'Securing and syncing your data safely...',
                                                style: AppTextStyles.small(
                                                  context,
                                                  color: AppColors.getTextMuted(context),
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
                                        AppToast.show(context, 'Account linked successfully!');
                                        Navigator.pop(context); // Close Drawer
                                      }
                                    }
                                  } on FirebaseAuthException catch (e) {
                                    if (context.mounted) {
                                      // Dismiss loading dialog
                                      Navigator.pop(context);
                                      
                                      if (e.code == 'credential-already-in-use') {
                                        AppToast.show(
                                          context,
                                          'This Google account is already linked to another user.',
                                          isError: true,
                                        );
                                      } else {
                                        AppToast.show(
                                          context,
                                          e.message ?? 'Failed to link account.',
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
                                    vertical: 4.h,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppSizes.r12),
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
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.bold,
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
                        style: AppTextStyles.headline(
                          context,
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (profile['email'] != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          profile['email']!,
                          style: AppTextStyles.small(
                            context,
                            color: AppColors.white.withOpacity(0.9),
                            fontSize: 10.sp,
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
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
                  _buildSimpleTile(
                    context,
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Feedback',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FeedbackScreen(),
                        ),
                      );
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
      title: Text(
        title,
        style: AppTextStyles.body(context, fontSize: 12.sp, color: color),
      ),
      trailing: trailing,
    );
  }

  void _navigateToDetail(BuildContext context, String title, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SettingsDetailScreen(title: title, content: content),
      ),
    );
  }

  Future<void> _shareApp(BuildContext context) async {
    const String shareText = '${AppStrings.appName} is the ultimate personal finance app! 📈\n\n'
        'It automatically tracks your expenses from SMS, manages your budgets, and visualizes your spending with premium interactive charts. 📊✨\n\n'
        'Download it now from Google Play:\n'
        'https://play.google.com/store/apps/details?id=com.smart_money_tracker';

    try {
      // 1. Load app icon from assets
      final ByteData bytes = await rootBundle.load(AppStrings.appIconPath);
      final Uint8List list = bytes.buffer.asUint8List();

      // 2. Get temp directory and write the file
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/app_icon.png');
      await file.writeAsBytes(list);

      // 3. Share the file along with the text natively
      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: 'Manage your money smartly with ${AppStrings.appName}!',
      );
    } catch (e) {
      // Fallback to sharing only text if file sharing fails or is not supported
      await Share.share(
        shareText,
        subject: 'Manage your money smartly with ${AppStrings.appName}!',
      );
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
              Text(
                'Sign Out',
                style: AppTextStyles.headline(
                  context,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: AppSizes.h12),
              Text(
                'Are you sure you want to securely sign out of your account?',
                style: AppTextStyles.body(context, fontSize: 11.sp),
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
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.body(
                          context,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                          fontWeight: FontWeight.w600,
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
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}
