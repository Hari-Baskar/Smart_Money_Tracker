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
          horizontal: AppSizes.w12,
          vertical: AppSizes.h12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.r32),
          color: isError
              ? AppColors.error.withOpacity(0.9)
              : AppColors.primary.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message,
          style: AppTextStyles.body(context, color: AppColors.white),
          textAlign: TextAlign.center,
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
