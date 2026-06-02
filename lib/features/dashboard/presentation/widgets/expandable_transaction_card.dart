import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';

class ExpandableTransactionCard extends StatefulWidget {
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
  State<ExpandableTransactionCard> createState() => _ExpandableTransactionCardState();
}

class _ExpandableTransactionCardState extends State<ExpandableTransactionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final hasSplits = t.splits.isNotEmpty;

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainerLowest(context),
        borderRadius: BorderRadius.circular(AppSizes.r16),
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark(context)
                ? AppColors.black.withOpacity(0.2)
                : AppColors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.isDark(context)
              ? AppColors.white.withOpacity(0.05)
              : AppColors.black.withOpacity(0.03),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: hasSplits
                ? () => setState(() => _isExpanded = !_isExpanded)
                : widget.onTap,
            child: ListTile(
              contentPadding: EdgeInsets.all(AppSizes.r12),
              leading: Container(
                width: AppSizes.r(48),
                height: AppSizes.r(48),
                decoration: BoxDecoration(
                  color: t.type == TransactionType.credit
                      ? AppColors.success.withOpacity(0.12)
                      : AppColors.getCategoryBgColor(context, t.category),
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                ),
                child: Icon(
                  t.type == TransactionType.credit
                      ? Icons.account_balance_wallet_rounded
                      : AppColors.getCategoryIcon(t.category),
                  color: t.type == TransactionType.credit
                      ? AppColors.success
                      : AppColors.getCategoryColor(t.category),
                  size: AppSizes.r24,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.subcategory,
                      style: AppTextStyles.body(
                        context,
                        fontWeight: FontWeight.bold,
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
                      color: hasSplits
                          ? (AppColors.isDark(context)
                              ? AppColors.primary.withOpacity(0.15)
                              : AppColors.primary.withOpacity(0.08))
                          : (AppColors.isDark(context)
                              ? AppColors.white.withOpacity(0.06)
                              : AppColors.primary.withOpacity(0.06)),
                      borderRadius: BorderRadius.circular(AppSizes.r(20)),
                      border: hasSplits
                          ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 0.5)
                          : null,
                    ),
                    child: Text(
                      hasSplits ? 'SPLIT' : t.category.toUpperCase(),
                      style: AppTextStyles.small(
                        context,
                        color: hasSplits
                            ? AppColors.primary
                            : AppColors.getTextMuted(context),
                        fontSize: AppSizes.sSmall, // Uses AppSizes token instead of hardcoded 8
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: EdgeInsets.only(top: AppSizes.h4),
                child: Text(
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
                    style: AppTextStyles.headline(
                      context,
                      color: t.type == TransactionType.credit
                          ? AppColors.success
                          : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (hasSplits) ...[
                    SizedBox(width: AppSizes.w4),
                    // Edit icon for split transactions
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onTap,
                      child: Padding(
                        padding: EdgeInsets.only(left: AppSizes.w(2)),
                        child: Icon(
                           Icons.edit_rounded,
                           color: AppColors.getTextMuted(context).withOpacity(0.5),
                           size: AppSizes.r16,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSizes.w4),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.getTextMuted(context),
                      size: AppSizes.r24,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (hasSplits)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      if (_isExpanded) ...[
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppSizes.w16,
                            AppSizes.h8,
                            AppSizes.w16,
                            AppSizes.h12,
                          ),
                          child: Column(
                            children: t.splits.map((split) {
                              final catColor = AppColors.getCategoryColor(split.category);
                              final catBg = AppColors.getCategoryBgColor(context, split.category);
                              final displayCategoryName = split.category.toUpperCase();

                              return Container(
                                margin: EdgeInsets.symmetric(vertical: AppSizes.h4),
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppSizes.w12,
                                  vertical: AppSizes.h8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.isDark(context)
                                      ? AppColors.white.withOpacity(0.02)
                                      : AppColors.primary.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(AppSizes.r12),
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
                                        AppColors.getCategoryIcon(split.category),
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
                                            split.subcategory,
                                            style: AppTextStyles.body(
                                              context,
                                              fontWeight: FontWeight.w600,
                                              fontSize: AppSizes.sBody, // Uses AppSizes token instead of hardcoded 12
                                            ),
                                          ),
                                          Text(
                                            displayCategoryName,
                                            style: AppTextStyles.small(
                                              context,
                                              color: AppColors.getTextMuted(context),
                                              fontSize: AppSizes.sSmall, // Uses AppSizes token instead of hardcoded 8
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
                                        fontWeight: FontWeight.bold,
                                        fontSize: AppSizes.sBody, // Uses AppSizes token instead of hardcoded 12
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
                ),
              ),
            ),
        ],
      ),
    );
  }
}
