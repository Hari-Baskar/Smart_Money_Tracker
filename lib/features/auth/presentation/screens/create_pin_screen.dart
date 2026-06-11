import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/auth/presentation/widgets/pin_numpad.dart';
import 'package:smart_money_tracker/core/services/security_service.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';

class CreatePinScreen extends HookConsumerWidget {
  const CreatePinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pin = useState('');
    final confirmPin = useState('');
    final isConfirming = useState(false);
    final requireOnLaunch = useState(true);
    final isSaving = useState(false);
    final isMounted = useIsMounted();

    void handleNumberPress(String number) {
      if (isConfirming.value) {
        if (confirmPin.value.length < 6) {
          confirmPin.value += number;
        }
      } else {
        if (pin.value.length < 6) {
          pin.value += number;
        }
      }
    }

    void handleDelete() {
      if (isConfirming.value) {
        if (confirmPin.value.isNotEmpty) {
          confirmPin.value = confirmPin.value.substring(
            0,
            confirmPin.value.length - 1,
          );
        }
      } else {
        if (pin.value.isNotEmpty) {
          pin.value = pin.value.substring(0, pin.value.length - 1);
        }
      }
    }

    Future<void> handleComplete() async {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      isSaving.value = true;
      try {
        final securityService = ref.read(securityServiceProvider);

        // 1. Save locally
        await securityService.saveLocalPin(pin.value, requireOnLaunch.value);

        // 2. Save hash in cloud
        final hash = securityService.hashPin(pin.value);
        await ref.read(authRepositoryProvider).saveUserSettings(user.id, {
          'pin_hash': hash,
          'require_pin_on_launch': requireOnLaunch.value,
        });

        if (isMounted()) {
          context.pop(true); // Return success
        }
      } catch (e) {
        if (isMounted()) {
          AppToast.show(context, 'Failed to save PIN: $e', isError: true);
        }
      } finally {
        if (isMounted()) {
          isSaving.value = false;
        }
      }
    }

    // Auto-advance or complete when 4 digits are entered
    useEffect(() {
      if (!isConfirming.value && pin.value.length == 6) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (isMounted()) {
            isConfirming.value = true;
          }
        });
      } else if (isConfirming.value && confirmPin.value.length == 6) {
        if (pin.value == confirmPin.value) {
          // PINs match, but we let them press "Save PIN" button instead of auto-saving immediately
          // because they need to see and toggle the checkbox.
        } else {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (isMounted()) {
              AppToast.show(context, 'PINs do not match. Try again.', isError: true);
              confirmPin.value = '';
              isConfirming.value = false;
              pin.value = '';
            }
          });
        }
      }
      return null;
    }, [pin.value, confirmPin.value, isConfirming.value]);

    final currentPinLength = isConfirming.value
        ? confirmPin.value.length
        : pin.value.length;
    final title = isConfirming.value
        ? 'Confirm your PIN'
        : 'Create a 6-digit PIN';
    final subtitle = isConfirming.value
        ? 'Re-enter the PIN to confirm'
        : 'This PIN secures your financial data';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.w24),
          child: Column(
            children: [
              SizedBox(height: AppSizes.h32),
              Icon(
                Icons.lock_outline_rounded,
                size: AppSizes.screenHeight * 0.05,
                color: AppColors.primary,
              ),
              SizedBox(height: AppSizes.h16),
              Text(title, style: AppTextStyles.heading(context)),
              SizedBox(height: AppSizes.h8),
              Text(
                subtitle,
                style: AppTextStyles.body(
                  context,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (!isConfirming.value) ...[
                SizedBox(height: AppSizes.h8),
                Text(
                  'Warning: This PIN cannot be reset or recovered if forgotten.',
                  style: AppTextStyles.small(context, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],

              SizedBox(height: AppSizes.h48),

              // PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < currentPinLength;
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: AppSizes.w8),
                    width: AppSizes.w(16),
                    height: AppSizes.w(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.2),
                    ),
                  );
                }),
              ),

              const Spacer(),

              // Checkbox and Save button (only shown when confirming and pins match)
              if (isConfirming.value &&
                  confirmPin.value.length == 6 &&
                  pin.value == confirmPin.value) ...[
                Container(
                  padding: EdgeInsets.all(AppSizes.w16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: AppSizes.boxBorderRadius,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: requireOnLaunch.value,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          if (val != null) requireOnLaunch.value = val;
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Require PIN every time I open the app',
                          style: AppTextStyles.body(context),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSizes.h16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving.value ? null : handleComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
                    ),
                    child: isSaving.value
                        ? SizedBox(
                            height: AppSizes.r20,
                            width: AppSizes.r20,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Save PIN',
                            style: AppTextStyles.body(
                              context,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: AppSizes.h24),
              ] else ...[
                PinNumpad(
                  onNumberPressed: handleNumberPress,
                  onDeletePressed: handleDelete,
                ),
                SizedBox(height: AppSizes.h32),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
