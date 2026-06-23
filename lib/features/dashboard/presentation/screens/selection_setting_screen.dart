import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class SelectionSettingScreen extends HookConsumerWidget {
  final String title;
  final List<SelectionOption> options;
  final String currentValue;
  final Function(String) onSelected;

  const SelectionSettingScreen({
    super.key,
    required this.title,
    required this.options,
    required this.currentValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onBackground,
            size: AppSizes.r20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: AppTextStyles.heading(context)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.w12),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.getSurfaceContainerLowest(context),
                borderRadius: AppSizes.boxBorderRadius,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(
                      AppColors.isDark(context) ? 0.1 : 0.02,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: options.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final option = entry.value;
                  final isLast = idx == options.length - 1;
                  final isSelected = option.value == currentValue;

                  return Column(
                    children: [
                      ListTile(
                        onTap: () {
                          onSelected(option.value);
                          Navigator.pop(context);
                        },
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSizes.w24,
                          vertical: AppSizes.h8,
                        ),
                        leading: Icon(
                          option.icon,
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          size: AppSizes.r(22),
                        ),
                        title: Text(
                          option.label,
                          style: AppTextStyles.body(
                            context,
                            color: isSelected
                                ? AppColors.primary
                                : Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: AppSizes.r(22),
                              )
                            : null,
                      ),
                      if (!isLast)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSizes.w24),
                          child: Divider(
                            height: 1,
                            color: AppColors.getSurfaceContainer(context),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: AppSizes.h20),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}

class SelectionOption {
  final String label;
  final String value;
  final IconData icon;

  SelectionOption({
    required this.label,
    required this.value,
    required this.icon,
  });
}
