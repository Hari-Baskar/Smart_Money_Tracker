import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';

import 'package:smart_money_tracker/core/theme/app_text_styles.dart';

class AppToast {
  static final FToast _fToast = FToast();

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    _fToast.init(context);
    _fToast.removeCustomToast();
    _fToast.showToast(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.w16,
          vertical: AppSizes.h8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.r32),
          color: isError
              ? AppColors.error.withOpacity(0.9)
              : AppColors.primary.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: AppColors.white,
              size: AppSizes.r16,
            ),
            SizedBox(width: AppSizes.w8),
            Flexible(
              child: Text(
                message,
                style: AppTextStyles.small(
                  context,
                  color: AppColors.white,
                  fontSize: 12,
                ).copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      positionedToastBuilder: (context, child, gravity) {
        return Positioned(
          bottom: 100.h,
          left: 24.w,
          right: 24.w,
          child: Center(child: child),
        );
      },
      toastDuration: const Duration(seconds: 2),
    );
  }
}
