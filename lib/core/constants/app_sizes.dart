import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSizes {
  AppSizes._();

  // Dynamic Widths
  static double w(double value) => value.w;
  static double get w4 => 4.0.w;
  static double get w8 => 8.0.w;
  static double get w12 => 12.0.w;
  static double get w16 => 16.0.w;
  static double get w20 => 20.0.w;
  static double get w24 => 24.0.w;
  static double get w32 => 32.0.w;

  // Dynamic Heights
  static double h(double value) => value.h;
  static double get h2 => 2.0.h;
  static double get h4 => 4.0.h;
  static double get h8 => 8.0.h;
  static double get h12 => 12.0.h;
  static double get h16 => 16.0.h;
  static double get h20 => 20.0.h;
  static double get h24 => 24.0.h;
  static double get h32 => 32.0.h;
  static double get h40 => 40.0.h;
  static double get h45 => 45.0.h;
  static double get h48 => 48.0.h;
  static double get h64 => 64.0.h;

  // Dynamic Radius
  static double r(double value) => value.r;
  static double get r4 => 4.0.r;
  static double get r8 => 8.0.r;
  static double get r12 => 12.0.r;
  static double get r16 => 16.0.r;
  static double get r20 => 20.0.r;
  static double get r24 => 24.0.r;
  static double get r32 => 32.0.r;
  static double get r40 => 40.0.r;
  static double get r100 => 100.0.r;

  // Global Card & Box Styling
  static double get cardRadius => r8;
  static BorderRadius get cardBorderRadius => BorderRadius.circular(cardRadius);

  static double get boxRadius =>
      r8; // Centralized box radius token (uses r8/8.0.r by default)
  static BorderRadius get boxBorderRadius => BorderRadius.circular(boxRadius);

  // Font Sizes (Raw values)

  // Screen Dimensions
  static double get screenWidth => 1.sw;
  static double get screenHeight => 1.sh;
  static double get drawerWidth => 1.sw * 0.75;

  // Thickness
  static const double tDivider = 0.5;
  static const double tBorder = 4.0;
}
