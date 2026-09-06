import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:smart_money_tracker/core/constants/app_routes.dart';
import 'package:smart_money_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:smart_money_tracker/features/auth/presentation/screens/force_logout_screen.dart';
import 'package:smart_money_tracker/features/auth/presentation/screens/session_expired_screen.dart';

import 'package:smart_money_tracker/features/auth/presentation/screens/app_lock_screen.dart';
import 'package:smart_money_tracker/features/main/presentation/screens/main_screen.dart';
import 'package:smart_money_tracker/features/main/presentation/screens/permission_disclosure_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/settings_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/income_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/expense_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/edit_profile_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/feedback_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/settings_detail_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/selection_setting_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/transaction_detail_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/add_transaction_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/history_filter_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/download_report_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/history_analysis_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/sync_disclosure_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/ignored_transactions_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/ignored_transaction_detail_screen.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/models/ignored_transaction_model.dart';
import 'package:smart_money_tracker/core/common/screens/update_screen.dart';

import 'package:smart_money_tracker/features/budget/presentation/screens/budget_dashboard_screen.dart';
import 'package:smart_money_tracker/features/budget/presentation/screens/create_budget_screen.dart';
import 'package:smart_money_tracker/features/budget/presentation/screens/budget_detail_screen.dart';
import 'package:smart_money_tracker/features/budget/presentation/screens/budget_history_screen.dart';
import 'package:smart_money_tracker/features/budget/domain/providers/budget_providers.dart';
import 'package:smart_money_tracker/core/models/budget_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    observers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
    routes: [
      GoRoute(
        path: AppRoutes.income,
        builder: (context, state) {
          final initialDateRange = state.extra as DateTimeRange?;
          return IncomeScreen(initialDateRange: initialDateRange);
        },
      ),
      GoRoute(
        path: AppRoutes.expense,
        builder: (context, state) {
          final initialDateRange = state.extra as DateTimeRange?;
          return ExpenseScreen(initialDateRange: initialDateRange);
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forceLogout,
        builder: (context, state) {
          final activeDeviceName = state.extra as String;
          return ForceLogoutScreen(activeDeviceName: activeDeviceName);
        },
      ),
      GoRoute(
        path: AppRoutes.sessionExpired,
        builder: (context, state) => const SessionExpiredScreen(),
      ),

      GoRoute(
        path: AppRoutes.appLock,
        builder: (context, state) {
          final nextRoute = state.extra as String;
          return AppLockScreen(nextRoute: nextRoute);
        },
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: AppRoutes.permissions,
        builder: (context, state) => const PermissionDisclosureScreen(),
      ),
      GoRoute(
        path: AppRoutes.syncDisclosure,
        builder: (context, state) => const SyncDisclosureScreen(),
      ),

      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.ignoredTransactions,
        builder: (context, state) => const IgnoredTransactionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.ignoredTransactionDetail,
        builder: (context, state) {
          final transaction = state.extra as IgnoredTransactionModel;
          return IgnoredTransactionDetailScreen(transaction: transaction);
        },
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.feedback,
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsDetail,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return SettingsDetailScreen(
            title: extra['title'] as String,
            content: extra['content'] as String,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.selectionSetting,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return SelectionSettingScreen(
            title: extra['title'] as String,
            currentValue: extra['currentValue'] as String,
            options: extra['options'] as List<SelectionOption>,
            onSelected: extra['onSelected'] as void Function(String),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.transactionDetail,
        builder: (context, state) {
          final transaction = state.extra as TransactionModel;
          return TransactionDetailScreen(transaction: transaction);
        },
      ),
      GoRoute(
        path: AppRoutes.addTransaction,
        builder: (context, state) => const AddTransactionScreen(),
      ),
      GoRoute(
        path: AppRoutes.historyFilter,
        builder: (context, state) {
          final initial = state.extra as HistoryFilterState;
          return HistoryFilterScreen(initial: initial);
        },
      ),
      GoRoute(
        path: AppRoutes.downloadReport,
        builder: (context, state) {
          final args = state.extra as DownloadReportScreenArgs;
          return DownloadReportScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.update,
        builder: (context, state) {
          final args = state.extra as UpdateScreenArgs?;
          if (args == null) {
            // Handle hot-reload state loss by returning a fallback
            return const Scaffold(
              body: Center(
                child: Text(
                  'Update info lost during reload. Please restart app.',
                ),
              ),
            );
          }
          return UpdateScreen(args: args);
        },
      ),
      GoRoute(
        path: AppRoutes.historyAnalysis,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final transactions = extra['transactions'] as List<TransactionModel>;
          final dateRange = extra['dateRange'] as DateTimeRange;
          return HistoryAnalysisScreen(
            transactions: transactions,
            dateRange: dateRange,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.budgets,
        builder: (context, state) => const BudgetDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.createBudget,
        builder: (context, state) {
          final budget = state.extra as BudgetModel?;
          return CreateBudgetScreen(budgetToEdit: budget);
        },
      ),
      GoRoute(
        path: AppRoutes.budgetDetail,
        builder: (context, state) {
          final progress = state.extra as BudgetProgress;
          return BudgetDetailScreen(initialProgress: progress);
        },
      ),
      GoRoute(
        path: AppRoutes.budgetHistory,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BudgetHistoryScreen(
            transactions: extra['transactions'] as List<TransactionModel>,
            budgetName: extra['budgetName'] as String,
          );
        },
      ),
    ],
  );
});
