import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/subcategory_provider.dart';
import 'package:smart_money_tracker/core/common/widgets/category_icon_widget.dart';

class ExpandableTransactionCard extends ConsumerStatefulWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? margin;
  final bool isGrouped;

  const ExpandableTransactionCard({
    super.key,
    required this.transaction,
    required this.onTap,
    this.margin,
    this.isGrouped = false,
  });

  @override
  ConsumerState<ExpandableTransactionCard> createState() =>
      _ExpandableTransactionCardState();
}

class _ExpandableTransactionCardState
    extends ConsumerState<ExpandableTransactionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final hasSplits = t.splits.isNotEmpty;

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

    String? resolveCategoryEmoji(String id) {
      final match = categories.where((c) => c.id == id).firstOrNull;
      return match?.emoji;
    }

    String resolveSubcategoryText(String id) {
      final match = subcategories.where((s) => s.id == id).firstOrNull;
      if (match != null && match.isArchived) return '${match.name} (Archived)';
      return match?.name ?? id;
    }

    final displayCategoryText = resolveCategoryText(t.category);
    final displayCategoryRaw = resolveCategoryRaw(t.category);
    final displaySubcategoryText = resolveSubcategoryText(t.subcategory);

    final totalSplitAmount = t.splits.fold<double>(
      0.0,
      (sum, item) => sum + item.amount,
    );
    final remainderAmount = t.amount - totalSplitAmount;
    final List<TransactionSplit> displaySplits = List.from(t.splits);
    if (remainderAmount > 0.01) {
      displaySplits.add(
        TransactionSplit(
          amount: remainderAmount,
          category: t.category,
          subcategory: t.subcategory,
        ),
      );
    }

    return Container(
      margin: EdgeInsets.zero,
      decoration: const BoxDecoration(color: Colors.transparent),
      child: ClipRRect(
        borderRadius: AppSizes.boxBorderRadius,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: AppSizes.r(40),
                  height: AppSizes.r(40),
                  decoration: BoxDecoration(
                    color: hasSplits
                        ? AppColors.primary
                        : AppColors.getCategoryColor(
                            displayCategoryRaw,
                          ),
                    shape: BoxShape.circle,
                  ),
                  child: hasSplits
                      ? Center(
                          child: Text(
                            'S',
                            style: TextStyle(
                              fontSize: AppSizes.r(18),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : CategoryIconWidget(
                          categoryName: displayCategoryRaw,
                          emoji: resolveCategoryEmoji(t.category),
                          color: Colors.white,
                          size: AppSizes.r(18),
                        ),
                ),
                title: hasSplits
                    // ── Split parent: merchant + SPLIT badge ──────────
                    ? Row(
                        children: [
                          Flexible(
                            child: Text(
                              t.merchant.trim().isNotEmpty &&
                                      t.merchant.trim() != '-'
                                  ? t.merchant
                                  : 'Transaction',
                              style: AppTextStyles.body(
                                context,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: AppSizes.w8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSizes.w8,
                              vertical: AppSizes.h(2),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.isDark(context)
                                  ? AppColors.primary.withOpacity(0.15)
                                  : AppColors.primary.withOpacity(0.08),
                              borderRadius: AppSizes.boxBorderRadius,
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              'SPLIT',
                              style: AppTextStyles.small(
                                context,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      )
                    // ── Normal: subcategory + category badge ─────────
                    : Text(
                        displaySubcategoryText,
                        style: AppTextStyles.body(
                          context,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                subtitle: Padding(
                  padding: EdgeInsets.only(top: AppSizes.h4),
                  child: hasSplits
                      // ── Split parent: just show time ─────────────────
                      ? Text(
                          DateFormat('hh:mm a').format(t.date),
                          style: AppTextStyles.small(
                            context,
                            color: AppColors.getTextMuted(context),
                          ),
                        )
                      // ── Normal: payee + time ─────────────────────────
                      : Text(
                          t.merchant.trim().isNotEmpty &&
                                  t.merchant.trim() != '-'
                              ? "${t.merchant} • ${DateFormat('hh:mm a').format(t.date)}"
                              : DateFormat('hh:mm a').format(t.date),
                          style: AppTextStyles.small(
                            context,
                            color: AppColors.getTextMuted(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                trailing: Text(
                  '₹${AppColors.formatShortAmount(t.amount)}',
                  style: AppTextStyles.subHeading(
                    context,
                    fontWeight: FontWeight.w500,
                    color: t.type == TransactionType.credit
                        ? AppColors.success
                        : AppColors.getText(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
