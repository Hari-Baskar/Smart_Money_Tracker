import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import '../providers/subcategory_provider.dart';
import 'package:smart_money_tracker/core/common/widgets/category_icon_widget.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';
import 'package:smart_money_tracker/core/common/widgets/app_text_field.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/core/common/widgets/modal_action_sheet.dart';

class TxnCategoryPickerSheet extends ConsumerWidget {
  final ValueNotifier<String> selectedCategory;
  final ValueNotifier<String> selectedSubcategory;
  final bool? isIncome;
  final bool showAllOption;

  const TxnCategoryPickerSheet({
    super.key,
    required this.selectedCategory,
    required this.selectedSubcategory,
    this.isIncome,
    this.showAllOption = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final allCategories = categoriesAsync.value ?? const [];
    final categories = allCategories
        .where((c) => isIncome == null || c.isIncome == isIncome)
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Category',
                style: AppTextStyles.subHeading(
                  context,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.getTextMuted(context),
                ),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
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
              itemCount: categories.length + 1 + (showAllOption ? 1 : 0),
              itemBuilder: (context, index) {
                if (showAllOption && index == 0) {
                  final isSelected = selectedCategory.value == 'All';
                  final catColor = Colors.amber;
                  final catBg = Colors.amber.withOpacity(0.1);

                  return GestureDetector(
                    onTap: () {
                      selectedCategory.value = 'All';
                      selectedSubcategory.value = 'All';
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
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: AppSizes.r(44),
                            height: AppSizes.r(44),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: catColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.pie_chart_rounded,
                              color: AppColors.white,
                              size: AppSizes.r24,
                            ),
                          ),
                          SizedBox(height: AppSizes.h8),
                          Text(
                            'All',
                            style: AppTextStyles.body(
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
                }

                final adjustedIndex = showAllOption ? index - 1 : index;

                // Last item: Add Custom
                if (adjustedIndex == categories.length) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showAddCategoryDialog(
                        context,
                        ref,
                        isIncome: isIncome ?? false,
                        onAdded: (cat) {
                          selectedCategory.value = cat.id;
                          selectedSubcategory.value = showAllOption
                              ? 'All'
                              : 'General';
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
                            style: AppTextStyles.body(context),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final cat = categories[adjustedIndex];
                final isSelected = selectedCategory.value == cat.id;
                final catColor = AppColors.getCategoryColor(cat.name);
                final catBg = AppColors.getCategoryBgColor(context, cat.name);

                return GestureDetector(
                  onTap: () {
                    selectedCategory.value = cat.id;
                    selectedSubcategory.value = showAllOption
                        ? 'All'
                        : 'General';
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
                                  color: catColor,
                                  shape: BoxShape.circle,
                                ),
                                child: CategoryIconWidget(
                                  categoryName: cat.name,
                                  emoji: cat.emoji,
                                  color: AppColors.white,
                                  size: AppSizes.r24,
                                ),
                              ),
                              SizedBox(height: AppSizes.h8),
                              Text.rich(
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: cat.name.length > 13
                                          ? '${cat.name.substring(0, 11)}...'
                                          : cat.name,
                                      style: AppTextStyles.body(
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
                                        style: AppTextStyles.body(
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
      builder: (bottomSheetContext) {
        return ModalActionSheet(
          children: [
            ModalActionItem(
              icon: Icons.edit_outlined,
              title: 'Edit category',
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showRenameCategoryDialog(context, ref, cat);
              },
            ),
            if (cat.isArchived)
              Consumer(
                builder: (context, ref, _) {
                  return ModalActionItem(
                    icon: Icons.unarchive_outlined,
                    title: 'Unarchive category',
                    onTap: () async {
                      final notifier = ref.read(
                        categoriesProvider.notifier,
                      );
                      Navigator.pop(bottomSheetContext);
                      await notifier.unarchiveCategory(cat.id);
                    },
                  );
                },
              ),
            ModalActionItem(
              icon: Icons.delete_outline_rounded,
              title: 'Delete category',
              isDestructive: true,
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showDeleteCategoryDialog(context, ref, cat);
              },
            ),
          ],
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
    String? selectedEmoji = cat.emoji;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setState) {
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
                    child: SafeArea(
                      top: false,
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
                              style: AppTextStyles.subHeading(
                                modalContext,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: AppSizes.h8),
                            Text(
                              'This will change the name across all past and future transactions.',
                              style: AppTextStyles.body(
                                modalContext,
                                color: AppColors.getTextMuted(modalContext),
                              ),
                            ),
                            SizedBox(height: AppSizes.h16),
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    controller: controller,
                                    autofocus: true,
                                    maxLength: 15,
                                    hintText: 'Enter new category name',
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: AppSizes.h24),
                            Row(
                              children: [
                                Expanded(
                                  child: PrimaryButton(
                                    text: 'Save Category',
                                    isExpanded: true,
                                    onPressed: () async {
                                      if (!modalContext.mounted) return;
                                      final newName = controller.text.trim();
                                      if (newName.isNotEmpty &&
                                          newName != cat.name) {
                                        final notifier = freshRef.read(
                                          categoriesProvider.notifier,
                                        );
                                        await notifier.updateCategory(
                                          cat.id,
                                          newName,
                                          emoji: selectedEmoji,
                                        );
                                        if (modalContext.mounted)
                                          Navigator.pop(modalContext);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showDeleteCategoryDialog(
    BuildContext context,
    WidgetRef
    ref, // Unused outer ref (kept for signature compatibility if needed)
    CategoryModel cat,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        Future<bool>? dependencyCheck;

        return Consumer(
          builder: (_, freshRef, __) {
            if (dependencyCheck == null) {
              final userId = freshRef.read(authStateProvider).value?.id;
              dependencyCheck = userId != null
                  ? freshRef
                        .read(transactionRepositoryProvider)
                        .isCategoryInUse(userId, cat.id)
                  : Future.value(false);
            }

            return FutureBuilder<bool>(
              future: dependencyCheck,
              builder: (context, snapshot) {
                final isDark = AppColors.isDark(modalContext);

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.white,
                      borderRadius: AppSizes.boxBorderRadius,
                    ),
                    padding: EdgeInsets.fromLTRB(
                      AppSizes.w24,
                      AppSizes.h24,
                      AppSizes.w24,
                      AppSizes.h24,
                    ),
                    child: SafeArea(
                      top: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Center(child: CircularProgressIndicator()),
                          SizedBox(height: AppSizes.h16),
                          Text(
                            'Checking category usage...',
                            style: AppTextStyles.body(context),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final isUsedInCloud = snapshot.data ?? false;

                final transactionsAsync = freshRef.watch(transactionsProvider);
                final transactions = transactionsAsync.value ?? const [];
                int dependencies = transactions
                    .where((t) => t.category == cat.id)
                    .length;

                if (dependencies == 0 && isUsedInCloud) {
                  dependencies = 1;
                }

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
                        Text(
                          dependencies > 0 && !cat.isArchived
                              ? 'Archive Category?'
                              : 'Delete Category?',
                          style: AppTextStyles.subHeading(
                            modalContext,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: AppSizes.h8),
                        Text(
                          dependencies > 0 && !cat.isArchived
                              ? 'This category is used in $dependencies transaction(s). It will be archived instead of deleted, keeping your transaction history intact. It will no longer appear in selection menus.'
                              : (dependencies > 0 && cat.isArchived
                                    ? 'This archived category is still used in $dependencies transaction(s) and cannot be permanently deleted. Please reassign those transactions first.'
                                    : 'This will permanently delete the custom category "${cat.name}" and all of its custom subcategories. This action cannot be undone.'),
                          style: AppTextStyles.body(modalContext).copyWith(
                            color: AppColors.getTextMuted(modalContext),
                          ),
                        ),
                        if (!(cat.isArchived && dependencies > 0)) ...[
                          SizedBox(height: AppSizes.h24),
                          Row(
                            children: [
                              Expanded(
                                child: PrimaryButton(
                                  text: dependencies > 0 && !cat.isArchived
                                      ? 'Archive Category'
                                      : 'Delete Category',
                                  isExpanded: true,
                                  backgroundColor:
                                      dependencies > 0 && !cat.isArchived
                                      ? AppColors.primary
                                      : AppColors.error,
                                  onPressed: () async {
                                    if (!modalContext.mounted) return;
                                    final notifier = freshRef.read(
                                      categoriesProvider.notifier,
                                    );
                                    if (dependencies > 0 && !cat.isArchived) {
                                      await notifier.archiveCategory(cat.id);
                                    } else {
                                      await notifier.deleteCategory(cat.id);
                                    }
                                    if (selectedCategory.value == cat.id) {
                                      selectedCategory.value = 'Other';
                                      selectedSubcategory.value = 'General';
                                    }
                                    if (modalContext.mounted) {
                                      Navigator.pop(modalContext);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
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
    String? selectedEmoji;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                    child: SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: AppSizes.w(48),
                                height: AppSizes.h4,
                                margin: EdgeInsets.only(bottom: AppSizes.h24),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.white.withOpacity(0.12)
                                      : AppColors.black.withOpacity(0.08),
                                  borderRadius: AppSizes.boxBorderRadius,
                                ),
                              ),
                            ),
                            Text(
                              'Add New Category',
                              style: AppTextStyles.subHeading(
                                context,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),

                            SizedBox(height: AppSizes.h24),
                            AppTextField(
                              controller: controller,
                              autofocus: true,
                              maxLength: 15,
                              hintText: 'e.g. Business, Hobby',
                              prefixIcon: Icon(
                                Icons.category_rounded,
                                color: AppColors.primary,
                                size: AppSizes.r20,
                              ),
                            ),
                            SizedBox(height: AppSizes.h24),
                            Container(
                              padding: EdgeInsets.all(AppSizes.r16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceContainerLowestDark
                                    : AppColors.surfaceContainerLight,
                                borderRadius: AppSizes.boxBorderRadius,
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.white.withOpacity(0.05)
                                      : AppColors.black.withOpacity(0.05),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(AppSizes.r8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      color: AppColors.primary,
                                      size: AppSizes.r16,
                                    ),
                                  ),
                                  SizedBox(width: AppSizes.w16),
                                  Expanded(
                                    child: Text(
                                      'Choose a broad category name to group your expenses.',
                                      style: AppTextStyles.body(
                                        context,
                                        color: AppColors.getTextMuted(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: AppSizes.h32),
                            Row(
                              children: [
                                Expanded(
                                  child: PrimaryButton(
                                    text: 'Add Category',
                                    isExpanded: true,
                                    onPressed: () async {
                                      if (!context.mounted) return;
                                      final name = controller.text.trim();
                                      if (name.isNotEmpty) {
                                        final notifier = ref.read(
                                          categoriesProvider.notifier,
                                        );
                                        final newCat = await notifier
                                            .addCategory(
                                              name,
                                              isIncome: isIncome,
                                              emoji: selectedEmoji,
                                            );
                                        onAdded(newCat);
                                        if (context.mounted)
                                          Navigator.pop(context);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
