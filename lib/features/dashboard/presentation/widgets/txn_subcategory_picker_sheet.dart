import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';
import 'package:smart_money_tracker/core/common/widgets/app_text_field.dart';
import 'package:smart_money_tracker/core/common/widgets/modal_action_sheet.dart';
import '../providers/subcategory_provider.dart';

class TxnSubcategoryPickerSheet extends ConsumerWidget {
  final ValueNotifier<String> selectedSubcategory;
  final String parentCategory; // Stores Category ID
  final bool? isIncome;
  final bool showAllOption;

  const TxnSubcategoryPickerSheet({
    super.key,
    required this.selectedSubcategory,
    required this.parentCategory,
    this.isIncome,
    this.showAllOption = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final allSubcategoriesAsync = ref.watch(subcategoriesProvider);
    final allSubcategories = allSubcategoriesAsync.value ?? const [];

    // Filter subcategories by category ID
    final subcategories = allSubcategories
        .where((s) => s.parentCategoryId == parentCategory)
        .toList();

    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.value ?? const [];
    String resolveCategory(String id) {
      final match = categories.where((c) => c.id == id).firstOrNull;
      return match?.name ?? id;
    }

    final parentCategoryName = resolveCategory(parentCategory);

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
                'Select Subcategory',
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
            child: ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: subcategories.length + 1 + (showAllOption ? 1 : 0),
              separatorBuilder: (context, index) => Divider(
                color: isDark
                    ? AppColors.white.withOpacity(0.05)
                    : AppColors.black.withOpacity(0.04),
                height: 1,
              ),
              itemBuilder: (context, index) {
                if (showAllOption && index == 0) {
                  final isSelected = selectedSubcategory.value == 'All';

                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSizes.w8,
                      vertical: AppSizes.h4,
                    ),
                    onTap: () {
                      selectedSubcategory.value = 'All';
                      Navigator.pop(context);
                    },
                    leading: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.pie_chart_rounded,
                      color: isSelected
                          ? AppColors.getText(context)
                          : AppColors.getTextMuted(context).withValues(alpha: 0.5),
                      size: AppSizes.r20,
                    ),
                    title: Text(
                      'All Subcategories',
                      style: AppTextStyles.body(
                        context,
                        fontWeight: FontWeight.w500,
                        color: AppColors.getText(context),
                      ),
                    ),
                  );
                }

                final adjustedIndex = showAllOption ? index - 1 : index;

                if (adjustedIndex == subcategories.length) {
                  // Custom Add button
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSizes.w8,
                      vertical: AppSizes.h4,
                    ),
                    onTap: () {
                      _showAddSubcategoryDialog(
                        context,
                        ref,
                        category: parentCategory,
                        onAdded: (sub) {
                          selectedSubcategory.value = sub.id;
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        isIncome: isIncome ?? false,
                      );
                    },
                    leading: Icon(
                      Icons.add_rounded,
                      color: AppColors.getTextMuted(context),
                      size: AppSizes.r20,
                    ),
                    title: Text(
                      'Add Custom',
                      style: AppTextStyles.body(context),
                    ),
                  );
                }

                final sub = subcategories[adjustedIndex];
                final isSelected = selectedSubcategory.value == sub.id;

                return ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSizes.w8,
                    vertical: AppSizes.h4,
                  ),
                  onTap: () {
                    selectedSubcategory.value = sub.id;
                    Navigator.pop(context);
                  },
                  onLongPress: (sub.isCustom && sub.name != 'General')
                      ? () {
                          _showManageSubcategorySheet(
                            context,
                            ref,
                            sub,
                            selectedSubcategory,
                          );
                        }
                      : null,
                  leading: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: isSelected
                        ? AppColors.getText(context)
                        : AppColors.getTextMuted(context).withValues(alpha: 0.5),
                    size: AppSizes.r20,
                  ),
                  title: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: sub.name,
                          style: AppTextStyles.body(
                            context,
                            fontWeight: FontWeight.w500,
                            color: AppColors.getText(context),
                          ),
                        ),
                        if (sub.isArchived)
                          TextSpan(
                            text: ' (Archived)',
                            style: AppTextStyles.body(
                              context,
                              color: AppColors.error,
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

  void _showManageSubcategorySheet(
    BuildContext context,
    WidgetRef ref,
    SubcategoryModel sub,
    ValueNotifier<String> selectedSubcategory,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (bottomSheetContext) {
        return ModalActionSheet(
          children: [
            ModalActionItem(
              icon: Icons.edit_outlined,
              title: 'Edit subcategory',
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showRenameSubcategoryDialog(
                  context,
                  ref,
                  sub,
                  selectedSubcategory,
                );
              },
            ),
            if (sub.isArchived)
              Consumer(
                builder: (context, ref, _) {
                  return ModalActionItem(
                    icon: Icons.unarchive_outlined,
                    title: 'Unarchive subcategory',
                    onTap: () async {
                      final notifier = ref.read(
                        subcategoriesProvider.notifier,
                      );
                      Navigator.pop(bottomSheetContext);
                      await notifier.unarchiveSubcategory(sub.id);
                    },
                  );
                },
              ),
            ModalActionItem(
              icon: Icons.delete_outline_rounded,
              title: 'Delete subcategory',
              isDestructive: true,
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showDeleteSubcategoryDialog(
                  context,
                  ref,
                  sub,
                  selectedSubcategory,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showRenameSubcategoryDialog(
    BuildContext context,
    WidgetRef ref,
    SubcategoryModel sub,
    ValueNotifier<String> selectedSubcategory,
  ) {
    final controller = TextEditingController(text: sub.name);
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
                              'Rename Subcategory',
                              style: AppTextStyles.subHeading(
                                modalContext,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),
                        SizedBox(height: AppSizes.h8),
                        Text(
                          'This will change the name across all past and future transactions.',
                          style: AppTextStyles.body(modalContext).copyWith(
                            color: AppColors.getTextMuted(modalContext),
                          ),
                        ),
                        SizedBox(height: AppSizes.h16),
                        AppTextField(
                          controller: controller,
                          autofocus: true,
                          maxLength: 20,
                          hintText: 'Enter new name',
                          prefixIcon: Icon(
                            Icons.subdirectory_arrow_right_rounded,
                            color: AppColors.primary,
                            size: AppSizes.r20,
                          ),
                        ),
                        SizedBox(height: AppSizes.h24),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                text: 'Save Subcategory',
                                isExpanded: true,
                                onPressed: () async {
                                  final newName = controller.text.trim();
                                  if (newName.isNotEmpty) {
                                    if (newName != sub.name) {
                                      await freshRef
                                          .read(subcategoriesProvider.notifier)
                                          .updateSubcategory(sub.id, newName);
                                    }
                                    if (modalContext.mounted) {
                                      Navigator.pop(modalContext);
                                    }
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
  }

  void _showDeleteSubcategoryDialog(
    BuildContext context,
    WidgetRef ref,
    SubcategoryModel sub,
    ValueNotifier<String> selectedSubcategory,
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
                .where((t) => t.subcategory == sub.id)
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
                        Text(
                          dependencies > 0 && !sub.isArchived
                              ? 'Archive Subcategory?'
                              : 'Delete Subcategory?',
                          style: AppTextStyles.subHeading(
                            modalContext,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                    SizedBox(height: AppSizes.h8),
                    Text(
                      dependencies > 0 && !sub.isArchived
                          ? 'This subcategory is used in $dependencies transaction(s). It will be archived instead of deleted, keeping your transaction history intact. It will no longer appear in selection menus.'
                          : (dependencies > 0 && sub.isArchived
                                ? 'This archived subcategory is still used in $dependencies transaction(s) and cannot be permanently deleted. Please reassign those transactions first.'
                                : 'This will permanently delete the custom subcategory "${sub.name}". This action cannot be undone.'),
                      style: AppTextStyles.body(
                        modalContext,
                      ).copyWith(color: AppColors.getTextMuted(modalContext)),
                    ),
                    if (!(sub.isArchived && dependencies > 0)) ...[
                      SizedBox(height: AppSizes.h24),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              text: dependencies > 0 && !sub.isArchived
                                  ? 'Archive Subcategory'
                                  : 'Delete Subcategory',
                              isExpanded: true,
                              backgroundColor:
                                  dependencies > 0 && !sub.isArchived
                                  ? AppColors.primary
                                  : AppColors.error,
                              onPressed: () async {
                                if (dependencies > 0 && !sub.isArchived) {
                                  await freshRef
                                      .read(subcategoriesProvider.notifier)
                                      .archiveSubcategory(sub.id);
                                } else {
                                  await freshRef
                                      .read(subcategoriesProvider.notifier)
                                      .deleteSubcategory(sub.id);
                                }
                                if (selectedSubcategory.value == sub.id) {
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
  }

  void _showAddSubcategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    required String category,
    required Function(SubcategoryModel) onAdded,
    bool isIncome = false,
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
                              'Add New Subcategory',
                              style: AppTextStyles.subHeading(
                                context,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),

                        SizedBox(height: AppSizes.h24),
                        AppTextField(
                          controller: controller,
                          autofocus: true,
                          maxLength: 20,
                          hintText: 'e.g. Netflix, Gym',
                          prefixIcon: Icon(
                            Icons.subdirectory_arrow_right_rounded,
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
                                  'Choose a name that helps you easily identify this subcategory.',
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
                                text: 'Add Subcategory',
                                isExpanded: true,
                                onPressed: () async {
                                  final name = controller.text.trim();
                                  if (name.isNotEmpty) {
                                    final newSub = await ref
                                        .read(subcategoriesProvider.notifier)
                                        .addSubcategory(
                                          name,
                                          category,
                                          isIncome: isIncome,
                                        );
                                    onAdded(newSub);
                                    if (context.mounted) Navigator.pop(context);
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
  }
}
