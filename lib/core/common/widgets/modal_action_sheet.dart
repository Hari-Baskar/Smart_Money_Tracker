import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';

/// An Instagram-styled bottom sheet container with a drag handle and clean padding.
class ModalActionSheet extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const ModalActionSheet({super.key, required this.children, this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24)),
      ),
      padding:
          padding ??
          EdgeInsets.fromLTRB(
            AppSizes.w8,
            AppSizes.h12,
            AppSizes.w8,
            AppSizes.h16,
          ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: AppSizes.w(40),
                height: AppSizes.h4,
                margin: EdgeInsets.only(bottom: AppSizes.h12),
                decoration: BoxDecoration(
                  color: AppColors.getTextMuted(context).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSizes.r100),
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// A clean, full-width text action item with a left icon and optional destructive styling.
class ModalActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;
  final bool isDestructive;

  const ModalActionItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDestructive
        ? AppColors.error
        : (color ?? AppColors.getText(context));

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.r12),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.w16,
            vertical: AppSizes.h12,
          ),
          child: Row(
            children: [
              Icon(icon, size: AppSizes.r24, color: effectiveColor),
              SizedBox(width: AppSizes.w16),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body(context).copyWith(
                    color: effectiveColor,
                    fontWeight: FontWeight.w500,
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
