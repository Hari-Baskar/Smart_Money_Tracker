import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/theme/app_text_styles.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/features/dashboard/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:expense_tracker/features/dashboard/presentation/screens/settings_detail_screen.dart';
import 'package:expense_tracker/features/dashboard/presentation/screens/selection_setting_screen.dart';

class ProfileScreen extends HookConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameAsync = ref.watch(userNameProvider);
    final authState = ref.watch(authStateProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'My Profile',
          style: AppTextStyles.headline(
            context,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),
              // Core-consistent Profile Header
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30.r,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.person_rounded,
                        size: 30.r,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          nameAsync.when(
                            data: (name) => Text(
                              name ?? 'User',
                              style: AppTextStyles.headline(
                                context,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            loading: () => const SizedBox(
                              height: 10,
                              width: 100,
                              child: LinearProgressIndicator(),
                            ),
                            error: (_, __) => const Text('User'),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            authState.value?.phoneNumber ?? 'No number linked',
                            style: AppTextStyles.small(
                              context,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Fluttertoast.showToast(msg: 'Coming soon');
                      },
                      icon: Icon(
                        Icons.edit_note_rounded,
                        color: AppColors.primary,
                        size: 24.r,
                      ),
                    ),
                  ],
                ),
              ),

                  SizedBox(height: 32.h),

                  // Settings Sections
                  _buildSectionHeader(context, 'Account Settings'),
                  _buildSettingsGroup(context, [
                    _buildSettingTile(
                      context,
                      icon: Icons.notifications_active_outlined,
                      title: 'Notifications',
                      subtitle: settings.notificationsEnabled ? 'On' : 'Off',
                      onTap: () => ref
                          .read(settingsProvider.notifier)
                          .toggleNotifications(!settings.notificationsEnabled),
                      trailing: Switch.adaptive(
                        value: settings.notificationsEnabled,
                        onChanged: (val) => ref
                            .read(settingsProvider.notifier)
                            .toggleNotifications(val),
                        activeColor: AppColors.primary,
                      ),
                    ),
                    _buildSettingTile(
                      context,
                      icon: Icons.lock_outline_rounded,
                      title: 'Privacy & Security',
                      subtitle: 'Manage your data and security',
                      onTap: () => _navigateToDetail(
                        context,
                        'Privacy & Security',
                        'Your financial security is our top priority. Smart Expense Tracker uses industry-standard AES-256 encryption for all data storage. We process SMS and notification data locally on your device for transaction extraction, ensuring your sensitive messages never leave your phone. We are fully committed to privacy and data protection.',
                      ),
                    ),
                  ]),

                  SizedBox(height: 24.h),

                  _buildSectionHeader(context, 'General Preferences'),
                  _buildSettingsGroup(context, [
                    _buildSettingTile(
                      context,
                      icon: Icons.palette_outlined,
                      title: 'Appearance',
                      subtitle: settings.themeMode.toUpperCase(),
                      onTap: () => _navigateToAppearance(
                        context,
                        ref,
                        settings.themeMode,
                      ),
                    ),
                    _buildSettingTile(
                      context,
                      icon: Icons.language_rounded,
                      title: 'Language',
                      subtitle: settings.language,
                      onTap: () =>
                          _navigateToLanguage(context, ref, settings.language),
                    ),
                  ]),

                  SizedBox(height: 24.h),

                  _buildSectionHeader(context, 'Support & More'),
                  _buildSettingsGroup(context, [
                    _buildSettingTile(
                      context,
                      icon: Icons.help_center_outlined,
                      title: 'Help Center',
                      subtitle: 'FAQs, contact support',
                      onTap: () => _navigateToDetail(
                        context,
                        'Help Center',
                        'Welcome to the Help Center. Here you can find guides on setting up automatic tracking, managing categories, and understanding your spending insights. If you need further assistance, our dedicated support team is available at support@smarttracker.ai. Response times are typically within 24 hours.',
                      ),
                    ),
                    _buildSettingTile(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: 'Legal Information',
                      subtitle: 'Terms, Privacy Policy',
                      onTap: () => _navigateToDetail(
                        context,
                        'Legal Information',
                        'By using Smart Expense Tracker, you agree to our Terms of Service and Privacy Policy. All rights reserved. You maintain full ownership of your financial records. We only collect anonymized usage data to improve our AI extraction models and overall app performance.',
                      ),
                    ),
                    _buildSettingTile(
                      context,
                      icon: Icons.alternate_email_rounded,
                      title: 'About',
                      subtitle: 'App version, company info',
                      onTap: () => _navigateToDetail(
                        context,
                        'About',
                        'Smart Expense Tracker v1.0.0\n\nA privacy-first, automated expense tracking app powered by advanced AI. Developed by a team of enthusiasts dedicated to making personal finance management effortless. Thank you for choosing us to be part of your financial journey.',
                      ),
                    ),
                  ]),

                  SizedBox(height: 40.h),

                  // Refined Logout Action
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _showLogoutDialog(context, ref),
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                      ),
                      label: Text(
                        'Sign Out',
                        style: AppTextStyles.body(
                          context,
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32.w,
                          vertical: 16.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        backgroundColor: AppColors.error.withOpacity(0.05),
                      ),
                    ),
                  ),

                  SizedBox(height: 48.h),

                  Center(
                    child: Text(
                      'Version 1.0.0',
                      style: AppTextStyles.small(
                        context,
                        color: AppColors.textMuted.withOpacity(0.5),
                      ),
                    ),
                  ),

                  SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.small(
          context,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final idx = entry.key;
          final widget = entry.value;
          final isLast = idx == children.length - 1;

          if (isLast) return widget;
          return Column(
            children: [
              widget,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Divider(
                    height: 1, color: Theme.of(context).colorScheme.surfaceVariant),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22.r),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body(
                      context,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.small(
                      context,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20.r,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                ),
          ],
        ),
      ),
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

  void _navigateToLanguage(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectionSettingScreen(
          title: 'Language',
          currentValue: current,
          options: [
            SelectionOption(
              label: 'English (US)',
              value: 'English (US)',
              icon: Icons.language_rounded,
            ),
            SelectionOption(
              label: 'Hindi',
              value: 'Hindi',
              icon: Icons.translate_rounded,
            ),
            SelectionOption(
              label: 'Spanish',
              value: 'Spanish',
              icon: Icons.g_translate_rounded,
            ),
          ],
          onSelected: (val) =>
              ref.read(settingsProvider.notifier).setLanguage(val),
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Sign Out', style: AppTextStyles.headline(context)),
        content: Text(
          'Are you sure you want to securely sign out of your account?',
          style: AppTextStyles.body(context,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Stay', style: AppTextStyles.body(context, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              'Sign Out',
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

    if (shouldLogout == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
    }
  }
}
