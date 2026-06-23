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
import 'package:smart_money_tracker/core/models/transaction_model.dart';

class ExpandableTransactionCard extends ConsumerStatefulWidget {
  final TransactionModel transaction;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? margin;

  const ExpandableTransactionCard({
    super.key,
    required this.transaction,
    required this.onTap,
    this.margin,
  });

  @override
  ConsumerState<ExpandableTransactionCard> createState() =>
      _ExpandableTransactionCardState();
}

class _ExpandableTransactionCardState extends ConsumerState<ExpandableTransactionCard> {
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

    return Card(
      margin: widget.margin ?? EdgeInsets.symmetric(horizontal: AppSizes.w8),
      shape: RoundedRectangleBorder(
        borderRadius: AppSizes.boxBorderRadius,

        side: BorderSide(color: AppColors.primary.withOpacity(0.1), width: 1),
      ),
      color: AppColors.getSurfaceContainerLowest(context),
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSizes.w12,
                vertical: AppSizes.h2,
              ),
              leading: hasSplits
                  ? null
                  : Container(
                      width: AppSizes.r(48),
                      height: AppSizes.r(48),
                      decoration: BoxDecoration(
                        color: t.type == TransactionType.credit
                            ? AppColors.success.withOpacity(0.12)
                            : AppColors.getCategoryBgColor(context, displayCategoryRaw),
                        borderRadius: AppSizes.boxBorderRadius,
                      ),
                      child: Icon(
                        t.type == TransactionType.credit
                            ? Icons.account_balance_wallet_rounded
                            : AppColors.getCategoryIcon(displayCategoryRaw),
                        color: t.type == TransactionType.credit
                            ? AppColors.success
                            : AppColors.getCategoryColor(displayCategoryRaw),
                        size: AppSizes.r20,
                      ),
                    ),
              title: hasSplits
                  // ── Split parent: merchant + SPLIT badge ──────────
                  ? Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.merchant.trim().isNotEmpty
                                ? t.merchant
                                : 'Transaction',
                            style: AppTextStyles.body(
                              context,
                              fontWeight: FontWeight.w600,
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
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    )
                  // ── Normal: subcategory + category badge ─────────
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            displaySubcategoryText,
                            style: AppTextStyles.body(context),
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
                                ? AppColors.white.withOpacity(0.06)
                                : AppColors.primary.withOpacity(0.06),
                            borderRadius: AppSizes.boxBorderRadius,
                          ),
                          child: Text(
                            displayCategoryText.toUpperCase(),
                            style: AppTextStyles.small(
                              context,
                              color: AppColors.getTextMuted(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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
                        t.merchant.trim().isNotEmpty
                            ? "${t.type == TransactionType.credit ? 'From' : 'Payee'}: ${t.merchant} • ${DateFormat('hh:mm a').format(t.date)}"
                            : DateFormat('hh:mm a').format(t.date),
                        style: AppTextStyles.small(
                          context,
                          color: AppColors.getTextMuted(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${t.type == TransactionType.credit ? '+' : '-'}₹${AppColors.formatShortAmount(t.amount)}',
                    style: AppTextStyles.heading(
                      context,
                      color: t.type == TransactionType.credit
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasSplits) ...[
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: AppColors.isDark(context)
                  ? AppColors.white.withOpacity(0.12)
                  : AppColors.black.withOpacity(0.08),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSizes.w16,
                AppSizes.h8,
                AppSizes.w16,
                AppSizes.h12,
              ),
              child: Column(
                children: displaySplits.map((split) {
                  final displayCategoryTextName = resolveCategoryText(split.category);
                  final displayCategoryRawName = resolveCategoryRaw(split.category);
                  final catColor = AppColors.getCategoryColor(displayCategoryRawName);
                  final catBg = AppColors.getCategoryBgColor(
                    context,
                    displayCategoryRawName,
                  );

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: AppSizes.h2),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.w12,
                      vertical: AppSizes.h4,
                    ),

                    child: Row(
                      children: [
                        Container(
                          width: AppSizes.r(32),
                          height: AppSizes.r(32),
                          decoration: BoxDecoration(
                            color: catBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppColors.getCategoryIcon(displayCategoryRawName),
                            color: catColor,
                            size: AppSizes.r16,
                          ),
                        ),
                        SizedBox(width: AppSizes.w12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resolveSubcategoryText(split.subcategory),
                                style: AppTextStyles.body(context),
                              ),
                              Text(
                                displayCategoryTextName.toUpperCase(),
                                style: AppTextStyles.small(
                                  context,
                                  color: AppColors.getTextMuted(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${AppColors.formatShortAmount(split.amount)}',
                          style: AppTextStyles.body(
                            context,
                            color: t.type == TransactionType.credit
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
