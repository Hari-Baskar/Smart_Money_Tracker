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
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:uuid/uuid.dart';
import '../providers/subcategory_provider.dart';
import 'package:smart_money_tracker/core/constants/payment_constants.dart';
import '../widgets/bank_picker_widget.dart';
import '../widgets/payment_method_picker_widget.dart';
import '../widgets/txn_category_picker_sheet.dart';
import '../widgets/txn_subcategory_picker_sheet.dart';
import 'package:smart_money_tracker/core/services/analytics_service.dart';

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
    final selectedBankId = useState<String?>(null);
    final customBankController = useTextEditingController();
    final selectedPaymentMethodId = useState<String?>(null);
    final customPaymentController = useTextEditingController();

    // Register rebuild triggers for custom bank and payment method changes
    final _ = selectedBankId.value;
    final __ = selectedPaymentMethodId.value;

    useEffect(() {
      AnalyticsService.logScreenView('AddTransactionScreen');
      return null;
    }, const []);

    Future<void> selectDate() async {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedDate.value,
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
        builder: (context, child) {
          final isDark = AppColors.isDark(context);
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark
                  ? const ColorScheme.dark(
                      primary: Color(0xFF078644),
                      onPrimary: AppColors.white,
                      primaryContainer: Color(0xFF004D25),
                      onPrimaryContainer: AppColors.white,
                      surface: AppColors.surfaceDark,
                      onSurface: AppColors.white,
                    )
                  : const ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: AppColors.white,
                      onSurface: AppColors.textLight,
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
            final isDark = AppColors.isDark(context);
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark
                    ? const ColorScheme.dark(
                        primary: Color(0xFF078644),
                        onPrimary: AppColors.white,
                        primaryContainer: Color(0xFF004D25),
                        onPrimaryContainer: AppColors.white,
                        surface: AppColors.surfaceDark,
                        onSurface: AppColors.white,
                      )
                    : const ColorScheme.light(
                        primary: AppColors.primary,
                        onPrimary: AppColors.white,
                        onSurface: AppColors.textLight,
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
          AppToast.show(context, 'Login required', isError: true);
          return;
        }

        final subcategories = ref.read(subcategoriesProvider).value ?? const [];

        String categoryId = selectedCategory.value;
        String subcategoryId = selectedSubcategory.value;

        final finalBankId = selectedBankId.value;

        final finalPaymentMethodId = selectedPaymentMethodId.value;

        final transaction = TransactionModel(
          id: const Uuid().v4(),
          amount: double.parse(amountController.text),
          merchant: merchantController.text,
          date: selectedDate.value,
          type: selectedType.value,
          category: categoryId,
          subcategory: subcategoryId,
          rawSms: 'Manual Entry',
          bankId: finalBankId?.isEmpty == true ? null : finalBankId,
          paymentMethodId: finalPaymentMethodId?.isEmpty == true
              ? null
              : finalPaymentMethodId,
        );

        await ref
            .read(transactionRepositoryProvider)
            .saveTransaction(userId, transaction);

        if (isMounted()) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (isMounted()) {
          AppToast.show(context, 'Error', isError: true);
        }
      } finally {
        if (isMounted()) isLoading.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).colorScheme.onBackground,
            size: AppSizes.r20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Add Transaction', style: AppTextStyles.heading(context)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: isLoading.value ? null : submitForm,
            child: isLoading.value
                ? SizedBox(
                    width: AppSizes.r20,
                    height: AppSizes.r20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Text(
                    'Save',
                    style: AppTextStyles.body(
                      context,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.w12),
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
                      style: AppTextStyles.body(
                        context,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: AppSizes.h8),
                    IntrinsicWidth(
                      child: TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading(context),
                        decoration: InputDecoration(
                          prefixStyle: AppTextStyles.heading(context),
                          border: InputBorder.none,
                          hintText: 'Amount',
                          hintStyle: AppTextStyles.heading(
                            context,
                            color: Theme.of(context).colorScheme.surfaceVariant,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Enter amount';
                          if (double.tryParse(value) == null)
                            return 'Enter valid number';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSizes.h32),

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
                      selectedCategory,
                      selectedSubcategory,
                    ),
                  ),
                  SizedBox(width: AppSizes.w16),
                  Expanded(
                    child: _buildTypeButton(
                      context,
                      'Income',
                      TransactionType.credit,
                      AppColors.success,
                      selectedType,
                      selectedCategory,
                      selectedSubcategory,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.h32),

              // Merchant Input
              _buildLabel(context, 'Merchant / Description'),
              SizedBox(height: AppSizes.h8),
              _buildTextField(
                context,
                controller: merchantController,
                hint: 'e.g. Starbucks, Rent, etc.',
                icon: Icons.storefront_rounded,
                validator: null,
              ),
              SizedBox(height: AppSizes.h24),

              // Category Selector
              _buildLabel(context, 'Category'),
              SizedBox(height: AppSizes.h8),
              _buildCategoryPicker(
                context,
                ref,
                selectedCategory,
                selectedSubcategory,
                selectedType,
              ),
              SizedBox(height: AppSizes.h24),

              // Subcategory Selector
              _buildLabel(context, 'Subcategory'),
              SizedBox(height: AppSizes.h8),
              _buildSubcategoryPicker(
                context,
                ref,
                selectedCategory,
                selectedSubcategory,
                selectedType,
              ),
              SizedBox(height: AppSizes.h24),

              // Bank Selector
              _buildLabel(context, 'Bank (Optional)'),
              SizedBox(height: AppSizes.h8),
              _buildBankPicker(context, selectedBankId, customBankController),
              SizedBox(height: AppSizes.h24),

              // Payment Method Selector
              _buildLabel(context, 'Payment Method (Optional)'),
              SizedBox(height: AppSizes.h8),
              _buildPaymentMethodPicker(
                context,
                selectedPaymentMethodId,
                customPaymentController,
              ),
              SizedBox(height: AppSizes.h24),

              // Date Selector
              _buildLabel(context, 'Date'),
              SizedBox(height: AppSizes.h8),
              _buildDateField(context, selectedDate, selectDate),
              SizedBox(height: AppSizes.h40),
              SizedBox(height: AppSizes.h40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: AppTextStyles.body(
        context,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainerLowest(context),
        borderRadius: AppSizes.boxBorderRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.isDark(context)
                ? AppColors.black.withOpacity(0.2)
                : AppColors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.isDark(context)
              ? AppColors.white.withOpacity(0.05)
              : AppColors.black.withOpacity(0.03),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        style: AppTextStyles.body(context),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body(
            context,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          prefixIcon: Icon(icon, color: AppColors.primary, size: AppSizes.r20),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.all(AppSizes.r16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildCategoryPicker(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<String> selectedCategory,
    ValueNotifier<String> selectedSubcategory,
    ValueNotifier<TransactionType> selectedType,
  ) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        final isIncome = selectedType.value == TransactionType.credit;
        final displayCategoryName = categories.firstWhere(
          (c) => c.id == selectedCategory.value,
          orElse: () => CategoryModel(id: selectedCategory.value, name: selectedCategory.value),
        ).name;

        final catColor = AppColors.getCategoryColor(displayCategoryName);
        final catBg = AppColors.getCategoryBgColor(
          context,
          displayCategoryName,
        );


        return InkWell(
          onTap: () => showModalBottomSheet(
            context: context,
            backgroundColor: AppColors.transparent,
            isScrollControlled: true,
            builder: (context) => TxnCategoryPickerSheet(
              selectedCategory: selectedCategory,
              selectedSubcategory: selectedSubcategory,
              isIncome: isIncome,
            ),
          ),
          borderRadius: AppSizes.boxBorderRadius,
          child: Container(
            padding: EdgeInsets.all(AppSizes.r16),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceContainerLowest(context),
              borderRadius: AppSizes.boxBorderRadius,
              boxShadow: [
                BoxShadow(
                  color: AppColors.isDark(context)
                      ? AppColors.black.withOpacity(0.2)
                      : AppColors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: AppColors.isDark(context)
                    ? AppColors.white.withOpacity(0.05)
                    : AppColors.black.withOpacity(0.03),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: AppSizes.r(36),
                  height: AppSizes.r(36),
                  decoration: BoxDecoration(
                    color: catBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppColors.getCategoryIcon(displayCategoryName),
                    color: catColor,
                    size: AppSizes.r20,
                  ),
                ),
                SizedBox(width: AppSizes.w16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category',
                        style: AppTextStyles.body(
                          context,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: AppSizes.h(2)),
                      Text(
                        displayCategoryName.length > 13
                            ? '${displayCategoryName.substring(0, 11)}...'
                            : displayCategoryName,
                        style: AppTextStyles.body(context),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  size: AppSizes.r20,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSubcategoryPicker(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<String> selectedCategory,
    ValueNotifier<String> selectedSubcategory,
    ValueNotifier<TransactionType> selectedType,
  ) {
    final subcategoriesAsync = ref.watch(subcategoriesProvider);

    return subcategoriesAsync.when(
      data: (allSubs) {
        final isIncome = selectedType.value == TransactionType.credit;
        final filteredSubs = allSubs
            .where(
              (s) =>
                  s.parentCategoryId == selectedCategory.value &&
                  s.isIncome == isIncome,
            )
            .toList();

        final displaySubcategoryName = allSubs.firstWhere(
          (s) => s.id == selectedSubcategory.value,
          orElse: () => SubcategoryModel(id: selectedSubcategory.value, name: selectedSubcategory.value, parentCategoryId: selectedCategory.value),
        ).name;

        final categoriesAsync = ref.read(categoriesProvider);
        final categories = categoriesAsync.value ?? const [];
        final displayCategoryName = categories.firstWhere(
          (c) => c.id == selectedCategory.value,
          orElse: () => CategoryModel(id: selectedCategory.value, name: selectedCategory.value),
        ).name;

        final catColor = AppColors.getCategoryColor(displayCategoryName);
        final catBg = AppColors.getCategoryBgColor(
          context,
          displayCategoryName,
        );

        return InkWell(
          onTap: () => showModalBottomSheet(
            context: context,
            backgroundColor: AppColors.transparent,
            isScrollControlled: true,
            builder: (context) => TxnSubcategoryPickerSheet(
              selectedSubcategory: selectedSubcategory,
              parentCategory: selectedCategory.value,
              isIncome: isIncome,
            ),
          ),
          borderRadius: AppSizes.boxBorderRadius,
          child: Container(
            padding: EdgeInsets.all(AppSizes.r16),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceContainerLowest(context),
              borderRadius: AppSizes.boxBorderRadius,
              boxShadow: [
                BoxShadow(
                  color: AppColors.isDark(context)
                      ? AppColors.black.withOpacity(0.2)
                      : AppColors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: AppColors.isDark(context)
                    ? AppColors.white.withOpacity(0.05)
                    : AppColors.black.withOpacity(0.03),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: AppSizes.r(36),
                  height: AppSizes.r(36),
                  decoration: BoxDecoration(
                    color: catBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.subdirectory_arrow_right_rounded,
                    color: catColor,
                    size: AppSizes.r20,
                  ),
                ),
                SizedBox(width: AppSizes.w16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subcategory',
                        style: AppTextStyles.body(
                          context,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: AppSizes.h(2)),
                      Text(
                        displaySubcategoryName,
                        style: AppTextStyles.body(context),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  size: AppSizes.r20,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }



  Widget _buildDateField(
    BuildContext context,
    ValueNotifier<DateTime> selectedDate,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSizes.r16),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceContainerLowest(context),
          borderRadius: AppSizes.boxBorderRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.isDark(context)
                  ? AppColors.black.withOpacity(0.2)
                  : AppColors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppColors.isDark(context)
                ? AppColors.white.withOpacity(0.05)
                : AppColors.black.withOpacity(0.03),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: AppSizes.r20,
            ),
            SizedBox(width: AppSizes.w12),
            Text(
              DateFormat('MMM dd, yyyy • hh:mm a').format(selectedDate.value),
              style: AppTextStyles.body(context),
            ),
            const Spacer(),
            Icon(
              Icons.edit_calendar_rounded,
              color: AppColors.primary,
              size: AppSizes.r20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    BuildContext context,
    String label,
    TransactionType type,
    Color color,
    ValueNotifier<TransactionType> selectedType,
    ValueNotifier<String> selectedCategory,
    ValueNotifier<String> selectedSubcategory,
  ) {
    final isSelected = selectedType.value == type;
    return GestureDetector(
      onTap: () {
        if (selectedType.value != type) {
          selectedType.value = type;
          if (type == TransactionType.credit) {
            selectedCategory.value = 'Salary';
            selectedSubcategory.value = 'General';
          } else {
            selectedCategory.value = 'Other';
            selectedSubcategory.value = 'General';
          }
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.transparent,
          borderRadius: AppSizes.cardBorderRadius,
          border: Border.all(
            color: isSelected
                ? color
                : Theme.of(context).colorScheme.surfaceVariant,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.body(
              context,
              color: isSelected
                  ? color
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankPicker(
    BuildContext context,
    ValueNotifier<String?> selectedBankId,
    TextEditingController customBankController,
  ) {
    return BankPickerWidget(
      selectedBankId: selectedBankId,
      customBankController: customBankController,
    );
  }

  Widget _buildPaymentMethodPicker(
    BuildContext context,
    ValueNotifier<String?> selectedPaymentMethodId,
    TextEditingController customPaymentController,
  ) {
    return PaymentMethodPickerWidget(
      selectedPaymentMethodId: selectedPaymentMethodId,
      customPaymentController: customPaymentController,
    );
  }
}
