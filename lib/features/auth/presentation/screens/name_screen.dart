import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';

class NameScreen extends HookConsumerWidget {
  const NameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final isMounted = useIsMounted();
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AsyncLoading;

    Future<void> saveName() async {
      final name = nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter your name")),
        );
        return;
      }

      try {
        await ref.read(authNotifierProvider.notifier).updateUserName(name);
        if (isMounted()) {
          context.go('/dashboard');
        }
      } catch (e) {
        if (isMounted()) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60.h),
              FadeInDown(
                child: Text(
                  'Almost There!',
                  style: AppTextStyles.headline(
                    context,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              FadeInDown(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'What should we call you?',
                  style: AppTextStyles.display(
                    context,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              FadeInDown(
                delay: const Duration(milliseconds: 300),
                child: Text(
                  'Enter your name to personalize your experience.',
                  style: AppTextStyles.body(
                    context,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: 48.h),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: TextField(
                  controller: nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
              ),
              const Spacer(),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : saveName,
                    child: isLoading
                        ? SizedBox(
                            height: 20.r,
                            width: 20.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Continue'),
                  ),
                ),
              ),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}

