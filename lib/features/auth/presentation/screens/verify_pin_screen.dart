import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/auth/presentation/widgets/pin_numpad.dart';
import 'package:smart_money_tracker/core/services/security_service.dart';

class VerifyPinScreen extends HookConsumerWidget {
  final String targetHash;
  final String title;
  final String subtitle;

  const VerifyPinScreen({
    super.key,
    required this.targetHash,
    this.title = 'Enter App PIN',
    this.subtitle = 'Please enter your PIN to continue',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pin = useState('');
    final isError = useState(false);
    final isMounted = useIsMounted();

    void handleNumberPress(String number) {
      if (isError.value) {
        isError.value = false;
        pin.value = '';
      }
      if (pin.value.length < 6) {
        pin.value += number;
      }
    }

    void handleDelete() {
      if (isError.value) {
        isError.value = false;
        pin.value = '';
      } else if (pin.value.isNotEmpty) {
        pin.value = pin.value.substring(0, pin.value.length - 1);
      }
    }

    useEffect(() {
      if (pin.value.length == 6) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!isMounted()) return;

          final securityService = ref.read(securityServiceProvider);
          final isValid = securityService.verifyPinHash(pin.value, targetHash);

          if (isValid) {
            context.pop(pin.value);
          } else {
            isError.value = true;
          }
        });
      }
      return null;
    }, [pin.value]);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.w24),
          child: Column(
            children: [
              SizedBox(height: AppSizes.h16),
              Icon(
                Icons.lock_rounded,
                size: AppSizes.screenHeight * 0.05,
                color: isError.value ? Colors.red : AppColors.primary,
              ),
              SizedBox(height: AppSizes.h16),
              Text(
                title,
                style: AppTextStyles.heading(context),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSizes.h8),
              Text(
                isError.value ? 'Incorrect PIN. Please try again.' : subtitle,
                style: AppTextStyles.body(
                  context,
                  color: isError.value
                      ? Colors.red
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: AppSizes.h48),

              // PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < pin.value.length;
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: AppSizes.w8),
                    width: AppSizes.w(16),
                    height: AppSizes.w(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isError.value
                          ? Colors.red
                          : (isFilled
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.2)),
                    ),
                  );
                }),
              ),

              const Spacer(),

              PinNumpad(
                onNumberPressed: handleNumberPress,
                onDeletePressed: handleDelete,
              ),
              SizedBox(height: AppSizes.h16),
            ],
          ),
        ),
      ),
    );
  }
}
