import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';

class ForceLogoutScreen extends StatelessWidget {
  final String activeDeviceName;

  const ForceLogoutScreen({super.key, required this.activeDeviceName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.w24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.warning_rounded,
                size: AppSizes.screenHeight * 0.1,
                color: Colors.orange,
              ),
              SizedBox(height: AppSizes.h32),
              Text(
                'Account in Use',
                style: AppTextStyles.heading(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSizes.h16),
              Text(
                'This account is already active on $activeDeviceName.\n\nDo you want to Force Logout from that device and login here?',
                style: AppTextStyles.body(context),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
                ),
                child: Text(
                  'Force Logout',
                  style: AppTextStyles.body(context, color: Colors.white),
                ),
              ),
              SizedBox(height: AppSizes.h16),
              TextButton(
                onPressed: () => context.pop(false),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.body(
                    context,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
