import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/features/auth/presentation/screens/splash_screen.dart';
import 'package:smart_money_tracker/features/auth/presentation/screens/login_screen.dart';
import 'package:smart_money_tracker/features/main/presentation/screens/main_screen.dart';
import 'package:smart_money_tracker/features/main/presentation/screens/permission_disclosure_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/settings_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/app_permissions_settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
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
    ],
  );
});

