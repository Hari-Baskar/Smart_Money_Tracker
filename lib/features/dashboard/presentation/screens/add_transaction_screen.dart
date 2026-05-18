import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import '../providers/subcategory_provider.dart';

class AddTransactionScreen extends HookConsumerWidget {
  const AddTransactionScreen({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final amountController = useTextEditingController();
    final merchantController = useTextEditingController();
    final selectedDate = useState(DateTime.now());
    final selectedCategory = useState('Other');
    final selectedSubcategory = useState('General');
    final selectedType = useState(TransactionType.debit);
    final isLoading = useState(false);
    final isMounted = useIsMounted();

    Future<void> selectDate() async {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedDate.value,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                onSurface: AppColors.isDark(context) ? Colors.white : AppColors.textLight,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedDate != null) {
        if (!isMounted()) return;
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(selectedDate.value),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  onSurface: AppColors.isDark(context) ? Colors.white : AppColors.textLight,
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedTime != null) {
          selectedDate.value = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        }
      }
    }

    Future<void> submitForm() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;

      try {
        final authState = ref.read(authStateProvider);
        final userId = authState.value?.id;

        if (userId == null) {
          Fluttertoast.showToast(msg: 'Login required');
          return;
        }

        final transaction = TransactionModel(
          id: const Uuid().v4(),
          amount: double.parse(amountController.text),
          merchant: merchantController.text,
          date: selectedDate.value,
          type: selectedType.value,
          category: selectedCategory.value,
          subcategory: selectedSubcategory.value,
          rawSms: 'Manual Entry',
        );

        await ref.read(transactionRepositoryProvider).saveTransaction(userId, transaction);

        if (isMounted()) {
          Navigator.pop(context);
          Fluttertoast.showToast(msg: 'Added');
        }
      } catch (e) {
        if (isMounted()) {
          Fluttertoast.showToast(msg: 'Error');
        }
      } finally {
        if (isMounted()) isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onBackground, size: 20.r),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Transaction',
          style: AppTextStyles.headline(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Input
              Center(
                child: Column(
                  children: [
                    Text(
                      'How much?',
                      style: AppTextStyles.small(context, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    SizedBox(height: 8.h),
                    IntrinsicWidth(
                      child: TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.display(context),
                        decoration: InputDecoration(
                          prefixText: '₹',
                          prefixStyle: AppTextStyles.display(context),
                          border: InputBorder.none,
                          hintText: '0',
                          hintStyle: AppTextStyles.display(context, color: Theme.of(context).colorScheme.surfaceVariant),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter amount';
                          if (double.tryParse(value) == null) return 'Enter valid number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.h),

              // Transaction Type Selector
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      context,
                      'Expense',
                      TransactionType.debit,
                      AppColors.error,
                      selectedType,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildTypeButton(
                      context,
                      'Income',
                      TransactionType.credit,
                      AppColors.success,
                      selectedType,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),

              // Merchant Input
              _buildLabel(context, 'Merchant / Description'),
              SizedBox(height: 8.h),
              _buildTextField(
                context,
                controller: merchantController,
                hint: 'e.g. Starbucks, Rent, etc.',
                icon: Icons.storefront_rounded,
                validator: (value) => value == null || value.isEmpty ? 'Enter merchant name' : null,
              ),
              SizedBox(height: 24.h),

              // Category Selector
              _buildLabel(context, 'Category'),
              SizedBox(height: 8.h),
              _buildDropdownField(context, ref, selectedCategory, selectedSubcategory),
              SizedBox(height: 24.h),

              // Subcategory Selector
              _buildLabel(context, 'Subcategory'),
              SizedBox(height: 8.h),
              _buildSubcategoryPicker(context, ref, selectedCategory, selectedSubcategory),
              SizedBox(height: 24.h),

              // Date Selector
              _buildLabel(context, 'Date'),
              SizedBox(height: 8.h),
              _buildDateField(context, selectedDate, selectDate),
              SizedBox(height: 48.h),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: isLoading.value ? null : submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSizes.cardBorderRadius,
                    ),
                    elevation: 0,
                  ),
                  child: isLoading.value
                      ? SizedBox(
                          height: 24.r,
                          width: 24.r,
                          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Save Transaction',
                          style: AppTextStyles.body(context, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: AppTextStyles.small(context, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: AppTextStyles.body(context),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.small(context, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20.r),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.all(16.r),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<String> selectedCategory,
    ValueNotifier<String> selectedSubcategory,
  ) {
    final subcategoriesAsync = ref.watch(subcategoriesProvider);

    return subcategoriesAsync.when(
      data: (allSubs) {
        // Extract all unique parent categories
        final categories = allSubs.map((s) => s.parentCategory).toSet().toList();
        categories.sort();

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: categories.contains(selectedCategory.value)
                  ? selectedCategory.value
                  : categories.first,
              isExpanded: true,
              dropdownColor: Theme.of(context).colorScheme.surface,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primary,
              ),
              items: [
                ...categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category, style: AppTextStyles.body(context)),
                  );
                }),
                const DropdownMenuItem<String>(
                  value: 'ADD_NEW_CAT',
                  child: Text(
                    '+ Add Custom Category...',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == 'ADD_NEW_CAT') {
                  _showAddCategoryDialog(
                    context,
                    ref,
                    selectedCategory,
                    selectedSubcategory,
                  );
                } else if (value != null) {
                  selectedCategory.value = value;
                  selectedSubcategory.value = 'General';
                }
              },
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSubcategoryPicker(BuildContext context, WidgetRef ref, ValueNotifier<String> selectedCategory, ValueNotifier<String> selectedSubcategory) {
    final subcategoriesAsync = ref.watch(subcategoriesProvider);

    return subcategoriesAsync.when(
      data: (allSubs) {
        final filteredSubs = allSubs
            .where((s) => s.parentCategory == selectedCategory.value)
            .map((s) => s.name)
            .toSet()
            .toList();

        if (!filteredSubs.contains(selectedSubcategory.value)) {
          filteredSubs.add(selectedSubcategory.value);
        }

        filteredSubs.sort();

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedSubcategory.value,
              isExpanded: true,
              dropdownColor: Theme.of(context).colorScheme.surface,
              icon: const Icon(Icons.subdirectory_arrow_right_rounded, color: AppColors.primary),
              items: [
                ...filteredSubs.map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s, style: AppTextStyles.body(context)),
                  ),
                ),
                const DropdownMenuItem(
                  value: 'ADD_NEW',
                  child: Text(
                    '+ Add Custom...',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val == 'ADD_NEW') {
                  _showAddSubcategoryDialog(context, ref, selectedCategory.value, selectedSubcategory);
                } else if (val != null) {
                  selectedSubcategory.value = val;
                }
              },
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error loading subcategories'),
    );
  }

  void _showAddCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<String> selectedCategory,
    ValueNotifier<String> selectedSubcategory,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('New Main Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter name (e.g. Business, Hobby)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final name = controller.text.trim();
                // To add a main category, we create a 'General' subcategory under it
                await ref
                    .read(subcategoriesProvider.notifier)
                    .addSubcategory('General', name);
                selectedCategory.value = name;
                selectedSubcategory.value = 'General';
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddSubcategoryDialog(BuildContext context, WidgetRef ref, String category, ValueNotifier<String> selectedSubcategory) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('New Subcategory'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter name (e.g. Netflix, Gym)',
            labelText: 'For $category',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final name = controller.text.trim();
                await ref
                    .read(subcategoriesProvider.notifier)
                    .addSubcategory(name, category);
                selectedSubcategory.value = name;
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(BuildContext context, ValueNotifier<DateTime> selectedDate, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20.r),
            SizedBox(width: 12.w),
            Text(
              DateFormat('MMM dd, yyyy • hh:mm a').format(selectedDate.value),
              style: AppTextStyles.body(context),
            ),
            const Spacer(),
            Icon(Icons.edit_calendar_rounded, color: AppColors.primary, size: 20.r),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(BuildContext context, String label, TransactionType type, Color color, ValueNotifier<TransactionType> selectedType) {
    final isSelected = selectedType.value == type;
    return GestureDetector(
      onTap: () => selectedType.value = type,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: AppSizes.cardBorderRadius,
          border: Border.all(
            color: isSelected ? color : Theme.of(context).colorScheme.surfaceVariant,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.small(
              context,
              color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
