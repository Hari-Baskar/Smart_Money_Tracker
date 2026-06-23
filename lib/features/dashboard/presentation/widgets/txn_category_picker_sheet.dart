import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import '../providers/subcategory_provider.dart';

class TxnCategoryPickerSheet extends ConsumerWidget {
  final ValueNotifier<String> selectedCategory;
  final ValueNotifier<String> selectedSubcategory;
  final bool isIncome;

  const TxnCategoryPickerSheet({
    super.key,
    required this.selectedCategory,
    required this.selectedSubcategory,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final allCategories = categoriesAsync.value ?? const [];
    final categories = allCategories
        .where((c) => c.isIncome == isIncome)
        .toList();

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
                        onAdded: (cat) {
                          selectedCategory.value = cat.id;
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
                final isSelected = selectedCategory.value == cat.id;
                final catColor = AppColors.getCategoryColor(cat.name);
                final catBg = AppColors.getCategoryBgColor(context, cat.name);

                return GestureDetector(
                  onTap: () {
                    selectedCategory.value = cat.id;
                    selectedSubcategory.value = 'General';
                    Navigator.pop(context);
                  },
                  onLongPress: cat.isCustom
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
                                  AppColors.getCategoryIcon(cat.name),
                                  color: catColor,
                                  size: AppSizes.r24,
                                ),
                              ),
                              SizedBox(height: AppSizes.h8),
                              RichText(
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: cat.name.length > 13
                                          ? '${cat.name.substring(0, 11)}...'
                                          : cat.name,
                                      style: AppTextStyles.small(
                                        context,
                                        color: isSelected
                                            ? (isDark
                                                  ? AppColors.white
                                                  : catColor)
                                            : AppColors.getText(context),
                                      ),
                                    ),
                                    if (cat.isArchived)
                                      TextSpan(
                                        text: '\n(Archived)',
                                        style: AppTextStyles.small(
                                          context,
                                          color: AppColors.error,
                                        ),
                                      ),
                                  ],
                                ),
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
    CategoryModel cat,
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
                  cat.name,
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
                    _showRenameCategoryDialog(context, ref, cat);
                  },
                ),
                Divider(
                  color: isDark
                      ? AppColors.white.withOpacity(0.05)
                      : AppColors.black.withOpacity(0.04),
                ),
                if (cat.isArchived) ...[
                  Consumer(
                    builder: (context, ref, _) {
                      return ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(AppSizes.r8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.unarchive_rounded,
                            color: AppColors.primary,
                            size: AppSizes.r20,
                          ),
                        ),
                        title: Text(
                          'Unarchive Category',
                          style: AppTextStyles.body(context),
                        ),
                        onTap: () async {
                          final notifier = ref.read(
                            categoriesProvider.notifier,
                          );
                          Navigator.pop(context);
                          await notifier.unarchiveCategory(cat.id);
                        },
                      );
                    },
                  ),
                  Divider(
                    color: isDark
                        ? AppColors.white.withOpacity(0.05)
                        : AppColors.black.withOpacity(0.04),
                  ),
                ],
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
                    _showDeleteCategoryDialog(context, ref, cat);
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
    CategoryModel cat,
  ) {
    final controller = TextEditingController(text: cat.name);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return Consumer(
          builder: (_, freshRef, __) {
            final isDark = AppColors.isDark(modalContext);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
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
                        style: AppTextStyles.heading(modalContext),
                      ),
                      SizedBox(height: AppSizes.h16),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        style: AppTextStyles.body(modalContext),
                        maxLength: 15,
                        decoration: InputDecoration(
                          hintText: 'Enter new category name',
                          hintStyle: AppTextStyles.small(
                            modalContext,
                            color: Theme.of(
                              modalContext,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.category_rounded,
                            color: AppColors.primary,
                            size: AppSizes.r20,
                          ),
                          filled: true,
                          fillColor: Theme.of(modalContext).colorScheme.surface,
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
                              onPressed: () => Navigator.pop(modalContext),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSizes.h16,
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: AppTextStyles.body(
                                  modalContext,
                                  color: Theme.of(
                                    modalContext,
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
                                if (newName.isNotEmpty && newName != cat.name) {
                                  await freshRef
                                      .read(categoriesProvider.notifier)
                                      .updateCategory(cat.id, newName);
                                  if (modalContext.mounted)
                                    Navigator.pop(modalContext);
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
                                  modalContext,
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
      },
    );
  }

  void _showDeleteCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryModel cat,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return Consumer(
          builder: (_, freshRef, __) {
            final isDark = AppColors.isDark(modalContext);
            final transactionsAsync = freshRef.watch(transactionsProvider);
            final transactions = transactionsAsync.value ?? const [];
            final dependencies = transactions
                .where((t) => t.category == cat.id)
                .length;

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
                      dependencies > 0 && !cat.isArchived
                          ? Icons.archive_rounded
                          : Icons.warning_amber_rounded,
                      color: dependencies > 0 && !cat.isArchived
                          ? AppColors.primary
                          : AppColors.error,
                      size: AppSizes.r(40),
                    ),
                    SizedBox(height: AppSizes.h16),
                    Text(
                      dependencies > 0 && !cat.isArchived
                          ? 'Archive Category?'
                          : 'Delete Category?',
                      style: AppTextStyles.heading(modalContext),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSizes.h12),
                    Text(
                      dependencies > 0 && !cat.isArchived
                          ? 'This category is used in $dependencies transaction(s). It will be archived instead of deleted, keeping your transaction history intact. It will no longer appear in selection menus.'
                          : (dependencies > 0 && cat.isArchived
                                ? 'This archived category is still used in $dependencies transaction(s) and cannot be permanently deleted. Please reassign those transactions first.'
                                : 'This will permanently delete the custom category "${cat.name}" and all of its custom subcategories. This action cannot be undone.'),
                      style: AppTextStyles.body(
                        modalContext,
                        color: Theme.of(
                          modalContext,
                        ).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSizes.h24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(modalContext),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSizes.h16,
                              ),
                            ),
                            child: Text(
                              cat.isArchived && dependencies > 0
                                  ? 'Okay'
                                  : 'Cancel',
                              style: AppTextStyles.body(
                                modalContext,
                                color: Theme.of(
                                  modalContext,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        if (!(cat.isArchived && dependencies > 0)) ...[
                          SizedBox(width: AppSizes.w16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (dependencies > 0 && !cat.isArchived) {
                                  await freshRef
                                      .read(categoriesProvider.notifier)
                                      .archiveCategory(cat.id);
                                } else {
                                  await freshRef
                                      .read(categoriesProvider.notifier)
                                      .deleteCategory(cat.id);
                                }
                                if (selectedCategory.value == cat.id) {
                                  selectedCategory.value = 'Other';
                                  selectedSubcategory.value = 'General';
                                }
                                if (modalContext.mounted) {
                                  Navigator.pop(modalContext);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    dependencies > 0 && !cat.isArchived
                                    ? AppColors.primary
                                    : AppColors.error,
                                foregroundColor: AppColors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSizes.h16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppSizes.boxBorderRadius,
                                ),
                              ),
                              child: Text(
                                dependencies > 0 && !cat.isArchived
                                    ? 'Archive'
                                    : 'Delete',
                                style: AppTextStyles.body(
                                  modalContext,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    required Function(CategoryModel) onAdded,
    required bool isIncome,
  }) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
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
                                final name = controller.text.trim();
                                if (name.isNotEmpty) {
                                  final newCat = await ref
                                      .read(categoriesProvider.notifier)
                                      .addCategory(name, isIncome: isIncome);
                                  onAdded(newCat);
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
      },
    );
  }
}
