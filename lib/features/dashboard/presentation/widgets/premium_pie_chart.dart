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
          showTitle: false,
          radius: 35, // width of the donut ring
          titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
        ),
      );
      i++;
    }

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
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
                        centerSpaceRadius: 55, // Hole size
                        sections: sections,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$currencySymbol${AppColors.formatShortAmount(totalAmount)}',
                          style:
                              AppTextStyles.body(
                                context,
                                fontWeight: FontWeight.bold,
                              ).copyWith(
                                color: isExpense
                                    ? AppColors.error
                                    : AppColors.success,
                                fontSize: 18,
                              ),
                        ),
                        Text(
                          'Total',
                          style: AppTextStyles.body(
                            context,
                            color: isDark
                                ? Colors.grey[400]
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: AppSizes.h8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isExpense ? 'Total Expenses: ' : 'Total Income: ',
                style: AppTextStyles.body(context, fontWeight: FontWeight.bold),
              ),
              Text(
                '$currencySymbol${AppColors.formatShortAmount(totalAmount)}',
                style: AppTextStyles.body(
                  context,
                  fontWeight: FontWeight.bold,
                  color: isExpense ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.h16),
          Wrap(
            spacing: AppSizes.w12,
            runSpacing: AppSizes.h12,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...List.generate(sortedEntries.length, (index) {
                final entry = sortedEntries[index];
                final color = palette[index % palette.length];
                final percentage = totalAmount > 0
                    ? (entry.value / totalAmount) * 100
                    : 0;
                return Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? color.withOpacity(0.15)
                        : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? color.withOpacity(0.3)
                          : color.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            AppColors.getCategoryIcon(entry.key),
                            size: 16,
                            color: color,
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: AppTextStyles.small(context).copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.key,
                        style: AppTextStyles.small(context).copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$currencySymbol${AppColors.formatShortAmount(entry.value)}',
                        style: AppTextStyles.small(context).copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
