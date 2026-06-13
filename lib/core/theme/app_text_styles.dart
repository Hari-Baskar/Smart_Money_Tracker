import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base(
    BuildContext context,
    double size, {
    FontWeight? weight,
    Color? color,
  }) {
    // Tone down bold/semi-bold weights to w400 (regular) or w300 (light) to avoid "too much bold" in the app
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color ?? Theme.of(context).colorScheme.onBackground,
    );
  }

  // Heading (18)
  static TextStyle heading(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
  }) => _base(
    context,
    fontSize ?? 16.sp,
    weight: fontWeight ?? FontWeight.w700,
    color: color,
  );

  // Subheading (16)
  static TextStyle subHeading(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
  }) => _base(
    context,
    fontSize ?? 14.sp,
    weight: fontWeight ?? FontWeight.w500,
    color: color,
  );

  // Body (14)
  static TextStyle body(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
  }) => _base(
    context,
    fontSize ?? 12.sp,
    weight: fontWeight ?? FontWeight.w500,
    color: color,
  );

  // Small (12)
  static TextStyle small(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
  }) => _base(
    context,
    fontSize ?? 10.sp,
    weight: fontWeight ?? FontWeight.w300,
    color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
  );

  // Legacy wrappers mapped strictly to the new 4 sizes and light weights
}
