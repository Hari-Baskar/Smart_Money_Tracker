import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';

/// A simple vertical bar chart that visualises the same data used by
/// [PremiumPieChart]. The chart shows a bar for each category with a label
/// and the amount. Colours are generated dynamically using a hue rotation so
/// that an arbitrary number of categories are supported.
class PremiumBarChart extends StatefulWidget {
  final Map<String, double> categoryAmounts;
  final String currencySymbol;

  const PremiumBarChart({
    super.key,
    required this.categoryAmounts,
    this.currencySymbol = '₹',
  });

  @override
  State<PremiumBarChart> createState() => _PremiumBarChartState();
}

class _BarSectionData {
  final String category;
  double amount;
  double percentage;
  Color color;

  _BarSectionData({
    required this.category,
    required this.amount,
    this.percentage = 0,
    required this.color,
  });
}

class _PremiumBarChartState extends State<PremiumBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_BarSectionData> _prepareSections(bool isDark) {
    final total = widget.categoryAmounts.values.fold<double>(
      0,
      (a, b) => a + b,
    );
    final colors = List<Color>.generate(
      widget.categoryAmounts.length,
      (i) => HSVColor.fromAHSV(
        1.0,
        (i * 360 / widget.categoryAmounts.length) % 360,
        0.7,
        0.9,
      ).toColor(),
    );
    int idx = 0;
    final sections = widget.categoryAmounts.entries.map((e) {
      final data = _BarSectionData(
        category: e.key,
        amount: e.value,
        percentage: total > 0 ? e.value / total : 0,
        color: colors[idx++],
      );
      return data;
    }).toList();
    if (!isDark) {
      // Optional: brighten colours for light theme
    }
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sections = _prepareSections(isDark);
    final maxBarHeight = 180.0; // visual max height for a 100% bar
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141614) : AppColors.white,
            borderRadius: AppSizes.boxBorderRadius,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.black.withOpacity(0.3)
                    : AppColors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bars
              ...sections.map((s) {
                final barHeight =
                    maxBarHeight * s.percentage * _animation.value;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.h(8)),
                  child: Row(
                    children: [
                      // Category label & amount
                      SizedBox(
                        width: 80.w,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.category,
                              style: AppTextStyles.body(context).copyWith(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            SizedBox(height: AppSizes.h(2)),
                            Text(
                              '${s.amount.toStringAsFixed(0)}${widget.currencySymbol}',
                              style: AppTextStyles.small(context).copyWith(
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: AppSizes.w4),
                      // Bar
                      Expanded(
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              height: 30.h,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.r4,
                                ),
                              ),
                            ),
                            Container(
                              width: barHeight,
                              height: 30.h,
                              decoration: BoxDecoration(
                                color: s.color,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.r4,
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: EdgeInsets.only(right: AppSizes.w4),
                                  child: Text(
                                    '${(s.percentage * 100).toStringAsFixed(0)}%',
                                    style: AppTextStyles.small(context),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
