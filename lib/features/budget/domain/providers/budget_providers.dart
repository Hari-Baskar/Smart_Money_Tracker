import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/models/budget_model.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/budget/data/repositories/budget_repository.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

final budgetsProvider = StreamProvider<List<BudgetModel>>((ref) async* {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    yield [];
    return;
  }
  
  final repository = ref.read(budgetRepositoryProvider);
  
  // Initial load
  yield await repository.getBudgets(user.id);
  
  // Sync from Firebase
  await repository.syncBudgetsFromFirebase(user.id);
  
  // Yield again to ensure we pick up the synced budgets, since we were not listening to the broadcast stream during the sync
  yield await repository.getBudgets(user.id);
  
  // Listen for changes
  await for (final _ in repository.onBudgetsChanged) {
    yield await repository.getBudgets(user.id);
  }
});

class BudgetProgress {
  final BudgetModel budget;
  final double spent;
  final List<TransactionModel> transactions;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String periodLabel;
  final bool isCompleted;
  
  BudgetProgress({
    required this.budget,
    required this.spent,
    this.transactions = const [],
    this.periodStart,
    this.periodEnd,
    this.periodLabel = '',
    this.isCompleted = false,
  });
  
  double get percentage => budget.amount > 0 ? (spent / budget.amount) : 0;
  bool get isOverBudget => spent > budget.amount;
  double get remaining => (budget.amount - spent).clamp(0.0, double.infinity);
}

String _getMonthName(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  if (month >= 1 && month <= 12) return months[month - 1];
  return '';
}

final budgetProgressProvider = Provider<List<BudgetProgress>>((ref) {
  final budgetsAsync = ref.watch(budgetsProvider);
  final transactionsAsync = ref.watch(transactionsProvider);
  
  final budgets = budgetsAsync.value ?? [];
  final transactions = transactionsAsync.value ?? [];
  
  final now = DateTime.now();
  final currentMonth = DateTime(now.year, now.month);
  
  final validBudgets = <BudgetProgress>[];
  
  for (var budget in budgets) {
    // Pre-filter transactions for this budget
    final applicableTransactions = transactions.where((txn) {
      if (txn.type != TransactionType.debit) return false;
      if (budget.categoryId != null && budget.categoryId != txn.category) return false;
      
      if (budget.endDate != null) {
        final end = budget.isStopped 
            ? budget.endDate! 
            : DateTime(budget.endDate!.year, budget.endDate!.month, budget.endDate!.day, 23, 59, 59, 999);
        if (txn.date.isAfter(end)) return false;
      }
      return true;
    }).toList();

    // 1. Custom Budget
    if (budget.period == BudgetPeriod.custom) {
      final isCompleted = budget.endDate != null && DateTime(budget.endDate!.year, budget.endDate!.month, budget.endDate!.day, 23, 59, 59).isBefore(now);
      
      double spent = 0;
      final budgetTxns = <TransactionModel>[];
      for (var txn in applicableTransactions) {
        if (budget.startDate != null) {
          final start = DateTime(budget.startDate!.year, budget.startDate!.month, budget.startDate!.day);
          if (txn.date.isBefore(start)) continue;
        }
        
        spent += txn.amount;
        budgetTxns.add(txn);
      }
      
      String label = 'Custom Period';
      if (budget.startDate != null && budget.endDate != null) {
        if (budget.startDate!.year == budget.endDate!.year && budget.startDate!.month == budget.endDate!.month) {
          label = "${_getMonthName(budget.startDate!.month)} ${budget.startDate!.year}";
        } else {
          DateTime targetMonth = budget.endDate!;
          DateTime currentMonthDate = DateTime(now.year, now.month);
          DateTime endMonthDate = DateTime(budget.endDate!.year, budget.endDate!.month);
          
          if (endMonthDate.isAfter(currentMonthDate)) {
             targetMonth = now; 
          }
          label = "${_getMonthName(targetMonth.month)} ${targetMonth.year}";
        }
      }

      validBudgets.add(BudgetProgress(
        budget: budget,
        spent: spent,
        transactions: budgetTxns..sort((a, b) => b.date.compareTo(a.date)),
        periodStart: budget.startDate,
        periodEnd: budget.endDate,
        periodLabel: label,
        isCompleted: isCompleted,
      ));
      continue;
    }
    
    // 2. Recurring Budgets
    // Find the earliest valid transaction to determine how far back to go, but bounded by budget.startDate
    DateTime? earliestTxnDate;
    for (var txn in applicableTransactions) {
      if (earliestTxnDate == null || txn.date.isBefore(earliestTxnDate)) {
        earliestTxnDate = txn.date;
      }
    }
    
    DateTime effectiveStart = budget.startDate ?? earliestTxnDate ?? now;
    // ensure effectiveStart is not *after* now just in case
    if (effectiveStart.isAfter(now)) effectiveStart = now;
    
    if (budget.period == BudgetPeriod.monthly) {
      DateTime iterMonth = DateTime(effectiveStart.year, effectiveStart.month);
      
      DateTime limitMonth = currentMonth;
      if (budget.endDate != null) {
        final endMonth = DateTime(budget.endDate!.year, budget.endDate!.month);
        if (endMonth.isBefore(currentMonth)) {
          limitMonth = endMonth;
        }
      }
      
      while (!iterMonth.isAfter(limitMonth)) {
        final isCompleted = iterMonth.isBefore(limitMonth) || (budget.endDate != null && iterMonth.isBefore(currentMonth));
        
        double spent = 0;
        final budgetTxns = <TransactionModel>[];
        for (var txn in applicableTransactions) {
          final txnMonth = DateTime(txn.date.year, txn.date.month);
          if (txnMonth == iterMonth) {
            spent += txn.amount;
            budgetTxns.add(txn);
          }
        }
        
        // Only add if it's the current month (or limit month) OR it has transactions (so we don't spam empty past months)
        if (iterMonth == limitMonth || budgetTxns.isNotEmpty) {
          // Calculate period bounds
          final start = iterMonth;
          final end = DateTime(iterMonth.year, iterMonth.month + 1, 0); // Last day of month
          
          validBudgets.add(BudgetProgress(
            budget: budget,
            spent: spent,
            transactions: budgetTxns..sort((a, b) => b.date.compareTo(a.date)),
            periodStart: start,
            periodEnd: end,
            periodLabel: "${_getMonthName(iterMonth.month)} ${iterMonth.year}",
            isCompleted: isCompleted,
          ));
        }
        
        // Next month
        iterMonth = DateTime(iterMonth.year, iterMonth.month + 1);
      }
    } else if (budget.period == BudgetPeriod.yearly) {
      int iterYear = effectiveStart.year;
      
      int limitYear = now.year;
      if (budget.endDate != null && budget.endDate!.year < now.year) {
        limitYear = budget.endDate!.year;
      }
      
      while (iterYear <= limitYear) {
        final isCompleted = iterYear < limitYear || (budget.endDate != null && iterYear < now.year);
        
        double spent = 0;
        final budgetTxns = <TransactionModel>[];
        for (var txn in applicableTransactions) {
          if (txn.date.year == iterYear) {
            spent += txn.amount;
            budgetTxns.add(txn);
          }
        }
        
        if (iterYear == limitYear || budgetTxns.isNotEmpty) {
          final start = DateTime(iterYear, 1, 1);
          final end = DateTime(iterYear, 12, 31);
          
          validBudgets.add(BudgetProgress(
            budget: budget,
            spent: spent,
            transactions: budgetTxns..sort((a, b) => b.date.compareTo(a.date)),
            periodStart: start,
            periodEnd: end,
            periodLabel: "$iterYear",
            isCompleted: isCompleted,
          ));
        }
        
        iterYear++;
      }
    } else if (budget.period == BudgetPeriod.weekly) {
      // Weekly logic: Find the Monday of effectiveStart week
      DateTime iterWeekStart = DateTime(effectiveStart.year, effectiveStart.month, effectiveStart.day)
          .subtract(Duration(days: effectiveStart.weekday - 1));
      
      DateTime currentWeekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));
          
      DateTime limitWeekStart = currentWeekStart;
      if (budget.endDate != null) {
        DateTime endWeekStart = DateTime(budget.endDate!.year, budget.endDate!.month, budget.endDate!.day)
            .subtract(Duration(days: budget.endDate!.weekday - 1));
        if (endWeekStart.isBefore(currentWeekStart)) {
          limitWeekStart = endWeekStart;
        }
      }
          
      while (!iterWeekStart.isAfter(limitWeekStart)) {
        final isCompleted = iterWeekStart.isBefore(limitWeekStart) || (budget.endDate != null && iterWeekStart.isBefore(currentWeekStart));
        DateTime iterWeekEnd = iterWeekStart.add(const Duration(days: 7)); // Next monday 00:00
        
        double spent = 0;
        final budgetTxns = <TransactionModel>[];
        for (var txn in applicableTransactions) {
          final txnDate = DateTime(txn.date.year, txn.date.month, txn.date.day);
          if (txnDate.isBefore(iterWeekStart) || !txnDate.isBefore(iterWeekEnd)) continue;
          
          spent += txn.amount;
          budgetTxns.add(txn);
        }
        
        if (iterWeekStart == limitWeekStart || budgetTxns.isNotEmpty) {
          // periodEnd is the Sunday
          final end = iterWeekStart.add(const Duration(days: 6));
          validBudgets.add(BudgetProgress(
            budget: budget,
            spent: spent,
            transactions: budgetTxns..sort((a, b) => b.date.compareTo(a.date)),
            periodStart: iterWeekStart,
            periodEnd: end,
            periodLabel: "Week of ${_getMonthName(iterWeekStart.month)} ${iterWeekStart.day}",
            isCompleted: isCompleted,
          ));
        }
        
        iterWeekStart = iterWeekStart.add(const Duration(days: 7));
      }
    }
  }
  
  // Sort the final validBudgets list: newest periods first
  validBudgets.sort((a, b) {
    // If one has no periodEnd, assume it's ongoing/newest
    if (a.periodEnd == null && b.periodEnd != null) return -1;
    if (b.periodEnd == null && a.periodEnd != null) return 1;
    if (a.periodEnd == null && b.periodEnd == null) return 0;
    
    // Sort descending (newest first)
    int cmp = b.periodEnd!.compareTo(a.periodEnd!);
    if (cmp != 0) return cmp;
    
    return a.budget.name.compareTo(b.budget.name);
  });
  
  return validBudgets;
});
