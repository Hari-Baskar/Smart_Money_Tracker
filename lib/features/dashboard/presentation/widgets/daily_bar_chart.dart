import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';

class DailyBarChartWidget extends StatefulWidget {
  final Map<DateTime, double> dailyIncomeAmounts;
  final Map<DateTime, double> dailyExpenseAmounts;
  final ValueNotifier<String> analysisType;
  final String dateRangeStr;
  final String currencySymbol;

  const DailyBarChartWidget({
    super.key,
    required this.dailyIncomeAmounts,
    required this.dailyExpenseAmounts,
    required this.analysisType,
    required this.dateRangeStr,
    this.currencySymbol = '₹',
  });

  @override
  State<DailyBarChartWidget> createState() => _DailyBarChartWidgetState();
}

class _DailyBarChartWidgetState extends State<DailyBarChartWidget> {
  int touchedIndex = -1;
  late List<DateTime> sortedDates;
  late double maxAmount;
  late double minAmount;

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  @override
  void didUpdateWidget(covariant DailyBarChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dailyIncomeAmounts != widget.dailyIncomeAmounts ||
        oldWidget.dailyExpenseAmounts != widget.dailyExpenseAmounts ||
        oldWidget.analysisType.value != widget.analysisType.value) {
      _prepareData();
    }
  }

  void _prepareData() {
    final allDates = <DateTime>{
      ...widget.dailyIncomeAmounts.keys,
      ...widget.dailyExpenseAmounts.keys,
    };
    sortedDates = allDates.toList()..sort();

    final isExpense = widget.analysisType.value == 'Expenses';

    maxAmount = 0.0;
    minAmount = double.infinity;
    for (final date in sortedDates) {
      final amount = isExpense 
          ? (widget.dailyExpenseAmounts[date] ?? 0.0)
          : (widget.dailyIncomeAmounts[date] ?? 0.0);
          
      if (amount > maxAmount) maxAmount = amount;
      if (amount < minAmount) minAmount = amount;
    }
    if (minAmount == double.infinity) minAmount = 0;
    if (maxAmount == 0) maxAmount = 100; // prevent divide by zero
  }

  @override
  Widget build(BuildContext context) {
    if (sortedDates.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpense = widget.analysisType.value == 'Expenses';

    // Calculate width to allow horizontal scrolling
    final minWidth = MediaQuery.of(context).size.width - AppSizes.w16 * 2;
    // Calculate required width based on fixed spacing
    final itemWidth = AppSizes.w(48);
    final calculatedWidth = sortedDates.length * itemWidth;
    final chartWidth = calculatedWidth > minWidth ? calculatedWidth : minWidth;

    final chartColor = isExpense ? AppColors.error : AppColors.primary;
    final chartColorSecondary = isExpense ? AppColors.red : AppColors.primaryContainer;

    final lineBarData = LineChartBarData(
      spots: List.generate(sortedDates.length, (i) {
        final amount = isExpense
            ? (widget.dailyExpenseAmounts[sortedDates[i]] ?? 0.0)
            : (widget.dailyIncomeAmounts[sortedDates[i]] ?? 0.0);
        return FlSpot(i.toDouble(), amount);
      }),
      isCurved: true,
      preventCurveOverShooting: true,
      gradient: LinearGradient(
        colors: [
          chartColor,
          chartColorSecondary,
        ],
      ),
      barWidth: 4,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [
            chartColor.withOpacity(0.3),
            chartColorSecondary.withOpacity(0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      showingIndicators: touchedIndex >= 0 && touchedIndex < sortedDates.length ? [touchedIndex] : [],
    );

    return Container(
      padding: EdgeInsets.all(AppSizes.w16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: AppSizes.boxBorderRadius,
        border: Border.all(
          color: isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                value: widget.analysisType.value,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.getText(context),
                ),
                underline: const SizedBox(),
                dropdownColor: AppColors.getSurface(context),
                style: AppTextStyles.subHeading(context),
                items: ['Debit', 'Credit'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    widget.analysisType.value = newValue;
                    setState(() {
                      touchedIndex = -1;
                      _prepareData();
                    });
                  }
                },
              ),
              if (touchedIndex >= 0 && touchedIndex < sortedDates.length)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isExpense)
                      Text(
                        'Inc: ${widget.currencySymbol}${(widget.dailyIncomeAmounts[sortedDates[touchedIndex]] ?? 0.0).toStringAsFixed(0)}',
                        style: AppTextStyles.body(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                          fontSize: 12,
                        ),
                      ),
                    if (isExpense)
                      Text(
                        'Exp: ${widget.currencySymbol}${(widget.dailyExpenseAmounts[sortedDates[touchedIndex]] ?? 0.0).toStringAsFixed(0)}',
                        style: AppTextStyles.body(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: AppSizes.h4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.dateRangeStr,
                  style: AppTextStyles.small(
                    context,
                  ).copyWith(color: AppColors.getTextMuted(context)),
                ),
                if (touchedIndex >= 0 && touchedIndex < sortedDates.length)
                  Text(
                    DateFormat(
                      'MMM dd, yyyy',
                    ).format(sortedDates[touchedIndex]),
                    style: AppTextStyles.small(
                      context,
                    ).copyWith(color: AppColors.getTextMuted(context)),
                  ),
              ],
            ),
          ),
          SizedBox(height: AppSizes.h24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: chartWidth,
              height: AppSizes.h(200),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value < 0 ||
                              value >= sortedDates.length ||
                              value != value.toInt()) {
                            return const SizedBox.shrink();
                          }
                          final date = sortedDates[value.toInt()];
                          // Check if it's showing multiple weeks
                          final String text = sortedDates.length <= 7
                              ? DateFormat('E')
                                    .format(date)
                                    .substring(0, 1) // M, T, W
                              : DateFormat('dd').format(date); // 01, 02
                          return Padding(
                            padding: EdgeInsets.only(top: AppSizes.h8),
                            child: Text(
                              text,
                              style: AppTextStyles.small(context).copyWith(
                                color: touchedIndex == value.toInt()
                                    ? (isDark ? Colors.white : Colors.black)
                                    : AppColors.getTextMuted(context),
                                fontWeight: touchedIndex == value.toInt()
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                        reservedSize: AppSizes.h(28),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: AppSizes.w(44),
                        getTitlesWidget: (value, meta) {
                          if (value == meta.min || value == meta.max) {
                            return const SizedBox.shrink(); // Hide exact edges if they overflow
                          }
                          return Padding(
                            padding: EdgeInsets.only(right: AppSizes.w8),
                            child: Text(
                              AppColors.formatShortAmount(value),
                              style: AppTextStyles.small(context).copyWith(
                                color: AppColors.getTextMuted(context),
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.getTextMuted(context).withOpacity(0.2),
                        width: 1,
                      ),
                      left: BorderSide(
                        color: AppColors.getTextMuted(context).withOpacity(0.2),
                        width: 1,
                      ),
                      right: BorderSide.none,
                      top: BorderSide(
                        color: AppColors.getTextMuted(context).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  minX: 0,
                  maxX: sortedDates.isNotEmpty
                      ? (sortedDates.length.toDouble() - 1)
                      : 0,
                  minY: minAmount > 0 ? (minAmount * 0.8) : 0,
                  maxY: maxAmount * 1.2,
                  showingTooltipIndicators: touchedIndex >= 0 && touchedIndex < sortedDates.length
                      ? [
                          ShowingTooltipIndicators([
                            LineBarSpot(
                              lineBarData,
                              0,
                              lineBarData.spots[touchedIndex],
                            )
                          ])
                        ]
                      : [],
                  lineBarsData: [lineBarData],
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: false,
                    getTouchedSpotIndicator:
                        (LineChartBarData barData, List<int> spotIndexes) {
                          return spotIndexes.map((spotIndex) {
                            return TouchedSpotIndicatorData(
                              FlLine(
                                color: chartColor,
                                strokeWidth: 2,
                                dashArray: const [4, 4],
                              ),
                              FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 6,
                                    color: chartColor,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                            );
                          }).toList();
                        },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => chartColor,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,

                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          return LineTooltipItem(
                            barSpot.y.toStringAsFixed(1),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    touchCallback:
                        (FlTouchEvent event, LineTouchResponse? lineTouch) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                lineTouch == null ||
                                lineTouch.lineBarSpots == null ||
                                lineTouch.lineBarSpots!.isEmpty) {
                              return;
                            }
                            touchedIndex = lineTouch.lineBarSpots![0].spotIndex;
                          });
                        },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
