import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:smart_money_tracker/features/auth/presentation/screens/splash_screen.dart';
import 'package:smart_money_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:smart_money_tracker/features/main/presentation/screens/main_screen.dart';
import 'package:smart_money_tracker/features/main/presentation/screens/permission_disclosure_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/settings_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/app_permissions_settings_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/income_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/expense_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/edit_profile_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/feedback_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/settings_detail_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/selection_setting_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/transaction_detail_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/add_transaction_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/history_filter_screen.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    observers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/income',
        builder: (context, state) => const IncomeScreen(),
      ),
      GoRoute(
        path: '/expense',
        builder: (context, state) => const ExpenseScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/permissions',
        builder: (context, state) => const PermissionDisclosureScreen(),
      ),
      GoRoute(
        path: '/app-permissions',
        builder: (context, state) => const AppPermissionsSettingsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: '/settings-detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return SettingsDetailScreen(
            title: extra['title'] as String,
            content: extra['content'] as String,
          );
        },
      ),
      GoRoute(
        path: '/selection-setting',
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
        path: '/transaction-detail',
        builder: (context, state) {
          final transaction = state.extra as TransactionModel;
          return TransactionDetailScreen(transaction: transaction);
        },
      ),
      GoRoute(
        path: '/add-transaction',
        builder: (context, state) => const AddTransactionScreen(),
      ),
      GoRoute(
        path: '/history-filter',
        builder: (context, state) {
          final initial = state.extra as HistoryFilterState;
          return HistoryFilterScreen(initial: initial);
        },
      ),
    ],
  );
});

