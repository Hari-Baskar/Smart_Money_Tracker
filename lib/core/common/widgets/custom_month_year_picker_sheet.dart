import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';
import 'package:intl/intl.dart';

class CustomMonthYearPickerSheet extends StatefulWidget {
  final DateTime? initialDate;
  final List<String> scannedMonths;

  const CustomMonthYearPickerSheet({
    super.key,
    this.initialDate,
    this.scannedMonths = const [],
  });

  @override
  State<CustomMonthYearPickerSheet> createState() =>
      _CustomMonthYearPickerSheetState();
}

class _CustomMonthYearPickerSheetState
    extends State<CustomMonthYearPickerSheet> {
  late int selectedMonth;
  late int selectedYear;

  final List<int> years = List.generate(
    4,
    (index) => DateTime.now().year - index,
  );

  final List<Map<String, dynamic>> months = List.generate(12, (index) {
    return {
      'value': index + 1,
      'label': DateFormat('MMMM').format(DateTime(2000, index + 1)),
    };
  });

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDate ?? DateTime.now();
    selectedMonth = initial.month;
    selectedYear = initial.year;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final availableMonths = selectedYear == now.year
        ? months.where((m) => (m['value'] as int) <= now.month).toList()
        : months;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSizes.w24,
            AppSizes.h12,
            AppSizes.w24,
            AppSizes.h24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: AppSizes.w(48),
                  height: AppSizes.h4,
                  margin: EdgeInsets.only(bottom: AppSizes.h20),
                  decoration: BoxDecoration(
                    color: AppColors.isDark(context)
                        ? AppColors.white.withOpacity(0.12)
                        : AppColors.black.withOpacity(0.08),
                    borderRadius: AppSizes.boxBorderRadius,
                  ),
                ),
              ),
              Text(
                'Scan Sms History',
                style: AppTextStyles.subHeading(
                  context,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: AppSizes.h4),
              Text(
                'Select a month and year to scan for past transactions.',
                style: AppTextStyles.body(
                  context,
                  color: AppColors.getTextMuted(context),
                ),
              ),
              SizedBox(height: AppSizes.h24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Month', style: AppTextStyles.body(context)),
                        SizedBox(height: AppSizes.h8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.w12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.getTextMuted(
                                context,
                              ).withValues(alpha: 0.5),
                            ),
                            borderRadius: AppSizes.cardBorderRadius,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedMonth,
                              isExpanded: true,
                              items: availableMonths.map((month) {
                                return DropdownMenuItem<int>(
                                  value: month['value'] as int,
                                  child: Text(month['label'] as String),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedMonth = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppSizes.w16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Year', style: AppTextStyles.body(context)),
                        SizedBox(height: AppSizes.h8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.w12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.getTextMuted(
                                context,
                              ).withValues(alpha: 0.5),
                            ),
                            borderRadius: AppSizes.cardBorderRadius,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedYear,
                              isExpanded: true,
                              items: years.map((year) {
                                return DropdownMenuItem<int>(
                                  value: year,
                                  child: Text(year.toString()),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedYear = value;
                                    if (selectedYear == DateTime.now().year &&
                                        selectedMonth > DateTime.now().month) {
                                      selectedMonth = DateTime.now().month;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.h32),
              Builder(
                builder: (context) {
                  final currentMonthKey =
                      '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}';
                  final isScanned = widget.scannedMonths.contains(
                    currentMonthKey,
                  );

                  final now = DateTime.now();
                  final isFuture =
                      selectedYear > now.year ||
                      (selectedYear == now.year && selectedMonth > now.month);

                  return Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          text: isScanned
                              ? 'Scan Again'
                              : isFuture
                              ? 'Future Month'
                              : 'Scan Now',
                          onPressed: isFuture
                              ? null
                              : () {
                                  Navigator.pop(
                                    context,
                                    DateTime(selectedYear, selectedMonth),
                                  );
                                },
                          isExpanded: true,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
