import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../../sms_disclosure/presentation/screens/sms_disclosure_screen.dart';
import 'package:smart_money_tracker/core/services/analytics_service.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';

class PermissionDisclosureScreen extends HookConsumerWidget {
  const PermissionDisclosureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMounted = useIsMounted();

    Future<void> _saveDisclosure() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('permissions_disclosed', true);
      
      final user = ref.read(authStateProvider).value;
      if (user != null && !user.isAnonymous) {
        await ref.read(authRepositoryProvider).saveUserSettings(
          user.id,
          {'permissions_disclosed': true},
        );
      }
    }

    // Google Play Policy Compliance:
    // 1. Prominent Disclosure purpose: Explain clearly what data is accessed (SMS messages) and how it is used (auto transaction detection).
    // 2. Consent BEFORE request: Runtime permission request occurs ONLY after user provides explicit consent by clicking "Continue" on the disclosure UI.
    // 3. No Silent Scanning: No SMS reading or processing is initialized before both consent and system permission are granted.
    // 4. Denied Flow: User may reject runtime permission, in which case the app continues smoothly to Dashboard without SMS scanning features.
    Future<void> handleContinue() async {
      // Persist that prominent disclosure onboarding is completed
      AnalyticsService.logEvent('sms_permission_granted');
      await _saveDisclosure();
      
      if (isMounted()) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      }
    }

    Future<void> handleNotNow() async {
      // Save onboarding flag but don't request permissions or start any SMS parsing
      AnalyticsService.logEvent('sms_permission_denied');
      await _saveDisclosure();
      
      if (isMounted()) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      }
    }

    return SmsDisclosureScreen(
      onContinue: handleContinue,
      onNotNow: handleNotNow,
    );
  }
}

