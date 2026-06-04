import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import '../providers/subcategory_provider.dart';

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
    final catColor = AppColors.getCategoryColor(split.category);
    final catBg = AppColors.getCategoryBgColor(context, split.category);
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
                        _showCategoryBottomSheetForSplit(
                          context,
                          ref,
                          index,
                          splits,
                          split,
                        );
                      },
                      borderRadius: AppSizes.boxBorderRadius,
                      child: Container(
                        height: AppSizes.h(48),
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.w12,
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
                            Container(
                              padding: EdgeInsets.all(AppSizes.r(4)),
                              decoration: BoxDecoration(
                                color: catBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                AppColors.getCategoryIcon(split.category),
                                color: catColor,
                                size: AppSizes.r(14),
                              ),
                            ),
                            SizedBox(width: AppSizes.w8),
                            Expanded(
                              child: Text(
                                split.category,
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

  void _showCategoryBottomSheetForSplit(
    BuildContext context,
    WidgetRef ref,
    int index,
    ValueNotifier<List<TransactionSplit>> splits,
    TransactionSplit split,
  ) {
    final subcategoriesAsync = ref.read(subcategoriesProvider);
    final defaultCats = isIncome ? incomeCategories : expenseCategories;
    final categoriesAsync = ref.read(categoriesProvider);
    final customCats = categoriesAsync.maybeWhen(
      data: (allCats) => allCats
          .where((c) => c.isIncome == isIncome && c.isCustom)
          .map((c) => c.name)
          .toList(),
      orElse: () => <String>[],
    );
    final allCategories = {...defaultCats, ...customCats}.toList()..sort();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: AppSizes.boxBorderRadius,
          ),
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
                    color: isDark
                        ? AppColors.white.withOpacity(0.12)
                        : AppColors.black.withOpacity(0.08),
                    borderRadius: AppSizes.boxBorderRadius,
                  ),
                ),
              ),
              Text('Select Category', style: AppTextStyles.heading(context)),
              SizedBox(height: AppSizes.h16),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSizes.w12,
                    mainAxisSpacing: AppSizes.h12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: allCategories.length + 1,
                  itemBuilder: (context, indexGrid) {
                    // Last item: Add Custom
                    if (indexGrid == allCategories.length) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showAddCategoryDialog(
                            context,
                            ref,
                            isIncome: isIncome,
                            onAdded: (name) {
                              final newList = List<TransactionSplit>.from(
                                splits.value,
                              );
                              newList[index] = TransactionSplit(
                                amount: split.amount,
                                category: name,
                                subcategory: 'General',
                                notes: split.notes,
                              );
                              splits.value = newList;
                            },
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.transparent,
                            borderRadius: AppSizes.boxBorderRadius,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.white.withOpacity(0.15)
                                  : AppColors.black.withOpacity(0.1),
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: AppSizes.r(44),
                                height: AppSizes.r(44),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add_rounded,
                                  color: AppColors.primary,
                                  size: AppSizes.r24,
                                ),
                              ),
                              SizedBox(height: AppSizes.h8),
                              Text(
                                'Add Custom',
                                style: AppTextStyles.small(
                                  context,
                                  color: AppColors.primary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final cat = allCategories[indexGrid];
                    final isSelected = split.category == cat;
                    final catColor = AppColors.getCategoryColor(cat);
                    final catBg = AppColors.getCategoryBgColor(context, cat);

                    return GestureDetector(
                      onTap: () {
                        final newList = List<TransactionSplit>.from(
                          splits.value,
                        );
                        newList[index] = TransactionSplit(
                          amount: split.amount,
                          category: cat,
                          subcategory: 'General',
                          notes: split.notes,
                        );
                        splits.value = newList;
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? catBg
                              : (isDark
                                    ? AppColors.surfaceContainerLowestDark
                                    : AppColors.backgroundLight),
                          borderRadius: AppSizes.boxBorderRadius,
                          border: Border.all(
                            color: isSelected
                                ? catColor
                                : (isDark
                                      ? AppColors.white.withOpacity(0.05)
                                      : AppColors.black.withOpacity(0.04)),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: catColor.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: AppSizes.r(44),
                              height: AppSizes.r(44),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark
                                          ? AppColors.black.withOpacity(0.2)
                                          : AppColors.white)
                                    : catBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                AppColors.getCategoryIcon(cat),
                                color: catColor,
                                size: AppSizes.r24,
                              ),
                            ),
                            SizedBox(height: AppSizes.h8),
                            Text(
                              cat,
                              style: AppTextStyles.small(
                                context,
                                color: isSelected
                                    ? (isDark ? AppColors.white : catColor)
                                    : AppColors.getText(context),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    required Function(String) onAdded,
    required bool isIncome,
  }) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              borderRadius: AppSizes.boxBorderRadius,
            ),
            padding: EdgeInsets.fromLTRB(
              AppSizes.w24,
              AppSizes.h12,
              AppSizes.w24,
              AppSizes.h24,
            ),
            child: SingleChildScrollView(
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
                        color: isDark
                            ? AppColors.white.withOpacity(0.12)
                            : AppColors.black.withOpacity(0.08),
                        borderRadius: AppSizes.boxBorderRadius,
                      ),
                    ),
                  ),
                  Text(
                    'New Main Category',
                    style: AppTextStyles.heading(context),
                  ),
                  SizedBox(height: AppSizes.h16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: AppTextStyles.body(context),
                    maxLength: 15,
                    decoration: InputDecoration(
                      hintText: 'Enter name (e.g. Business, Hobby)',
                      hintStyle: AppTextStyles.small(
                        context,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.category_rounded,
                        color: AppColors.primary,
                        size: AppSizes.r20,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: AppSizes.boxBorderRadius,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.all(AppSizes.r16),
                    ),
                  ),
                  SizedBox(height: AppSizes.h24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSizes.h16,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.body(
                              context,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSizes.w16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (controller.text.trim().isNotEmpty) {
                              final name = controller.text.trim();
                              await ref
                                  .read(subcategoriesProvider.notifier)
                                  .addSubcategory(
                                    'General',
                                    name,
                                    isIncome: isIncome,
                                  );
                              onAdded(name);
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: AppSizes.h16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSizes.boxBorderRadius,
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Add',
                            style: AppTextStyles.body(
                              context,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    final catColor = AppColors.getCategoryColor(split.category);

    return subcategoriesAsync.when(
      data: (allSubs) {
        final filteredSubs = allSubs
            .where((s) => s.parentCategoryId == split.category)
            .map((s) => s.name)
            .toSet()
            .toList();

        if (!filteredSubs.contains(split.subcategory)) {
          filteredSubs.add(split.subcategory);
        }

        filteredSubs.sort();

        return InkWell(
          onTap: () {
            _showSubcategoryBottomSheetForSplit(
              context,
              ref,
              index,
              splits,
              split,
              filteredSubs,
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
                    split.subcategory,
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

  void _showSubcategoryBottomSheetForSplit(
    BuildContext context,
    WidgetRef ref,
    int index,
    ValueNotifier<List<TransactionSplit>> splits,
    TransactionSplit split,
    List<String> subcategories,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: AppSizes.boxBorderRadius,
          ),
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
                    color: isDark
                        ? AppColors.white.withOpacity(0.12)
                        : AppColors.black.withOpacity(0.08),
                    borderRadius: AppSizes.boxBorderRadius,
                  ),
                ),
              ),
              Text('Select Subcategory', style: AppTextStyles.heading(context)),
              SizedBox(height: AppSizes.h16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: subcategories.length + 1,
                  separatorBuilder: (context, index) => Divider(
                    color: isDark
                        ? AppColors.white.withOpacity(0.05)
                        : AppColors.black.withOpacity(0.04),
                    height: 1,
                  ),
                  itemBuilder: (context, subIndex) {
                    if (subIndex == subcategories.length) {
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSizes.w8,
                          vertical: AppSizes.h4,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showAddSubcategoryDialog(
                            context,
                            ref,
                            category: split.category,
                            onAdded: (name) {
                              final newList = List<TransactionSplit>.from(
                                splits.value,
                              );
                              newList[index] = TransactionSplit(
                                amount: split.amount,
                                category: split.category,
                                subcategory: name,
                                notes: split.notes,
                              );
                              splits.value = newList;
                            },
                          );
                        },
                        leading: Container(
                          width: AppSizes.r(36),
                          height: AppSizes.r(36),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: AppSizes.boxBorderRadius,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: AppColors.primary,
                            size: AppSizes.r20,
                          ),
                        ),
                        title: Text(
                          '+ Add Custom',
                          style: AppTextStyles.body(
                            context,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }

                    final sub = subcategories[subIndex];
                    final isSelected = split.subcategory == sub;
                    final activeCatColor = AppColors.getCategoryColor(
                      split.category,
                    );

                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSizes.w8,
                        vertical: AppSizes.h4,
                      ),
                      onTap: () {
                        final newList = List<TransactionSplit>.from(
                          splits.value,
                        );
                        newList[index] = TransactionSplit(
                          amount: split.amount,
                          category: split.category,
                          subcategory: sub,
                          notes: split.notes,
                        );
                        splits.value = newList;
                        Navigator.pop(context);
                      },
                      leading: Container(
                        width: AppSizes.r(36),
                        height: AppSizes.r(36),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? activeCatColor.withOpacity(0.1)
                              : (isDark
                                    ? AppColors.surfaceContainerLowestDark
                                    : AppColors.backgroundLight),
                          borderRadius: AppSizes.boxBorderRadius,
                        ),
                        child: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: isSelected
                              ? activeCatColor
                              : AppColors.getTextMuted(
                                  context,
                                ).withOpacity(0.5),
                          size: AppSizes.r16,
                        ),
                      ),
                      title: Text(
                        sub,
                        style: AppTextStyles.body(
                          context,
                          color: isSelected
                              ? activeCatColor
                              : AppColors.getText(context),
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color: activeCatColor,
                              size: AppSizes.r20,
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddSubcategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    required String category,
    required Function(String) onAdded,
  }) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              borderRadius: AppSizes.boxBorderRadius,
            ),
            padding: EdgeInsets.fromLTRB(
              AppSizes.w24,
              AppSizes.h12,
              AppSizes.w24,
              AppSizes.h24,
            ),
            child: SingleChildScrollView(
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
                        color: isDark
                            ? AppColors.white.withOpacity(0.12)
                            : AppColors.black.withOpacity(0.08),
                        borderRadius: AppSizes.boxBorderRadius,
                      ),
                    ),
                  ),
                  Text(
                    'New Subcategory',
                    style: AppTextStyles.heading(context),
                  ),
                  SizedBox(height: AppSizes.h4),
                  Text(
                    'For $category',
                    style: AppTextStyles.small(
                      context,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: AppSizes.h16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: AppTextStyles.body(context),
                    maxLength: 20,
                    decoration: InputDecoration(
                      hintText: 'Enter name (e.g. Netflix, Gym)',
                      hintStyle: AppTextStyles.small(
                        context,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.subdirectory_arrow_right_rounded,
                        color: AppColors.primary,
                        size: AppSizes.r20,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: AppSizes.boxBorderRadius,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.all(AppSizes.r16),
                    ),
                  ),
                  SizedBox(height: AppSizes.h24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSizes.h16,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.body(
                              context,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSizes.w16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (controller.text.trim().isNotEmpty) {
                              final name = controller.text.trim();
                              await ref
                                  .read(subcategoriesProvider.notifier)
                                  .addSubcategory(
                                    name,
                                    category,
                                    isIncome: isIncome,
                                  );
                              onAdded(name);
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: AppSizes.h16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSizes.boxBorderRadius,
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Add',
                            style: AppTextStyles.body(
                              context,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
