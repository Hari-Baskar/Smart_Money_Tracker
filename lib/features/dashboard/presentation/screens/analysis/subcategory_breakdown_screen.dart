import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';

class SubcategoryBreakdownScreen extends StatelessWidget {
  final String categoryName;
  final List<TransactionModel> groupTransactions;
  final Color color;
  final String Function(String) resolveSubcategory;
  final void Function(BuildContext, String, List<TransactionModel>, Color)
  onShowTransactions;

  const SubcategoryBreakdownScreen({
    super.key,
    required this.categoryName,
    required this.groupTransactions,
    required this.color,
    required this.resolveSubcategory,
    required this.onShowTransactions,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, List<TransactionModel>> subGroups = {};
    for (var t in groupTransactions) {
      final sub = (t.subcategory?.isNotEmpty == true)
          ? t.subcategory!
          : 'Other';
      subGroups.putIfAbsent(sub, () => []).add(t);
    }

    final sortedSubs = subGroups.keys.toList()
      ..sort((a, b) {
        final totalA = subGroups[a]!.fold(0.0, (sum, t) => sum + t.amount);
        final totalB = subGroups[b]!.fold(0.0, (sum, t) => sum + t.amount);
        return totalB.compareTo(totalA);
      });

    final categoryTotal = groupTransactions.fold(
      0.0,
      (sum, t) => sum + t.amount,
    );

    final Map<String, int> exactPercentages = {};
    if (categoryTotal > 0 && sortedSubs.isNotEmpty) {
      int sumRounded = 0;
      final List<MapEntry<String, double>> remainders = [];

      for (var sub in sortedSubs) {
        final subTotal = subGroups[sub]!.fold(0.0, (sum, t) => sum + t.amount);
        final exact = (subTotal / categoryTotal) * 100;
        final rounded = exact.floor();
        exactPercentages[sub] = rounded;
        sumRounded += rounded;
        remainders.add(MapEntry(sub, exact - rounded));
      }

      final int diff = 100 - sumRounded;
      remainders.sort((a, b) => b.value.compareTo(a.value));
      for (int i = 0; i < diff && i < remainders.length; i++) {
        exactPercentages[remainders[i].key] =
            exactPercentages[remainders[i].key]! + 1;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.getText(context),
            size: AppSizes.r20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "${categoryName} Breakdown",
          style: AppTextStyles.subHeading(context),
        ),

        centerTitle: true,
        //  backgroundColor: AppColors.getSurfaceContainer(context),
        elevation: 0,
      ),
      //  backgroundColor: AppColors.getSurface(context),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.w8,
          vertical: AppSizes.h12,
        ),
        itemCount: sortedSubs.length,
        itemBuilder: (navContext, index) {
          final subKey = sortedSubs[index];
          final subTxns = subGroups[subKey]!;
          final subTotal = subTxns.fold(0.0, (sum, t) => sum + t.amount);
          final finalPercentage = exactPercentages[subKey] ?? 0;
          final subName = subKey == 'Other'
              ? 'Other'
              : resolveSubcategory(subKey);

          return Container(
            margin: EdgeInsets.only(bottom: AppSizes.h8),
            decoration: BoxDecoration(
              color: Theme.of(navContext).colorScheme.surface,
              borderRadius: AppSizes.cardBorderRadius,
              border: AppColors.isDark(navContext)
                  ? null
                  : Border.all(color: AppColors.black.withOpacity(0.08)),
              boxShadow: AppColors.isDark(navContext)
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.03),
                        blurRadius: 16,
                        spreadRadius: 0,
                        offset: Offset.zero,
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: AppSizes.cardBorderRadius,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    onShowTransactions(navContext, subName, subTxns, color);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.w16,
                      vertical: AppSizes.h12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: AppSizes.r40,
                          height: AppSizes.r40,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              subName.isNotEmpty ? subName[0].toUpperCase() : '?',
                              style: AppTextStyles.subHeading(navContext).copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: AppSizes.w16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            subName,
                                            style:
                                                AppTextStyles.body(
                                                  navContext,
                                                ).copyWith(
                                                  color: AppColors.getText(
                                                    navContext,
                                                  ),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(width: AppSizes.w8),
                                        Text(
                                          '${finalPercentage}%',
                                          style: AppTextStyles.body(navContext),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${subTotal.toStringAsFixed(2)}',
                                    style: AppTextStyles.body(navContext)
                                        .copyWith(
                                          color: AppColors.getText(navContext),
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              SizedBox(height: AppSizes.h8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.r4,
                                ),
                                child: LinearProgressIndicator(
                                  value: finalPercentage / 100.0,
                                  backgroundColor: color.withOpacity(0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    color,
                                  ),
                                  minHeight: AppSizes.h4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
