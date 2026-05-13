import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/constants/app_sizes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base(
    BuildContext context,
    double size, {
    FontWeight? weight,
    Color? color,
  }) {
    return GoogleFonts.poppins(
      fontSize: size.sp,
      fontWeight: weight ?? FontWeight.w400,
      color: color ?? Theme.of(context).colorScheme.onBackground,
    );
  }

  // Large Displays
  static TextStyle display(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
  }) => _base(
    context,
    AppSizes.sDisplay,
    weight: fontWeight ?? FontWeight.w700,
    color: color,
  );

  // Headings/Titles
  static TextStyle headline(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
  }) => _base(
    context,
    AppSizes.sHeadline,
    weight: fontWeight ?? FontWeight.w600,
    color: color,
  );

  // Standard Body Text
  static TextStyle body(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
  }) => _base(
    context,
    AppSizes.sBody,
    weight: fontWeight ?? FontWeight.w400,
    color: color,
  );

  // Small/Secondary Text
  static TextStyle small(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
  }) => _base(
    context,
    AppSizes.sSmall,
    weight: fontWeight ?? FontWeight.w400,
    color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
  );
}
