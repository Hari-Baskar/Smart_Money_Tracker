import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/settings_detail_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/selection_setting_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/edit_profile_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/feedback_screen.dart';

class AppDrawer extends HookConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final settings = ref.watch(settingsProvider);

    return Drawer(
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
          // Header - Matches Image (Solid Color, Centered)
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              AppSizes.w16,
              AppSizes.h48,
              AppSizes.w16,
              AppSizes.h32,
            ),
            color: AppColors.primary,
            child: userProfileAsync.when(
              data: (profile) {
                final isAnonymous = profile['isAnonymous'] == 'true';
                if (isAnonymous) {
                  return Column(
                    children: [
                      Text(
                        'Guest User',
                        style: AppTextStyles.largeTitle(
                          context,
                          color: AppColors.white,
                        ),
                      ),
                      SizedBox(height: AppSizes.h16),
                      Container(
                        padding: EdgeInsets.all(AppSizes.h12),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.15),
                          borderRadius: AppSizes.cardBorderRadius,
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Save your data permanently by linking an account.',
                              style: AppTextStyles.small(
                                context,
                                color: AppColors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: AppSizes.h12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  await ref
                                      .read(authNotifierProvider.notifier)
                                      .linkWithGoogle();
                                },
                                icon: Icon(Icons.link, size: 16.r),
                                label: Text(
                                  'Link Google Account',
                                  style: AppTextStyles.body(
                                    context,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.white,
                                  foregroundColor: AppColors.primary,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppSizes.cardBorderRadius,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    CircleAvatar(
                      radius: AppSizes.r40,
                      backgroundColor: AppColors.white.withOpacity(0.2),
                      backgroundImage: profile['photoUrl'] != null
                          ? NetworkImage(profile['photoUrl']!)
                          : null,
                      child: profile['photoUrl'] == null
                          ? Icon(
                              Icons.person_rounded,
                              size: AppSizes.h45,
                              color: AppColors.white,
                            )
                          : null,
                    ),
                    SizedBox(height: AppSizes.h16),
                    Text(
                      profile['name'] ?? 'User',
                      style: AppTextStyles.headline(
                        context,
                        color: AppColors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (profile['email'] != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        profile['email']!,
                        style: AppTextStyles.small(
                          context,
                          color: AppColors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.white),
              ),
              error: (_, __) => Column(
                children: [
                  Icon(Icons.error_outline, color: AppColors.white, size: 40.r),
                  SizedBox(height: 16.h),
                  Text(
                    'Error loading profile',
                    style: AppTextStyles.body(context, color: AppColors.white),
                  ),
                ],
              ),
            ),
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
                ListTile(
                  leading: Icon(
                    settings.themeMode == 'dark'
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    size: AppSizes.h24,
                  ),
                  title: Text(
                    'Dark Mode',
                    style: AppTextStyles.body(context, fontSize: 11.sp),
                  ),
                  trailing: Switch(
                    value:
                        settings.themeMode == 'dark' ||
                        (settings.themeMode == 'system' &&
                            Theme.of(context).brightness == Brightness.dark),
                    onChanged: (bool value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setThemeMode(value ? 'dark' : 'light');
                    },
                    activeColor: AppColors.primary,
                  ),
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
                    'Expense Tracker v1.0.0',
                  ),
                ),
                _buildSimpleTile(
                  context,
                  icon: Icons.verified_user_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _navigateToDetail(
                    context,
                    'Privacy Policy',
                    'Your data is safe.',
                  ),
                ),
                _buildSimpleTile(
                  context,
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  onTap: () => _navigateToDetail(
                    context,
                    'Terms',
                    'Terms and conditions.',
                  ),
                ),
                Divider(height: AppSizes.h32, thickness: AppSizes.tDivider),
                _buildSimpleTile(
                  context,
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  color: AppColors.error,
                  onTap: () => _showLogoutDialog(context, ref),
                ),
                _buildSimpleTile(
                  context,
                  icon: Icons.delete_outlined,
                  title: 'Delete Account',
                  color: AppColors.error,
                  onTap: () => _showDeleteAccountDialog(context, ref),
                ),
              ],
            ),
          ),
        ],
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

  void _navigateToAppearance(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectionSettingScreen(
          title: 'Appearance',
          currentValue: current,
          options: [
            SelectionOption(
              label: 'Light Mode',
              value: 'light',
              icon: Icons.light_mode_outlined,
            ),
            SelectionOption(
              label: 'Dark Mode',
              value: 'dark',
              icon: Icons.dark_mode_outlined,
            ),
            SelectionOption(
              label: 'System Default',
              value: 'system',
              icon: Icons.settings_suggest_outlined,
            ),
          ],
          onSelected: (val) =>
              ref.read(settingsProvider.notifier).setThemeMode(val),
        ),
      ),
    );
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

  Future<void> _showDeleteAccountDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Delete Account?',
          style: AppTextStyles.headline(
            context,
            color: AppColors.error,
            fontSize: 14.sp,
          ),
        ),
        content: Text(
          'This action is permanent and will delete all your transactions and profile data. You cannot undo this.',
          style: AppTextStyles.body(context, fontSize: 11.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.body(context)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              'Delete Forever',
              style: AppTextStyles.body(
                context,
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(authNotifierProvider.notifier).deleteAccount();
        if (context.mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete account: $e')),
          );
        }
      }
    }
  }
}
