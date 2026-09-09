import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/models/budget_model.dart';
import 'package:smart_money_tracker/core/models/budget_instance_model.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/services/time_service.dart';
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
  
  // Yield again to ensure we pick up the synced budgets
  yield await repository.getBudgets(user.id);
  
  // Listen for changes
  await for (final _ in repository.onBudgetsChanged) {
    yield await repository.getBudgets(user.id);
  }
});

final budgetInstancesProvider = StreamProvider<List<BudgetInstanceModel>>((ref) async* {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    yield [];
    return;
  }
  
  final repository = ref.read(budgetRepositoryProvider);
  
  // Initial load
  yield await repository.getBudgetInstances(user.id);
  
  // Listen for changes
  await for (final _ in repository.onBudgetsChanged) {
    yield await repository.getBudgetInstances(user.id);
  }
});

class BudgetProgress {
  final BudgetModel budget;
  final BudgetInstanceModel? instance;
  final double spent;
  final List<TransactionModel> transactions;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String periodLabel;
  final bool isCompleted;
  
  BudgetProgress({
    required this.budget,
    this.instance,
    required this.spent,
    this.transactions = const [],
    this.periodStart,
    this.periodEnd,
    this.periodLabel = '',
    this.isCompleted = false,
  });
  
  double get limitAmount => instance?.amount ?? budget.amount;
  double get percentage => limitAmount > 0 ? (spent / limitAmount) : 0;
  bool get isOverBudget => spent > limitAmount;
  double get remaining => (limitAmount - spent).clamp(0.0, double.infinity);
  bool get isUpcoming {
    if (budget.period != BudgetPeriod.custom) return false;
    if (periodStart == null) return false;
    final now = TimeService.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(periodStart!.year, periodStart!.month, periodStart!.day);
    return start.isAfter(today);
  }
}

String _getMonthName(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  if (month >= 1 && month <= 12) return months[month - 1];
  return '';
}

final Set<String> _autoSpawnedInstances = <String>{};

final budgetProgressProvider = Provider<List<BudgetProgress>>((ref) {
  final budgetsAsync = ref.watch(budgetsProvider);
  final instancesAsync = ref.watch(budgetInstancesProvider);
  final transactionsAsync = ref.watch(transactionsProvider);
  
  final budgets = budgetsAsync.value ?? [];
  final allInstances = instancesAsync.value ?? [];
  final transactions = transactionsAsync.value ?? [];
  final user = ref.watch(authStateProvider).value;
  
  final now = TimeService.now();
  
  final validBudgets = <BudgetProgress>[];
  
  for (var budget in budgets) {
    // Pre-filter transactions for this budget by category / subcategory / type
    final applicableTransactions = transactions.where((txn) {
      if (txn.type != TransactionType.debit) return false;
      if (budget.categoryId != null && budget.categoryId != txn.category) return false;
      if (budget.subcategoryId != null && budget.subcategoryId != txn.subcategory) return false;
      return true;
    }).toList();

    // 1. Custom or Yearly or Non-Recurring Budgets
    if (budget.period == BudgetPeriod.custom ||
        budget.period == BudgetPeriod.yearly ||
        !budget.isRecurring) {
      DateTime? pStart = budget.startDate;
      DateTime? pEnd = budget.endDate;

      if (budget.period == BudgetPeriod.monthly && !budget.isRecurring) {
        final base = budget.startDate ?? now;
        pStart = DateTime(base.year, base.month, 1);
        pEnd = DateTime(base.year, base.month + 1, 0, 23, 59, 59, 999);
      } else if (budget.period == BudgetPeriod.weekly && !budget.isRecurring) {
        final base = budget.startDate ?? now;
        final monday = base.subtract(Duration(days: base.weekday - 1));
        pStart = DateTime(monday.year, monday.month, monday.day);
        pEnd = DateTime(monday.year, monday.month, monday.day + 6, 23, 59, 59, 999);
      } else if (budget.period == BudgetPeriod.yearly) {
        final base = budget.startDate ?? now;
        pStart = DateTime(base.year, 1, 1);
        pEnd = DateTime(base.year, 12, 31, 23, 59, 59, 999);
      }

      final isCompleted = (pEnd != null && pEnd.isBefore(now)) || budget.isStopped;

      double spent = 0;
      final budgetTxns = <TransactionModel>[];
      for (var txn in applicableTransactions) {
        if (pStart != null && txn.date.isBefore(pStart)) continue;
        if (pEnd != null && txn.date.isAfter(pEnd)) continue;
        spent += txn.amount;
        budgetTxns.add(txn);
      }

      String label = 'Custom Period';
      if (budget.period == BudgetPeriod.monthly) {
        final m = pStart ?? now;
        label = "${_getMonthName(m.month)} ${m.year}";
      } else if (budget.period == BudgetPeriod.weekly) {
        final w = pStart ?? now;
        label = "Week of ${_getMonthName(w.month)} ${w.day}";
      } else if (budget.period == BudgetPeriod.yearly) {
        label = "${pStart?.year ?? now.year}";
      } else if (pStart != null && pEnd != null) {
        if (pStart.year == pEnd.year && pStart.month == pEnd.month) {
          label = "${_getMonthName(pStart.month)} ${pStart.year}";
        } else {
          label = "${_getMonthName(pStart.month)} ${pStart.year} - ${_getMonthName(pEnd.month)} ${pEnd.year}";
        }
      }

      validBudgets.add(BudgetProgress(
        budget: budget,
        spent: spent,
        transactions: budgetTxns..sort((a, b) => b.date.compareTo(a.date)),
        periodStart: pStart,
        periodEnd: pEnd,
        periodLabel: label,
        isCompleted: isCompleted,
      ));
      continue;
    }

    // 2. Recurring Budgets (Monthly & Weekly) with Instances Subcollection
    final budgetInstances = allInstances
        .where((inst) => inst.budgetId == budget.id)
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    // Backfilling: Generate all recurring cycles from budget.startDate/createdAt up to current cycle
    final startBase = budget.startDate ?? budget.createdAt;
    
    if (!budget.isStopped) {
      if (budget.period == BudgetPeriod.monthly) {
        var cycle = DateTime(startBase.year, startBase.month, 1);
        final currentMonth = DateTime(now.year, now.month, 1);
        int safetyLimit = 0;
        
        while (!cycle.isAfter(currentMonth) && safetyLimit < 60) {
          safetyLimit++;
          final cStart = cycle;
          final cEnd = DateTime(cStart.year, cStart.month + 1, 0, 23, 59, 59, 999);
          final exists = budgetInstances.any((inst) =>
              inst.startDate.year == cStart.year && inst.startDate.month == cStart.month);
              
          if (!exists) {
            final newInstance = BudgetInstanceModel(
              id: BudgetInstanceModel.generateId(budget.id, cStart),
              budgetId: budget.id,
              amount: budget.amount,
              startDate: cStart,
              endDate: cEnd,
            );
            if (user != null && instancesAsync.hasValue && !_autoSpawnedInstances.contains(newInstance.id)) {
              _autoSpawnedInstances.add(newInstance.id);
              Future.microtask(() {
                ref.read(budgetRepositoryProvider).saveBudgetInstance(user.id, newInstance);
              });
            }
            budgetInstances.add(newInstance);
          }
          cycle = DateTime(cycle.year, cycle.month + 1, 1);
        }
      } else if (budget.period == BudgetPeriod.weekly) {
        final monday = startBase.subtract(Duration(days: startBase.weekday - 1));
        var cycle = DateTime(monday.year, monday.month, monday.day);
        final currentMonday = now.subtract(Duration(days: now.weekday - 1));
        final currentWeekStart = DateTime(currentMonday.year, currentMonday.month, currentMonday.day);
        int safetyLimit = 0;
        
        while (!cycle.isAfter(currentWeekStart) && safetyLimit < 104) {
          safetyLimit++;
          final cStart = cycle;
          final cEnd = DateTime(cStart.year, cStart.month, cStart.day + 6, 23, 59, 59, 999);
          final exists = budgetInstances.any((inst) =>
              inst.startDate.year == cStart.year &&
              inst.startDate.month == cStart.month &&
              inst.startDate.day == cStart.day);
              
          if (!exists) {
            final newInstance = BudgetInstanceModel(
              id: BudgetInstanceModel.generateId(budget.id, cStart),
              budgetId: budget.id,
              amount: budget.amount,
              startDate: cStart,
              endDate: cEnd,
            );
            if (user != null && instancesAsync.hasValue && !_autoSpawnedInstances.contains(newInstance.id)) {
              _autoSpawnedInstances.add(newInstance.id);
              Future.microtask(() {
                ref.read(budgetRepositoryProvider).saveBudgetInstance(user.id, newInstance);
              });
            }
            budgetInstances.add(newInstance);
          }
          cycle = cycle.add(const Duration(days: 7));
        }
      }
    }

    // If budget still has no instances in memory, add currentCycle fallback
    if (budgetInstances.isEmpty) {
      DateTime fallbackStart;
      DateTime fallbackEnd;
      if (budget.period == BudgetPeriod.monthly) {
        fallbackStart = DateTime(now.year, now.month, 1);
        fallbackEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
      } else {
        final monday = now.subtract(Duration(days: now.weekday - 1));
        fallbackStart = DateTime(monday.year, monday.month, monday.day);
        fallbackEnd = DateTime(monday.year, monday.month, monday.day + 6, 23, 59, 59, 999);
      }
      budgetInstances.add(BudgetInstanceModel(
        id: BudgetInstanceModel.generateId(budget.id, fallbackStart),
        budgetId: budget.id,
        amount: budget.amount,
        startDate: fallbackStart,
        endDate: fallbackEnd,
      ));
    }

    // Deduplicate instances by cycle key (e.g. year_month for monthly or year_month_day for weekly)
    final uniqueInstances = <String, BudgetInstanceModel>{};
    for (var inst in budgetInstances) {
      final key = budget.period == BudgetPeriod.monthly
          ? "${inst.startDate.year}_${inst.startDate.month}"
          : "${inst.startDate.year}_${inst.startDate.month}_${inst.startDate.day}";
      if (!uniqueInstances.containsKey(key)) {
        uniqueInstances[key] = inst;
      } else {
        final existing = uniqueInstances[key]!;
        if (inst.isOverridden && !existing.isOverridden) {
          uniqueInstances[key] = inst;
        }
      }
    }

    final deduplicatedList = uniqueInstances.values.toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    for (var instance in deduplicatedList) {
      final isCompleted = instance.endDate.isBefore(now) || instance.isStopped || budget.isStopped;

      double spent = 0;
      final budgetTxns = <TransactionModel>[];
      for (var txn in applicableTransactions) {
        if (txn.date.isBefore(instance.startDate)) continue;
        if (txn.date.isAfter(instance.endDate)) continue;
        spent += txn.amount;
        budgetTxns.add(txn);
      }

      final durationDays = instance.endDate.difference(instance.startDate).inDays;
      String label;
      if (durationDays > 20) {
        label = "${_getMonthName(instance.startDate.month)} ${instance.startDate.year}";
      } else {
        label = "Week of ${_getMonthName(instance.startDate.month)} ${instance.startDate.day}";
      }

      validBudgets.add(BudgetProgress(
        budget: budget,
        instance: instance,
        spent: spent,
        transactions: budgetTxns..sort((a, b) => b.date.compareTo(a.date)),
        periodStart: instance.startDate,
        periodEnd: instance.endDate,
        periodLabel: label,
        isCompleted: isCompleted,
      ));
    }
  }
  
  // Sort the final validBudgets list: active/current budgets first, then newest periods first
  validBudgets.sort((a, b) {
    if (!a.isCompleted && b.isCompleted) return -1;
    if (a.isCompleted && !b.isCompleted) return 1;

    DateTime dateA;
    if (a.isCompleted) {
      dateA = a.periodEnd ?? a.periodStart ?? now;
    } else if (a.periodStart != null && a.periodStart!.isAfter(now)) {
      dateA = a.periodStart!;
    } else {
      dateA = now;
    }

    DateTime dateB;
    if (b.isCompleted) {
      dateB = b.periodEnd ?? b.periodStart ?? now;
    } else if (b.periodStart != null && b.periodStart!.isAfter(now)) {
      dateB = b.periodStart!;
    } else {
      dateB = now;
    }

    int cmp = dateB.compareTo(dateA);
    if (cmp != 0) return cmp;

    return a.budget.name.compareTo(b.budget.name);
  });
  
  return validBudgets;
});

