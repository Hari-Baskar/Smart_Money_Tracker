import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/settings_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/selection_setting_screen.dart';

class SettingsScreen extends HookConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onBackground,
            size: AppSizes.r20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: AppTextStyles.headline(context, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.w16,
          vertical: AppSizes.h12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Padding(
              padding: EdgeInsets.only(left: AppSizes.w4, bottom: AppSizes.h8),
              child: Text(
                'Preferences',
                style: AppTextStyles.small(
                  context,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            // Appearance Preference Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.getSurfaceContainerLowest(context),
                borderRadius: AppSizes.cardBorderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      AppColors.isDark(context) ? 0.15 : 0.03,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                onTap: () =>
                    _navigateToAppearance(context, ref, settings.themeMode),
                leading: Icon(
                  settings.themeMode == 'dark'
                      ? Icons.dark_mode_rounded
                      : settings.themeMode == 'light'
                      ? Icons.light_mode_rounded
                      : Icons.settings_suggest_rounded,
                  color: AppColors.primary,
                  size: AppSizes.h24,
                ),
                title: Text(
                  'Appearance',
                  style: AppTextStyles.body(
                    context,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  _getThemeLabel(settings.themeMode),
                  style: AppTextStyles.small(context),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: AppSizes.h24,
                ),
              ),
            ),

            SizedBox(height: AppSizes.h12),

            // Permissions Preference Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.getSurfaceContainerLowest(context),
                borderRadius: AppSizes.cardBorderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      AppColors.isDark(context) ? 0.15 : 0.03,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                onTap: () => context.push('/permissions'),
                leading: Icon(
                  Icons.security_rounded,
                  color: AppColors.primary,
                  size: AppSizes.h24,
                ),
                title: Text(
                  'App Permissions',
                  style: AppTextStyles.body(
                    context,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Manage biometric & notification access',
                  style: AppTextStyles.small(context),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: AppSizes.h24,
                ),
              ),
            ),

            SizedBox(height: AppSizes.h24),

            // Danger Zone Title
            Padding(
              padding: EdgeInsets.only(left: AppSizes.w4, bottom: AppSizes.h8),
              child: Text(
                'Danger Zone',
                style: AppTextStyles.small(
                  context,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ),

            // Danger Zone Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.getSurfaceContainerLowest(context),
                borderRadius: AppSizes.cardBorderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      AppColors.isDark(context) ? 0.15 : 0.03,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                onTap: () => _showDeleteAccountDialog(context, ref),
                leading: Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.error,
                  size: AppSizes.h24,
                ),
                title: Text(
                  'Delete Account',
                  style: AppTextStyles.body(
                    context,
                    fontWeight: FontWeight.w500,
                    color: AppColors.error,
                  ),
                ),
                subtitle: Text(
                  'Permanently delete your profile and transaction history',
                  style: AppTextStyles.small(
                    context,
                    color: AppColors.error.withOpacity(0.7),
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.error.withOpacity(0.5),
                  size: AppSizes.h24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeLabel(String value) {
    switch (value) {
      case 'light':
        return 'Light Mode';
      case 'dark':
        return 'Dark Mode';
      default:
        return 'System Default';
    }
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

  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppSizes.cardBorderRadius,
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSizes.w24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: AppSizes.h20),
                Text(
                  message,
                  style: AppTextStyles.body(
                    context,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
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
                  Icons.delete_forever_rounded,
                  color: AppColors.error,
                  size: AppSizes.h32,
                ),
              ),
              SizedBox(height: AppSizes.h20),
              Text(
                'Delete Account',
                style: AppTextStyles.headline(
                  context,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: AppSizes.h12),
              Text(
                'This action is permanent and will delete all your transactions and profile data. You cannot undo this.',
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
                        'Delete Forever',
                        style: AppTextStyles.body(
                          context,
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.sp,
                        ),
                        textAlign: TextAlign.center,
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

    if (confirmed == true) {
      if (context.mounted) {
        _showLoadingDialog(context, 'Deleting account and data...');
      }
      try {
        await ref.read(authNotifierProvider.notifier).deleteAccount();
        if (context.mounted) {
          Navigator.pop(context); // Pop the loading dialog
          context.go('/login');
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // Pop the loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete account: $e')),
          );
        }
      }
    }
  }
}
