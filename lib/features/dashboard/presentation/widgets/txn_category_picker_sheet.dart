import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import '../providers/subcategory_provider.dart';

class TxnCategoryPickerSheet extends ConsumerWidget {
  final ValueNotifier<String> selectedCategory;
  final ValueNotifier<String> selectedSubcategory;
  final List<String> categories;
  final bool isIncome;

  const TxnCategoryPickerSheet({
    super.key,
    required this.selectedCategory,
    required this.selectedSubcategory,
    required this.categories,
    required this.isIncome,
  });

  bool _isDefaultCategory(String category) {
    return const [
      'Food',
      'Travel',
      'Shopping',
      'Bills',
      'Entertainment',
      'Health',
      'Investment',
      'Other',
      'Salary',
    ].contains(category);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                // Last item: Add Custom
                if (index == categories.length) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showAddCategoryDialog(
                        context,
                        ref,
                        isIncome: isIncome,
                        onAdded: (name) {
                          selectedCategory.value = name;
                          selectedSubcategory.value = 'General';
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

                final cat = categories[index];
                final isSelected = selectedCategory.value == cat;
                final catColor = AppColors.getCategoryColor(cat);
                final catBg = AppColors.getCategoryBgColor(context, cat);
                final isCustom = !_isDefaultCategory(cat);

                return GestureDetector(
                  onTap: () {
                    selectedCategory.value = cat;
                    selectedSubcategory.value = 'General';
                    Navigator.pop(context);
                  },
                  onLongPress: isCustom
                      ? () {
                          Navigator.pop(context);
                          _showManageCategorySheet(context, ref, cat);
                        }
                      : null,
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
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.center,
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
                                cat.length > 13
                                    ? '${cat.substring(0, 11)}...'
                                    : cat,
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
  }

  void _showManageCategorySheet(
    BuildContext context,
    WidgetRef ref,
    String categoryName,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
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
          child: SafeArea(
            top: false,
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
                Text('Manage Category', style: AppTextStyles.heading(context)),
                Text(
                  categoryName,
                  style: AppTextStyles.body(
                    context,
                    color: AppColors.getTextMuted(context),
                  ),
                ),
                SizedBox(height: AppSizes.h24),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(AppSizes.r8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: AppColors.primary,
                      size: AppSizes.r20,
                    ),
                  ),
                  title: Text(
                    'Rename Category',
                    style: AppTextStyles.body(context),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showRenameCategoryDialog(context, ref, categoryName);
                  },
                ),
                Divider(
                  color: isDark
                      ? AppColors.white.withOpacity(0.05)
                      : AppColors.black.withOpacity(0.04),
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(AppSizes.r8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_rounded,
                      color: AppColors.error,
                      size: AppSizes.r20,
                    ),
                  ),
                  title: Text(
                    'Delete Category',
                    style: AppTextStyles.body(context, color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteCategoryDialog(context, ref, categoryName);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRenameCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    String categoryName,
  ) {
    final controller = TextEditingController(text: categoryName);
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
                    'Rename Category',
                    style: AppTextStyles.heading(context),
                  ),
                  SizedBox(height: AppSizes.h16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: AppTextStyles.body(context),
                    maxLength: 15,
                    decoration: InputDecoration(
                      hintText: 'Enter new category name',
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
                            final newName = controller.text.trim();
                            if (newName.isNotEmpty && newName != categoryName) {
                              await ref
                                  .read(subcategoriesProvider.notifier)
                                  .updateCategory(categoryName, newName);
                              if (selectedCategory.value == categoryName) {
                                selectedCategory.value = newName;
                              }
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
                            'Save',
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

  void _showDeleteCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    String categoryName,
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
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
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
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: AppSizes.r(40),
                ),
                SizedBox(height: AppSizes.h16),
                Text(
                  'Delete Category?',
                  style: AppTextStyles.heading(context),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.h12),
                Text(
                  'This will permanently delete the custom category "$categoryName" and all of its custom subcategories. This action cannot be undone.',
                  style: AppTextStyles.body(
                    context,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.h24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
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
                          await ref
                              .read(subcategoriesProvider.notifier)
                              .deleteCategory(categoryName);
                          if (selectedCategory.value == categoryName) {
                            selectedCategory.value = 'Other';
                            selectedSubcategory.value = 'General';
                          }
                          if (context.mounted) {
                            Navigator.pop(context); // Close bottom sheet
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.white,
                          padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSizes.boxBorderRadius,
                          ),
                        ),
                        child: Text(
                          'Delete',
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
}
