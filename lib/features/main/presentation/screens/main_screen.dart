import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/history_screen.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/screens/add_transaction_screen.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/main/presentation/widgets/app_drawer.dart';
import 'dart:io';
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/core/constants/app_routes.dart';

final mainScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
  return GlobalKey<ScaffoldState>();
});

class MainScreenIndex extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final mainScreenIndexProvider = NotifierProvider<MainScreenIndex, int>(MainScreenIndex.new);

class MainScreen extends HookConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(mainScreenIndexProvider);
    final authState = ref.watch(authStateProvider).value;

    useEffect(() {
      StreamSubscription? sub;

      Future<void> initGuard() async {
        if (authState == null || authState.isAnonymous) return;

        final deviceInfo = DeviceInfoPlugin();
        String? currentDeviceId;
        if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          currentDeviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          currentDeviceId = iosInfo.identifierForVendor;
        }

        if (currentDeviceId == null) return;

        sub = ref
            .read(authRepositoryProvider)
            .watchUserSettings(authState.id)
            .listen((settings) async {
              if (settings != null &&
                  settings.containsKey('active_device_id')) {
                final activeDeviceId = settings['active_device_id'] as String?;
                if (activeDeviceId != null &&
                    activeDeviceId != currentDeviceId) {
                  sub?.cancel();

                  if (context.mounted) {
                    context.go('/session-expired');
                  }

                  await ref
                      .read(authNotifierProvider.notifier)
                      .forceSignOut(authState.id);
                }
              }
            });
      }

      initGuard();
      return () => sub?.cancel();
    }, [authState?.id]);

    final List<Widget> screens = [
      const DashboardScreen(),
      const HistoryScreen(),
    ];

    final isDark = AppColors.isDark(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        key: ref.read(mainScaffoldKeyProvider),
        drawer: const AppDrawer(),
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          top: true, 
          bottom: false, 
          child: IndexedStack(
            index: selectedIndex,
            children: screens,
          )
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          bottom: true,
          child: Container(
            padding: EdgeInsets.only(bottom: AppSizes.h4, top: AppSizes.h4),
            decoration: BoxDecoration(color: AppColors.getBackground(context)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  ref,
                  selectedIndex,
                  0,
                  Icons.home_outlined,
                  Icons.home_rounded,
                  'Home',
                ),
                _buildNavItem(
                  context,
                  ref,
                  selectedIndex,
                  1,
                  Icons.history_toggle_off,
                  Icons.history,
                  'History',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref,
    int selectedIndex,
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(mainScreenIndexProvider.notifier).setIndex(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.w16,
          vertical: AppSizes.h4,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: AppSizes.boxBorderRadius,
        ),
        child: AnimatedScale(
          scale: isSelected ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 20,
                color: isSelected
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              Text(
                label,
                style:
                    AppTextStyles.small(
                      context,
                      color: isSelected
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ).copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
