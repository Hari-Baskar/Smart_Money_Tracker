import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';
import 'package:uuid/uuid.dart';
import '../providers/subcategory_provider.dart';
import 'package:smart_money_tracker/core/constants/payment_constants.dart';
import '../widgets/bank_picker_widget.dart';
import '../widgets/payment_method_picker_widget.dart';
import '../widgets/txn_category_picker_sheet.dart';
import '../widgets/txn_subcategory_picker_sheet.dart';
import 'package:smart_money_tracker/core/services/analytics_service.dart';
import 'package:smart_money_tracker/core/constants/app_toast_messages.dart';

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
      FocusManager.instance.primaryFocus?.unfocus();
      await Future.delayed(const Duration(milliseconds: 50));
      if (!isMounted()) return;
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
                      primary: AppColors.primaryContainer,
                      onPrimary: AppColors.white,
                      primaryContainer: AppColors.primary,
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
                      primary: AppColors.primaryContainer,
                      onPrimary: AppColors.white,
                      primaryContainer: AppColors.primary,
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
      
      final amountText = amountController.text;
      if (amountText.isEmpty || double.tryParse(amountText) == null) {
        AppToast.show(context, 'Please enter a valid amount', isError: true);
        return;
      }

      isLoading.value = true;

      try {
        final authState = ref.read(authStateProvider);
        final userId = authState.value?.id;

        if (userId == null) {
          AppToast.show(context, AppToastMessages.loginRequired, isError: true);
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
          AppToast.show(context, 'Transaction Created');
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            context.go('/');
          }
        }
      } catch (e) {
        if (isMounted()) {
          AppToast.show(context, AppToastMessages.error, isError: true);
        }
      } finally {
        if (isMounted()) isLoading.value = false;
      }
    }

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Theme.of(context).colorScheme.onBackground,
                    size: AppSizes.r20,
                  ),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: Text(
            'Add Transaction',
            style: AppTextStyles.subHeading(context),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(AppSizes.w12),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSizes.h16),

                _buildSectionTitle(context, 'General Info'),
                _buildInfoCard(context, [
                  _buildEditField(
                    context,
                    'Amount',
                    amountController,
                    Icons.currency_rupee_rounded,
                    hint: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  _buildTypePicker(
                    context,
                    selectedType,
                    selectedCategory,
                    selectedSubcategory,
                  ),
                  _buildEditField(
                    context,
                    'Merchant',
                    merchantController,
                    Icons.storefront_rounded,
                  ),
                  _buildCategoryPicker(
                    context,
                    ref,
                    selectedCategory,
                    selectedSubcategory,
                    selectedType,
                  ),
                  _buildSubcategoryPicker(
                    context,
                    ref,
                    selectedCategory,
                    selectedSubcategory,
                    selectedType,
                  ),
                  _buildBankPicker(
                    context,
                    selectedBankId,
                    customBankController,
                  ),
                  _buildPaymentMethodPicker(
                    context,
                    selectedPaymentMethodId,
                    customPaymentController,
                  ),
                  _buildDateField(context, selectedDate, selectDate),
                ]),
                SizedBox(height: AppSizes.h40),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.w16,
              AppSizes.h12,
              AppSizes.w16,
              AppSizes.h16,
            ),
            child: PrimaryButton(
              text: 'Save Transaction',
              onPressed: submitForm,
              isLoading: isLoading.value,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.h12, left: AppSizes.w4),
      child: Text(
        title,
        style: AppTextStyles.body(
          context,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    return Column(children: children);
  }

  Widget _buildEditField(
    BuildContext context,
    String label,
    TextEditingController controller,
    IconData icon, {
    String hint = '',
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
      child: Row(
        children: [
          Container(
            width: AppSizes.r(36),
            height: AppSizes.r(36),
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: AppSizes.r20),
          ),
          SizedBox(width: AppSizes.w16),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                labelText: label,
                hintText: hint.isNotEmpty ? hint : null,
                hintStyle: AppTextStyles.body(context, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
                labelStyle: AppTextStyles.body(
                  context,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
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
        final displayCategoryName = categories
            .firstWhere(
              (c) => c.id == selectedCategory.value,
              orElse: () => CategoryModel(
                id: selectedCategory.value,
                name: selectedCategory.value,
              ),
            )
            .name;

        final catColor = AppColors.getCategoryColor(displayCategoryName);
        final catBg = AppColors.getCategoryBgColor(
          context,
          displayCategoryName,
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Future.delayed(const Duration(milliseconds: 50), () {
              if (!context.mounted) return;
              showModalBottomSheet(
                context: context,
                backgroundColor: AppColors.transparent,
                isScrollControlled: true,
                builder: (context) => TxnCategoryPickerSheet(
                  selectedCategory: selectedCategory,
                  selectedSubcategory: selectedSubcategory,
                  isIncome: isIncome,
                ),
              );
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
            child: Row(
              children: [
                Container(
                  width: AppSizes.r(36),
                  height: AppSizes.r(36),
                  decoration: BoxDecoration(
                    color: catColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    AppColors.getCategoryIcon(displayCategoryName),
                    color: Colors.white,
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

        final displaySubcategoryName = allSubs
            .firstWhere(
              (s) => s.id == selectedSubcategory.value,
              orElse: () => SubcategoryModel(
                id: selectedSubcategory.value,
                name: selectedSubcategory.value,
                parentCategoryId: selectedCategory.value,
              ),
            )
            .name;

        final categoriesAsync = ref.read(categoriesProvider);
        final categories = categoriesAsync.value ?? const [];
        final displayCategoryName = categories
            .firstWhere(
              (c) => c.id == selectedCategory.value,
              orElse: () => CategoryModel(
                id: selectedCategory.value,
                name: selectedCategory.value,
              ),
            )
            .name;

        final catColor = AppColors.getCategoryColor(displayCategoryName);
        final catBg = AppColors.getCategoryBgColor(
          context,
          displayCategoryName,
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Future.delayed(const Duration(milliseconds: 50), () {
              if (!context.mounted) return;
              showModalBottomSheet(
                context: context,
                backgroundColor: AppColors.transparent,
                isScrollControlled: true,
                builder: (context) => TxnSubcategoryPickerSheet(
                  selectedSubcategory: selectedSubcategory,
                  parentCategory: selectedCategory.value,
                  isIncome: isIncome,
                ),
              );
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
            child: Row(
              children: [
                Container(
                  width: AppSizes.r(36),
                  height: AppSizes.r(36),
                  decoration: BoxDecoration(
                    color: catColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.subdirectory_arrow_right_rounded,
                    color: Colors.white,
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
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
        child: Row(
          children: [
            Container(
              width: AppSizes.r(36),
              height: AppSizes.r(36),
              decoration: BoxDecoration(
                color: Colors.pink,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: Colors.white,
                size: AppSizes.r20,
              ),
            ),
            SizedBox(width: AppSizes.w16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date & Time',
                    style: AppTextStyles.body(
                      context,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: AppSizes.h(2)),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy • hh:mm a',
                    ).format(selectedDate.value),
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
  }

  Widget _buildTypePicker(
    BuildContext context,
    ValueNotifier<TransactionType> selectedType,
    ValueNotifier<String> selectedCategory,
    ValueNotifier<String> selectedSubcategory,
  ) {
    final isIncome = selectedType.value == TransactionType.credit;
    final color = isIncome ? AppColors.success : AppColors.error;
    final icon = isIncome
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final typeName = isIncome ? 'Credit' : 'Debit';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!context.mounted) return;
          showModalBottomSheet(
            context: context,
            backgroundColor: AppColors.transparent,
            isScrollControlled: true,
            builder: (modalContext) => Container(
              decoration: BoxDecoration(
                color: AppColors.isDark(modalContext)
                    ? AppColors.surfaceDark
                    : AppColors.white,
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
                          color: AppColors.isDark(modalContext)
                              ? AppColors.white.withOpacity(0.12)
                              : AppColors.black.withOpacity(0.08),
                          borderRadius: AppSizes.boxBorderRadius,
                        ),
                      ),
                    ),
                    Text(
                      'Select Type',
                      style: AppTextStyles.subHeading(modalContext),
                    ),
                    SizedBox(height: AppSizes.h16),
                    ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(AppSizes.r8),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: AppSizes.r20,
                        ),
                      ),
                      title: Text(
                        'Debit',
                        style: AppTextStyles.body(modalContext),
                      ),
                      trailing: !isIncome
                          ? Icon(Icons.check_rounded, color: AppColors.error)
                          : null,
                      onTap: () {
                        if (selectedType.value != TransactionType.debit) {
                          selectedType.value = TransactionType.debit;
                          selectedCategory.value = 'Other';
                          selectedSubcategory.value = 'General';
                        }
                        Navigator.pop(modalContext);
                      },
                    ),
                    Divider(
                      color: AppColors.isDark(modalContext)
                          ? AppColors.white.withOpacity(0.05)
                          : AppColors.black.withOpacity(0.04),
                    ),
                    ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(AppSizes.r8),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_downward_rounded,
                          color: Colors.white,
                          size: AppSizes.r20,
                        ),
                      ),
                      title: Text(
                        'Credit',
                        style: AppTextStyles.body(modalContext),
                      ),
                      trailing: isIncome
                          ? Icon(Icons.check_rounded, color: AppColors.success)
                          : null,
                      onTap: () {
                        if (selectedType.value != TransactionType.credit) {
                          selectedType.value = TransactionType.credit;
                          selectedCategory.value = 'Salary';
                          selectedSubcategory.value = 'General';
                        }
                        Navigator.pop(modalContext);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
        child: Row(
          children: [
            Container(
              width: AppSizes.r(36),
              height: AppSizes.r(36),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: AppSizes.r20),
            ),
            SizedBox(width: AppSizes.w16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Type',
                    style: AppTextStyles.body(
                      context,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: AppSizes.h(2)),
                  Text(typeName, style: AppTextStyles.body(context)),
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
