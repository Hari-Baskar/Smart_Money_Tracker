import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/common/widgets/app_text_field.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import '../providers/subcategory_provider.dart';
import 'txn_category_picker_sheet.dart';
import 'txn_subcategory_picker_sheet.dart';

class SplitItemWidget extends ConsumerWidget {
  final int index;
  final TransactionSplit split;
  final ValueNotifier<List<TransactionSplit>> splits;
  final ValueNotifier<List<TextEditingController>> splitControllers;
  final Future<void> Function(DateTime initialDate, Function(DateTime) onPicked)
  selectDateTime;
  final bool isIncome;
  final List<String> expenseCategories;
  final List<String> incomeCategories;
  const SplitItemWidget({
    super.key,
    required this.index,
    required this.split,
    required this.splits,
    required this.splitControllers,
    required this.selectDateTime,
    required this.isIncome,
    required this.expenseCategories,
    required this.incomeCategories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final subcategoriesAsync = ref.watch(subcategoriesProvider);
    final categories = categoriesAsync.value ?? const [];
    final subcategories = subcategoriesAsync.value ?? const [];

    String resolveCategoryText(String id) {
      final match = categories.where((c) => c.id == id).firstOrNull;
      if (match != null && match.isArchived) return '${match.name} (Archived)';
      return match?.name ?? id;
    }

    String resolveCategoryRaw(String id) {
      final match = categories.where((c) => c.id == id).firstOrNull;
      return match?.name ?? id;
    }

    final displayCategoryText = resolveCategoryText(split.category);
    final displayCategoryRaw = resolveCategoryRaw(split.category);

    final catColor = AppColors.getCategoryColor(displayCategoryRaw);

    final isDark = AppColors.isDark(context);

    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.h24),
      padding: EdgeInsets.all(AppSizes.r16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainerLowest(context),
        borderRadius: AppSizes.boxBorderRadius,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AppColors.black.withOpacity(0.3)
                : AppColors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark
              ? AppColors.white.withOpacity(0.06)
              : AppColors.primary.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Split number
          Text(
            '${index + 1}. Split Transaction',
            style: AppTextStyles.body(
              context,
              color: AppColors.getText(context),
            ),
          ),

          SizedBox(height: AppSizes.h12),

          // Amount Input Field
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
            child: Row(
              children: [
                Container(
                  width: AppSizes.r(36),
                  height: AppSizes.r(36),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.currency_rupee_rounded,
                    color: AppColors.white,
                    size: AppSizes.r20,
                  ),
                ),
                SizedBox(width: AppSizes.w16),
                Expanded(
                  child: AppTextField(
                    controller: splitControllers.value[index],
                    keyboardType: TextInputType.number,
                    labelText: 'Amount',
                    onChanged: (val) {
                      final amount = double.tryParse(val) ?? 0;
                      final newList = List<TransactionSplit>.from(splits.value);
                      newList[index] = TransactionSplit(
                        amount: amount,
                        category: split.category,
                        subcategory: split.subcategory,
                        notes: split.notes,
                        date: split.date,
                      );
                      splits.value = newList;
                    },
                  ),
                ),
              ],
            ),
          ),

          // Category Picker
          InkWell(
            onTap: () {
              final tempCatNotifier = ValueNotifier<String>(split.category);
              final tempSubNotifier = ValueNotifier<String>(split.subcategory);

              void updateSplit() {
                final newList = List<TransactionSplit>.from(splits.value);
                newList[index] = TransactionSplit(
                  amount: split.amount,
                  category: tempCatNotifier.value,
                  subcategory: tempSubNotifier.value,
                  notes: split.notes,
                  date: split.date,
                );
                splits.value = newList;
              }

              tempCatNotifier.addListener(updateSplit);
              tempSubNotifier.addListener(updateSplit);

              showModalBottomSheet(
                context: context,
                backgroundColor: AppColors.transparent,
                isScrollControlled: true,
                builder: (context) => TxnCategoryPickerSheet(
                  selectedCategory: tempCatNotifier,
                  selectedSubcategory: tempSubNotifier,
                  isIncome: isIncome,
                ),
              );
            },
            borderRadius: AppSizes.boxBorderRadius,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
              child: Row(
                children: [
                  Container(
                    width: AppSizes.r(36),
                    height: AppSizes.r(36),
                    decoration: BoxDecoration(
                      color: catColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      AppColors.getCategoryIcon(displayCategoryRaw),
                      color: AppColors.white,
                      size: AppSizes.r20,
                    ),
                  ),
                  SizedBox(width: AppSizes.w16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: AppTextStyles.body(
                            context,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: AppSizes.h(2)),
                        Text(
                          displayCategoryText,
                          style: AppTextStyles.body(context),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_right_rounded,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                    size: AppSizes.r20,
                  ),
                ],
              ),
            ),
          ),

          if (split.category != 'Other')
            _buildSplitSubcategoryPickerWidget(
              context,
              ref,
              index,
              split,
              splits,
            ),

          SizedBox(height: AppSizes.h12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                final newList = List<TransactionSplit>.from(splits.value);
                newList.removeAt(index);
                splits.value = newList;

                final newControllers = List<TextEditingController>.from(
                  splitControllers.value,
                );
                newControllers[index].dispose();
                newControllers.removeAt(index);
                splitControllers.value = newControllers;
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.w12,
                  vertical: AppSizes.h8,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Remove Split',
                style: AppTextStyles.body(context).copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // end of split inputs
        ],
      ),
    );
  }

  Widget _buildSplitSubcategoryPickerWidget(
    BuildContext context,
    WidgetRef ref,
    int index,
    TransactionSplit split,
    ValueNotifier<List<TransactionSplit>> splits,
  ) {
    final subcategoriesAsync = ref.watch(subcategoriesProvider);
    final categoriesAsync = ref.read(categoriesProvider);
    final catName =
        categoriesAsync.value
            ?.firstWhere(
              (c) => c.id == split.category,
              orElse: () =>
                  CategoryModel(id: split.category, name: split.category),
            )
            .name ??
        split.category;

    final catColor = AppColors.getCategoryColor(catName);

    return subcategoriesAsync.when(
      data: (allSubs) {
        return InkWell(
          onTap: () {
            final tempSubNotifier = ValueNotifier<String>(split.subcategory);
            tempSubNotifier.addListener(() {
              final newList = List<TransactionSplit>.from(splits.value);
              newList[index] = TransactionSplit(
                amount: split.amount,
                category: split.category,
                subcategory: tempSubNotifier.value,
                notes: split.notes,
                date: split.date,
              );
              splits.value = newList;
            });

            showModalBottomSheet(
              context: context,
              backgroundColor: AppColors.transparent,
              isScrollControlled: true,
              builder: (context) => TxnSubcategoryPickerSheet(
                selectedSubcategory: tempSubNotifier,
                parentCategory: split.category,
                isIncome: isIncome,
              ),
            );
          },
          borderRadius: AppSizes.boxBorderRadius,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
            child: Row(
              children: [
                Container(
                  width: AppSizes.r(36),
                  height: AppSizes.r(36),
                  decoration: BoxDecoration(
                    color: catColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.subdirectory_arrow_right_rounded,
                    color: Colors.white,
                    size: AppSizes.r20,
                  ),
                ),
                SizedBox(width: AppSizes.w16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subcategory',
                        style: AppTextStyles.small(
                          context,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: AppSizes.h(2)),
                      Text(
                        allSubs
                                .where((s) => s.id == split.subcategory)
                                .firstOrNull
                                ?.name ??
                            split.subcategory,
                        style: AppTextStyles.body(context),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  size: AppSizes.r20,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
