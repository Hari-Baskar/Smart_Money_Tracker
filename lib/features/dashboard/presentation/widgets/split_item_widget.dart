import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
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
    final isDark = AppColors.isDark(context);
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

    String resolveSubcategoryText(String id) {
      final match = subcategories.where((s) => s.id == id).firstOrNull;
      if (match != null && match.isArchived) return '${match.name} (Archived)';
      return match?.name ?? id;
    }

    final displayCategoryText = resolveCategoryText(split.category);
    final displayCategoryRaw = resolveCategoryRaw(split.category);
    final displaySubcategoryText = resolveSubcategoryText(split.subcategory);

    final catColor = AppColors.getCategoryColor(displayCategoryRaw);
    final catBg = AppColors.getCategoryBgColor(context, displayCategoryRaw);
    final formattedDate = split.date != null
        ? DateFormat('MMM dd, hh:mm a').format(split.date!)
        : 'Select Time';

    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.h16),
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
          // Header Row: Split number & Delete button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: AppSizes.r(24),
                    height: AppSizes.r(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: AppTextStyles.small(
                          context,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSizes.w8),
                  Text(
                    'Split Transaction',
                    style: AppTextStyles.body(
                      context,
                      color: AppColors.getText(context),
                    ),
                  ),
                ],
              ),
              IconButton(
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
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error.withOpacity(0.8),
                  size: AppSizes.r(22),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          Divider(
            height: AppSizes.h20,
            color: isDark
                ? AppColors.white.withOpacity(0.06)
                : AppColors.black.withOpacity(0.05),
          ),

          // Pickers Row: Category (and optionally Subcategory)
          Row(
            children: [
              // Category Picker
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: AppTextStyles.small(
                        context,
                        color: AppColors.getTextMuted(context),
                      ),
                    ),
                    SizedBox(height: AppSizes.h(6)),
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
                      child: Container(
                        height: AppSizes.h(48),
                        padding: EdgeInsets.symmetric(horizontal: AppSizes.w12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.white.withOpacity(0.03)
                              : AppColors.black.withOpacity(0.02),
                          border: Border.all(
                            color: isDark
                                ? AppColors.white.withOpacity(0.08)
                                : AppColors.black.withOpacity(0.06),
                          ),
                          borderRadius: AppSizes.boxBorderRadius,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.all(AppSizes.r(4)),
                              decoration: BoxDecoration(
                                color: catBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                AppColors.getCategoryIcon(displayCategoryRaw),
                                color: catColor,
                                size: AppSizes.r(14),
                              ),
                            ),
                            SizedBox(width: AppSizes.w8),
                            Expanded(
                              child: Text(
                                displayCategoryText,
                                style: AppTextStyles.small(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: AppSizes.r16,
                              color: AppColors.getTextMuted(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (split.category != 'Other') ...[
                SizedBox(width: AppSizes.w12),
                // Subcategory Picker
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subcategory',
                        style: AppTextStyles.small(
                          context,
                          color: AppColors.getTextMuted(context),
                        ),
                      ),
                      SizedBox(height: AppSizes.h(6)),
                      SizedBox(
                        height: AppSizes.h(48),
                        child: _buildSplitSubcategoryPickerWidget(
                          context,
                          ref,
                          index,
                          split,
                          splits,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          SizedBox(height: AppSizes.h16),

          // Inputs Row: Amount & Date/Time
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Amount Input Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: AppTextStyles.small(
                        context,
                        color: AppColors.getTextMuted(context),
                      ),
                    ),
                    SizedBox(height: AppSizes.h(6)),
                    Focus(
                      child: Builder(
                        builder: (context) {
                          final hasFocus = Focus.of(context).hasFocus;
                          return Container(
                            height: AppSizes.h(48),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.white.withOpacity(0.03)
                                  : AppColors.black.withOpacity(0.02),
                              border: Border.all(
                                color: hasFocus
                                    ? AppColors.primary
                                    : (isDark
                                          ? AppColors.white.withOpacity(0.08)
                                          : AppColors.black.withOpacity(0.06)),
                                width: hasFocus ? 1.5 : 1.0,
                              ),
                              borderRadius: AppSizes.boxBorderRadius,
                            ),
                            alignment: Alignment.center,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              style: AppTextStyles.body(context),
                              decoration: InputDecoration(
                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(
                                    left: AppSizes.w12,
                                    right: AppSizes.w(6),
                                  ),
                                  child: Icon(
                                    Icons.currency_rupee_rounded,
                                    size: AppSizes.r16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                prefixIconConstraints: BoxConstraints(
                                  minWidth: AppSizes.w(28),
                                  minHeight: AppSizes.h20,
                                ),
                                hintText: '0.00',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: AppSizes.h(12),
                                ),
                              ),
                              onChanged: (val) {
                                final amount = double.tryParse(val) ?? 0;
                                final newList = List<TransactionSplit>.from(
                                  splits.value,
                                );
                                newList[index] = TransactionSplit(
                                  amount: amount,
                                  category: split.category,
                                  subcategory: split.subcategory,
                                  notes: split.notes,
                                  date: split.date,
                                );
                                splits.value = newList;
                              },
                              controller: splitControllers.value[index],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: AppSizes.w12),

              // Date/Time Button Picker
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date & Time',
                      style: AppTextStyles.small(
                        context,
                        color: AppColors.getTextMuted(context),
                      ),
                    ),
                    SizedBox(height: AppSizes.h(6)),
                    InkWell(
                      onTap: () =>
                          selectDateTime(split.date ?? DateTime.now(), (dt) {
                            final newList = List<TransactionSplit>.from(
                              splits.value,
                            );
                            newList[index] = TransactionSplit(
                              amount: split.amount,
                              category: split.category,
                              subcategory: split.subcategory,
                              notes: split.notes,
                              date: dt,
                            );
                            splits.value = newList;
                          }),
                      borderRadius: AppSizes.boxBorderRadius,
                      child: Container(
                        height: AppSizes.h(48),
                        padding: EdgeInsets.symmetric(horizontal: AppSizes.w12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.white.withOpacity(0.03)
                              : AppColors.black.withOpacity(0.02),
                          border: Border.all(
                            color: isDark
                                ? AppColors.white.withOpacity(0.08)
                                : AppColors.black.withOpacity(0.06),
                          ),
                          borderRadius: AppSizes.boxBorderRadius,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                formattedDate,
                                style: AppTextStyles.small(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.calendar_month_rounded,
                              size: AppSizes.r16,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    final isDark = AppColors.isDark(context);
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
        final filteredSubs = allSubs
            .where((s) => s.parentCategoryId == split.category)
            .toList();

        filteredSubs.sort((a, b) => a.name.compareTo(b.name));

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
          child: Container(
            height: AppSizes.h48,
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.w12,
              vertical: AppSizes.h(10),
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.white.withOpacity(0.03)
                  : AppColors.black.withOpacity(0.02),
              border: Border.all(
                color: isDark
                    ? AppColors.white.withOpacity(0.08)
                    : AppColors.black.withOpacity(0.06),
              ),
              borderRadius: AppSizes.boxBorderRadius,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    allSubs.where((s) => s.id == split.subcategory).firstOrNull?.name ?? split.subcategory,
                    style: AppTextStyles.small(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: AppSizes.r16,
                  color: catColor,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        height: AppSizes.h(38),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.white.withOpacity(0.03)
              : AppColors.black.withOpacity(0.02),
          border: Border.all(
            color: isDark
                ? AppColors.white.withOpacity(0.08)
                : AppColors.black.withOpacity(0.06),
          ),
          borderRadius: AppSizes.boxBorderRadius,
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

}
