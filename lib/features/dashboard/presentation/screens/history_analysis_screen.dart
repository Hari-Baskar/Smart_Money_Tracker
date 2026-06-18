import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/history_analysis_view.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';

class HistoryAnalysisScreen extends HookConsumerWidget {
  final List<TransactionModel> transactions;

  const HistoryAnalysisScreen({super.key, required this.transactions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisType = useState('Expenses');

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Analysis', style: AppTextStyles.heading(context)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSizes.w12,
          right: AppSizes.w12,
          top: AppSizes.w12,
          bottom: AppSizes.h(100),
        ),
        child: HistoryAnalysisView(
          transactions: transactions,
          analysisType: analysisType,
        ),
      ),
    );
  }
}
