import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';

class PremiumPieChart extends StatelessWidget {
  final Map<String, double> categoryAmounts;
  final String currencySymbol;
  final double totalAmount;
  final bool isExpense;

  const PremiumPieChart({
    super.key,
    required this.categoryAmounts,
    this.currencySymbol = '₹',
    required this.totalAmount,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sortedEntries = categoryAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    const palette = [
      Color(0xFF64B5F6), // Soft Blue
      Color(0xFF81C784), // Soft Green
      Color(0xFFFFB74D), // Soft Orange
      Color(0xFFBA68C8), // Soft Purple
      Color(0xFFE57373), // Soft Red
      Color(0xFF4DB6AC), // Soft Teal
      Color(0xFF7986CB), // Soft Indigo
      Color(0xFFFFD54F), // Soft Yellow
      Color(0xFFA1887F), // Soft Brown
      Color(0xFF90A4AE), // Soft BlueGrey
    ];

    List<PieChartSectionData> sections = [];
    int i = 0;
    for (var entry in sortedEntries) {
      final percentage = totalAmount > 0
          ? (entry.value / totalAmount) * 100
          : 0;
      final color = palette[i % palette.length];
      sections.add(
        PieChartSectionData(
          color: color,
          value: entry.value,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 35, // width of the donut ring
          titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
        ),
      );
      i++;
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.h16),
      padding: EdgeInsets.all(AppSizes.w16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : Colors.white,
        borderRadius: AppSizes.cardBorderRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isExpense ? 'Total Expenses' : 'Total Income',
                style: AppTextStyles.body(context, fontWeight: FontWeight.bold),
              ),
              Text(
                '$currencySymbol${AppColors.formatShortAmount(totalAmount)}',
                style: AppTextStyles.subHeading(
                  context,
                  color: isExpense ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.h24),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(enabled: false),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2, // Space between sections
                          centerSpaceRadius: 40, // Hole size
                          sections: sections,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$currencySymbol${AppColors.formatShortAmount(totalAmount)}',
                            style: AppTextStyles.body(context, fontWeight: FontWeight.bold).copyWith(color: isDark ? Colors.white : Colors.black87),
                          ),
                          Text(
                            'Total',
                            style: AppTextStyles.small(context, color: isDark ? Colors.grey[400] : AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: AppSizes.w16),
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(sortedEntries.length, (index) {
                    final entry = sortedEntries[index];
                    final color = palette[index % palette.length];
                    final percentage = totalAmount > 0
                        ? (entry.value / totalAmount) * 100
                        : 0;
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppSizes.h8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: AppTextStyles.small(context).copyWith(fontSize: 12, color: isDark ? Colors.white : null),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$currencySymbol${entry.value.toStringAsFixed(0)}',
                            style: AppTextStyles.small(context, color: isDark ? Colors.grey[300] : AppColors.textMuted).copyWith(fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 30,
                            child: Text(
                              '${percentage.toStringAsFixed(0)}%',
                              style: AppTextStyles.small(context, color: isDark ? Colors.grey[300] : AppColors.textMuted).copyWith(fontSize: 11),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
