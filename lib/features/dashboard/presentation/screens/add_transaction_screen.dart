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

        // Find Category ID/Name
        String categoryId = selectedCategory.value;
        if (!_isDefaultCategory(categoryId)) {
          final catMatch = subcategories.firstWhere(
            (sub) =>
                sub.isCustom &&
                sub.name == 'General' &&
                sub.parentCategory == selectedCategory.value,
            orElse: () =>
                SubcategoryModel(id: '', name: '', parentCategory: ''),
          );
          if (catMatch.id.isNotEmpty) {
            categoryId = catMatch.id;
          }
        }

        // Find Subcategory ID
        String subcategoryId = selectedSubcategory.value;
        final subMatch = subcategories.firstWhere(
          (sub) =>
              sub.name == selectedSubcategory.value &&
              (sub.parentCategory == selectedCategory.value ||
                  sub.parentCategory == categoryId),
          orElse: () => SubcategoryModel(id: '', name: '', parentCategory: ''),
        );
        if (subMatch.id.isNotEmpty) {
          subcategoryId = subMatch.id;
        }

        final finalBankId = selectedBankId.value == 'custom'
            ? 'custom:${customBankController.text.trim()}'
            : selectedBankId.value;

        final finalPaymentMethodId = selectedPaymentMethodId.value == 'custom'
            ? 'custom:${customPaymentController.text.trim()}'
            : selectedPaymentMethodId.value;

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
          AppToast.show(context, 'Added');
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
                          prefixText: '₹',
                          prefixStyle: AppTextStyles.heading(context),
                          border: InputBorder.none,
                          hintText: '0',
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
    final subcategoriesAsync = ref.watch(subcategoriesProvider);

    return subcategoriesAsync.when(
      data: (allSubs) {
        final isIncome = selectedType.value == TransactionType.credit;
        final categories = allSubs
            .where((s) => s.isIncome == isIncome)
            .map((s) => s.parentCategory)
            .toSet()
            .toList();
        categories.sort();

        final catColor = AppColors.getCategoryColor(selectedCategory.value);
        final catBg = AppColors.getCategoryBgColor(
          context,
          selectedCategory.value,
        );

        return InkWell(
          onTap: () => showModalBottomSheet(
            context: context,
            backgroundColor: AppColors.transparent,
            isScrollControlled: true,
            builder: (context) => TxnCategoryPickerSheet(
              selectedCategory: selectedCategory,
              selectedSubcategory: selectedSubcategory,
              categories: categories,
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
                    AppColors.getCategoryIcon(selectedCategory.value),
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
                        selectedCategory.value.length > 13
                            ? '${selectedCategory.value.substring(0, 11)}...'
                            : selectedCategory.value,
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
                  s.parentCategory == selectedCategory.value &&
                  s.isIncome == isIncome,
            )
            .toList();

        if (!filteredSubs.any((s) => s.name == selectedSubcategory.value)) {
          filteredSubs.add(
            SubcategoryModel(
              id: 'temp',
              name: selectedSubcategory.value,
              parentCategory: selectedCategory.value,
              isCustom: false,
              isIncome: isIncome,
            ),
          );
        }

        filteredSubs.sort((a, b) => a.name.compareTo(b.name));

        final catColor = AppColors.getCategoryColor(selectedCategory.value);
        final catBg = AppColors.getCategoryBgColor(
          context,
          selectedCategory.value,
        );

        return InkWell(
          onTap: () => showModalBottomSheet(
            context: context,
            backgroundColor: AppColors.transparent,
            isScrollControlled: true,
            builder: (context) => TxnSubcategoryPickerSheet(
              selectedSubcategory: selectedSubcategory,
              parentCategory: selectedCategory.value,
              subcategories: filteredSubs,
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
                        selectedSubcategory.value,
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

  void _showCategoryBottomSheet(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<String> selectedCategory,
    ValueNotifier<String> selectedSubcategory,
    List<String> categories,
    ValueNotifier<TransactionType> selectedType,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: AppSizes.boxBorderRadius,
          ),
          padding: EdgeInsets.fromLTRB(
            AppSizes.w24,
            AppSizes.h12,
            AppSizes.w24,
            AppSizes.h24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: AppSizes.w(48),
                  height: AppSizes.h4,
                  margin: EdgeInsets.only(bottom: AppSizes.h20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.white.withOpacity(0.12)
                        : AppColors.black.withOpacity(0.08),
                    borderRadius: AppSizes.boxBorderRadius,
                  ),
                ),
              ),
              Text('Select Category', style: AppTextStyles.heading(context)),
              SizedBox(height: AppSizes.h16),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSizes.w12,
                    mainAxisSpacing: AppSizes.h12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == categories.length) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showAddCategoryDialog(
                            context,
                            ref,
                            selectedCategory,
                            selectedSubcategory,
                            selectedType,
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.transparent,
                            borderRadius: AppSizes.boxBorderRadius,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.white.withOpacity(0.15)
                                  : AppColors.black.withOpacity(0.1),
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: AppSizes.r(44),
                                height: AppSizes.r(44),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add_rounded,
                                  color: AppColors.primary,
                                  size: AppSizes.r24,
                                ),
                              ),
                              SizedBox(height: AppSizes.h8),
                              Text(
                                'Add Custom',
                                style: AppTextStyles.body(
                                  context,
                                  color: AppColors.primary,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final cat = categories[index];
                    final isSelected = selectedCategory.value == cat;
                    final catColor = AppColors.getCategoryColor(cat);
                    final catBg = AppColors.getCategoryBgColor(context, cat);
                    final isCustom = !_isDefaultCategory(cat);

                    return GestureDetector(
                      onTap: () {
                        selectedCategory.value = cat;
                        selectedSubcategory.value = 'General';
                        Navigator.pop(context);
                      },
                      onLongPress: isCustom
                          ? () {
                              Navigator.pop(context);
                              _showManageCategorySheet(
                                context,
                                ref,
                                cat,
                                selectedCategory,
                                selectedSubcategory,
                              );
                            }
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? catBg
                              : (isDark
                                    ? AppColors.surfaceContainerLowestDark
                                    : AppColors.backgroundLight),
                          borderRadius: AppSizes.boxBorderRadius,
                          border: Border.all(
                            color: isSelected
                                ? catColor
                                : (isDark
                                      ? AppColors.white.withOpacity(0.05)
                                      : AppColors.black.withOpacity(0.04)),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: catColor.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: AppSizes.r(44),
                                    height: AppSizes.r(44),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? (isDark
                                                ? AppColors.black.withOpacity(
                                                    0.2,
                                                  )
                                                : AppColors.white)
                                          : catBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      AppColors.getCategoryIcon(cat),
                                      color: catColor,
                                      size: AppSizes.r24,
                                    ),
                                  ),
                                  SizedBox(height: AppSizes.h8),
                                  Text(
                                    cat.length > 13
                                        ? '${cat.substring(0, 11)}...'
                                        : cat,
                                    style: AppTextStyles.body(
                                      context,
                                      color: isSelected
                                          ? (isDark
                                                ? AppColors.white
                                                : catColor)
                                          : AppColors.getText(context),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isDefaultCategory(String category) {
    return const [
      'Food',
      'Travel',
      'Shopping',
      'Bills',
      'Entertainment',
      'Health',
      'Investment',
      'Other',
      'Salary',
    ].contains(category);
  }

  void _showManageCategorySheet(
    BuildContext context,
    WidgetRef ref,
    String categoryName,
    ValueNotifier<String> selectedCategory,
    ValueNotifier<String> selectedSubcategory,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: AppSizes.boxBorderRadius,
          ),
          padding: EdgeInsets.fromLTRB(
            AppSizes.w24,
            AppSizes.h12,
            AppSizes.w24,
            AppSizes.h24,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: AppSizes.w(48),
                    height: AppSizes.h4,
                    margin: EdgeInsets.only(bottom: AppSizes.h20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.white.withOpacity(0.12)
                          : AppColors.black.withOpacity(0.08),
                      borderRadius: AppSizes.boxBorderRadius,
                    ),
                  ),
                ),
                Text('Manage Category', style: AppTextStyles.heading(context)),
                Text(
                  categoryName,
                  style: AppTextStyles.body(
                    context,
                    color: AppColors.getTextMuted(context),
                  ),
                ),
                SizedBox(height: AppSizes.h24),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(AppSizes.r8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: AppColors.primary,
                      size: AppSizes.r20,
                    ),
                  ),
                  title: Text(
                    'Rename Category',
                    style: AppTextStyles.body(context),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showRenameCategoryDialog(
                      context,
                      ref,
                      categoryName,
                      selectedCategory,
                      selectedSubcategory,
                    );
                  },
                ),
                Divider(
                  color: isDark
                      ? AppColors.white.withOpacity(0.05)
                      : AppColors.black.withOpacity(0.04),
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(AppSizes.r8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_forever_rounded,
                      color: AppColors.error,
                      size: AppSizes.r20,
                    ),
                  ),
                  title: Text(
                    'Delete Category',
                    style: AppTextStyles.body(context, color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteCategoryDialog(
                      context,
                      ref,
                      categoryName,
                      selectedCategory,
                      selectedSubcategory,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRenameCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    String categoryName,
    ValueNotifier<String> selectedCategory,
    ValueNotifier<String> selectedSubcategory,
  ) {
    final controller = TextEditingController(text: categoryName);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              borderRadius: AppSizes.boxBorderRadius,
            ),
            padding: EdgeInsets.fromLTRB(
              AppSizes.w24,
              AppSizes.h12,
              AppSizes.w24,
              AppSizes.h24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: AppSizes.w(48),
                      height: AppSizes.h4,
                      margin: EdgeInsets.only(bottom: AppSizes.h20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.white.withOpacity(0.12)
                            : AppColors.black.withOpacity(0.08),
                        borderRadius: AppSizes.boxBorderRadius,
                      ),
                    ),
                  ),
                  Text(
                    'Rename Category',
                    style: AppTextStyles.heading(context),
                  ),
                  SizedBox(height: AppSizes.h16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: AppTextStyles.body(context),
                    maxLength: 15,
                    decoration: InputDecoration(
                      hintText: 'Enter new category name',
                      hintStyle: AppTextStyles.body(
                        context,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.category_rounded,
                        color: AppColors.primary,
                        size: AppSizes.r20,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: AppSizes.boxBorderRadius,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.all(AppSizes.r16),
                    ),
                  ),
                  SizedBox(height: AppSizes.h24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSizes.h16,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.body(
                              context,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSizes.w16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final newName = controller.text.trim();
                            if (newName.isNotEmpty && newName != categoryName) {
                              await ref
                                  .read(subcategoriesProvider.notifier)
                                  .updateCategory(categoryName, newName);
                              if (selectedCategory.value == categoryName) {
                                selectedCategory.value = newName;
                              }
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: AppSizes.h16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSizes.boxBorderRadius,
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Save',
                            style: AppTextStyles.body(
                              context,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    String categoryName,
    ValueNotifier<String> selectedCategory,
    ValueNotifier<String> selectedSubcategory,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: AppSizes.boxBorderRadius,
          ),
          padding: EdgeInsets.fromLTRB(
            AppSizes.w24,
            AppSizes.h12,
            AppSizes.w24,
            AppSizes.h24,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: AppSizes.w(48),
                    height: AppSizes.h4,
                    margin: EdgeInsets.only(bottom: AppSizes.h20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.white.withOpacity(0.12)
                          : AppColors.black.withOpacity(0.08),
                      borderRadius: AppSizes.boxBorderRadius,
                    ),
                  ),
                ),
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: AppSizes.r(40),
                ),
                SizedBox(height: AppSizes.h16),
                Text(
                  'Delete Category?',
                  style: AppTextStyles.heading(context),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.h12),
                Text(
                  'This will permanently delete the custom category "$categoryName" and all of its custom subcategories. This action cannot be undone.',
                  style: AppTextStyles.body(
                    context,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.h24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTextStyles.body(
                            context,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSizes.w16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await ref
                              .read(subcategoriesProvider.notifier)
                              .deleteCategory(categoryName);
                          if (selectedCategory.value == categoryName) {
                            selectedCategory.value = 'Other';
                            selectedSubcategory.value = 'General';
                          }
                          if (context.mounted) {
                            Navigator.pop(context); // Close bottom sheet
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.white,
                          padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSizes.boxBorderRadius,
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: AppTextStyles.body(
                            context,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSubcategoryBottomSheet(
    BuildContext context,
    WidgetRef ref,
    String parentCategory,
    ValueNotifier<String> selectedSubcategory,
    List<SubcategoryModel> subcategories, {
    bool isIncome = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: AppSizes.boxBorderRadius,
          ),
          padding: EdgeInsets.fromLTRB(
            AppSizes.w24,
            AppSizes.h12,
            AppSizes.w24,
            AppSizes.h24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: AppSizes.w(48),
                  height: AppSizes.h4,
                  margin: EdgeInsets.only(bottom: AppSizes.h20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.white.withOpacity(0.12)
                        : AppColors.black.withOpacity(0.08),
                    borderRadius: AppSizes.boxBorderRadius,
                  ),
                ),
              ),
              Text('Select Subcategory', style: AppTextStyles.heading(context)),
              SizedBox(height: AppSizes.h16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: subcategories.length + 1,
                  separatorBuilder: (context, index) => Divider(
                    color: isDark
                        ? AppColors.white.withOpacity(0.05)
                        : AppColors.black.withOpacity(0.04),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    if (index == subcategories.length) {
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSizes.w8,
                          vertical: AppSizes.h4,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showAddSubcategoryDialog(
                            context,
                            ref,
                            parentCategory,
                            selectedSubcategory,
                            isIncome: isIncome,
                          );
                        },
                        leading: Container(
                          width: AppSizes.r(36),
                          height: AppSizes.r(36),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: AppSizes.boxBorderRadius,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: AppColors.primary,
                            size: AppSizes.r20,
                          ),
                        ),
                        title: Text(
                          '+ Add Custom',
                          style: AppTextStyles.body(
                            context,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }

                    final sub = subcategories[index];
                    final isSelected = selectedSubcategory.value == sub.name;
                    final activeCatColor = AppColors.getCategoryColor(
                      parentCategory,
                    );

                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSizes.w8,
                        vertical: AppSizes.h4,
                      ),
                      onTap: () {
                        selectedSubcategory.value = sub.name;
                        Navigator.pop(context);
                      },
                      onLongPress: (sub.isCustom && sub.name != 'General')
                          ? () {
                              Navigator.pop(context);
                              _showManageSubcategorySheet(
                                context,
                                ref,
                                sub,
                                selectedSubcategory,
                              );
                            }
                          : null,
                      leading: Container(
                        width: AppSizes.r(36),
                        height: AppSizes.r(36),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? activeCatColor.withOpacity(0.1)
                              : (isDark
                                    ? AppColors.surfaceContainerLowestDark
                                    : AppColors.backgroundLight),
                          borderRadius: AppSizes.boxBorderRadius,
                        ),
                        child: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: isSelected
                              ? activeCatColor
                              : AppColors.getTextMuted(
                                  context,
                                ).withOpacity(0.5),
                          size: AppSizes.r16,
                        ),
                      ),
                      title: Text(
                        sub.name,
                        style: AppTextStyles.body(
                          context,
                          color: isSelected
                              ? activeCatColor
                              : AppColors.getText(context),
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color: activeCatColor,
                              size: AppSizes.r20,
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showManageSubcategorySheet(
    BuildContext context,
    WidgetRef ref,
    SubcategoryModel sub,
    ValueNotifier<String> selectedSubcategory,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: AppSizes.boxBorderRadius,
          ),
          padding: EdgeInsets.fromLTRB(
            AppSizes.w24,
            AppSizes.h12,
            AppSizes.w24,
            AppSizes.h24,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: AppSizes.w(48),
                    height: AppSizes.h4,
                    margin: EdgeInsets.only(bottom: AppSizes.h20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.white.withOpacity(0.12)
                          : AppColors.black.withOpacity(0.08),
                      borderRadius: AppSizes.boxBorderRadius,
                    ),
                  ),
                ),
                Text(
                  'Manage Subcategory',
                  style: AppTextStyles.heading(context),
                ),
                Text(
                  '${sub.name} (under ${sub.parentCategory})',
                  style: AppTextStyles.body(
                    context,
                    color: AppColors.getTextMuted(context),
                  ),
                ),
                SizedBox(height: AppSizes.h24),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(AppSizes.r8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: AppColors.primary,
                      size: AppSizes.r20,
                    ),
                  ),
                  title: Text(
                    'Rename Subcategory',
                    style: AppTextStyles.body(context),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showRenameSubcategoryDialog(
                      context,
                      ref,
                      sub,
                      selectedSubcategory,
                    );
                  },
                ),
                Divider(
                  color: isDark
                      ? AppColors.white.withOpacity(0.05)
                      : AppColors.black.withOpacity(0.04),
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(AppSizes.r8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_forever_rounded,
                      color: AppColors.error,
                      size: AppSizes.r20,
                    ),
                  ),
                  title: Text(
                    'Delete Subcategory',
                    style: AppTextStyles.body(context, color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteSubcategoryDialog(
                      context,
                      ref,
                      sub,
                      selectedSubcategory,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRenameSubcategoryDialog(
    BuildContext context,
    WidgetRef ref,
    SubcategoryModel sub,
    ValueNotifier<String> selectedSubcategory,
  ) {
    final controller = TextEditingController(text: sub.name);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              borderRadius: AppSizes.boxBorderRadius,
            ),
            padding: EdgeInsets.fromLTRB(
              AppSizes.w24,
              AppSizes.h12,
              AppSizes.w24,
              AppSizes.h24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: AppSizes.w(48),
                      height: AppSizes.h4,
                      margin: EdgeInsets.only(bottom: AppSizes.h20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.white.withOpacity(0.12)
                            : AppColors.black.withOpacity(0.08),
                        borderRadius: AppSizes.boxBorderRadius,
                      ),
                    ),
                  ),
                  Text(
                    'Rename Subcategory',
                    style: AppTextStyles.heading(context),
                  ),
                  SizedBox(height: AppSizes.h4),
                  Text(
                    'For ${sub.parentCategory}',
                    style: AppTextStyles.body(
                      context,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: AppSizes.h16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: AppTextStyles.body(context),
                    maxLength: 20,
                    decoration: InputDecoration(
                      hintText: 'Enter new name',
                      hintStyle: AppTextStyles.body(
                        context,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.subdirectory_arrow_right_rounded,
                        color: AppColors.primary,
                        size: AppSizes.r20,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: AppSizes.boxBorderRadius,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.all(AppSizes.r16),
                    ),
                  ),
                  SizedBox(height: AppSizes.h24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSizes.h16,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.body(
                              context,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSizes.w16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final newName = controller.text.trim();
                            if (newName.isNotEmpty && newName != sub.name) {
                              await ref
                                  .read(subcategoriesProvider.notifier)
                                  .updateSubcategory(sub.id, newName);
                              if (selectedSubcategory.value == sub.name) {
                                selectedSubcategory.value = newName;
                              }
                              if (context.mounted) {
                                Navigator.pop(
                                  context,
                                ); // Close rename subcategory bottom sheet modal
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: AppSizes.h16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSizes.boxBorderRadius,
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Save',
                            style: AppTextStyles.body(
                              context,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteSubcategoryDialog(
    BuildContext context,
    WidgetRef ref,
    SubcategoryModel sub,
    ValueNotifier<String> selectedSubcategory,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: AppSizes.boxBorderRadius,
          ),
          padding: EdgeInsets.fromLTRB(
            AppSizes.w24,
            AppSizes.h12,
            AppSizes.w24,
            AppSizes.h24,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: AppSizes.w(48),
                    height: AppSizes.h4,
                    margin: EdgeInsets.only(bottom: AppSizes.h20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.white.withOpacity(0.12)
                          : AppColors.black.withOpacity(0.08),
                      borderRadius: AppSizes.boxBorderRadius,
                    ),
                  ),
                ),
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: AppSizes.r(40),
                ),
                SizedBox(height: AppSizes.h16),
                Text(
                  'Delete Subcategory?',
                  style: AppTextStyles.heading(context),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.h12),
                Text(
                  'This will permanently delete the custom subcategory "${sub.name}". This action cannot be undone.',
                  style: AppTextStyles.body(
                    context,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.h24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
                        ),
                        child: Text(
                          'Cancel',
                          style: AppTextStyles.body(
                            context,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSizes.w16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await ref
                              .read(subcategoriesProvider.notifier)
                              .deleteSubcategory(sub.id);
                          if (selectedSubcategory.value == sub.name) {
                            selectedSubcategory.value = 'General';
                          }
                          if (context.mounted) {
                            Navigator.pop(
                              context,
                            ); // Close bottom sheet confirmation modal
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: AppColors.white,
                          padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppSizes.boxBorderRadius,
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: AppTextStyles.body(
                            context,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<String> selectedCategory,
    ValueNotifier<String> selectedSubcategory,
    ValueNotifier<TransactionType> selectedType,
  ) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              borderRadius: AppSizes.boxBorderRadius,
            ),
            padding: EdgeInsets.fromLTRB(
              AppSizes.w24,
              AppSizes.h12,
              AppSizes.w24,
              AppSizes.h24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: AppSizes.w(48),
                      height: AppSizes.h4,
                      margin: EdgeInsets.only(bottom: AppSizes.h20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.white.withOpacity(0.12)
                            : AppColors.black.withOpacity(0.08),
                        borderRadius: AppSizes.boxBorderRadius,
                      ),
                    ),
                  ),
                  Text(
                    'New Main Category',
                    style: AppTextStyles.heading(context),
                  ),
                  SizedBox(height: AppSizes.h16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: AppTextStyles.body(context),
                    maxLength: 15,
                    decoration: InputDecoration(
                      hintText: 'Enter name (e.g. Business, Hobby)',
                      hintStyle: AppTextStyles.body(
                        context,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.category_rounded,
                        color: AppColors.primary,
                        size: AppSizes.r20,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: AppSizes.boxBorderRadius,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.all(AppSizes.r16),
                    ),
                  ),
                  SizedBox(height: AppSizes.h24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSizes.h16,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.body(
                              context,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSizes.w16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (controller.text.trim().isNotEmpty) {
                              final name = controller.text.trim();
                              await ref
                                  .read(subcategoriesProvider.notifier)
                                  .addSubcategory(
                                    'General',
                                    name,
                                    isIncome:
                                        selectedType.value ==
                                        TransactionType.credit,
                                  );
                              selectedCategory.value = name;
                              selectedSubcategory.value = 'General';
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: AppSizes.h16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSizes.boxBorderRadius,
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Add',
                            style: AppTextStyles.body(
                              context,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddSubcategoryDialog(
    BuildContext context,
    WidgetRef ref,
    String category,
    ValueNotifier<String> selectedSubcategory, {
    bool isIncome = false,
  }) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              borderRadius: AppSizes.boxBorderRadius,
            ),
            padding: EdgeInsets.fromLTRB(
              AppSizes.w24,
              AppSizes.h12,
              AppSizes.w24,
              AppSizes.h24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: AppSizes.w(48),
                      height: AppSizes.h4,
                      margin: EdgeInsets.only(bottom: AppSizes.h20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.white.withOpacity(0.12)
                            : AppColors.black.withOpacity(0.08),
                        borderRadius: AppSizes.boxBorderRadius,
                      ),
                    ),
                  ),
                  Text(
                    'New Subcategory',
                    style: AppTextStyles.heading(context),
                  ),
                  SizedBox(height: AppSizes.h4),
                  Text(
                    'For $category',
                    style: AppTextStyles.body(
                      context,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: AppSizes.h16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: AppTextStyles.body(context),
                    maxLength: 20,
                    decoration: InputDecoration(
                      hintText: 'Enter name (e.g. Netflix, Gym)',
                      hintStyle: AppTextStyles.body(
                        context,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.subdirectory_arrow_right_rounded,
                        color: AppColors.primary,
                        size: AppSizes.r20,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: AppSizes.boxBorderRadius,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.all(AppSizes.r16),
                    ),
                  ),
                  SizedBox(height: AppSizes.h24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSizes.h16,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.body(
                              context,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSizes.w16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (controller.text.trim().isNotEmpty) {
                              final name = controller.text.trim();
                              await ref
                                  .read(subcategoriesProvider.notifier)
                                  .addSubcategory(
                                    name,
                                    category,
                                    isIncome: isIncome,
                                  );
                              selectedSubcategory.value = name;
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: AppSizes.h16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppSizes.boxBorderRadius,
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Add',
                            style: AppTextStyles.body(
                              context,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
