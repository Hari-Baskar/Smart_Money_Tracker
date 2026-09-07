import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/common/widgets/app_text_field.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_money_tracker/core/models/budget_model.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:smart_money_tracker/features/budget/domain/providers/budget_providers.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/subcategory_provider.dart';
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/txn_category_picker_sheet.dart';
import 'package:smart_money_tracker/core/common/widgets/category_icon_widget.dart';


class CreateBudgetScreen extends HookConsumerWidget {
  final BudgetModel? budgetToEdit;
  const CreateBudgetScreen({super.key, this.budgetToEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final nameController = useTextEditingController(text: budgetToEdit?.name ?? '');
    final amountController = useTextEditingController(
        text: budgetToEdit?.amount != null ? budgetToEdit!.amount.toStringAsFixed(2) : '');
    
    final selectedCategory = useState<String>(budgetToEdit?.categoryId ?? 'All');
    final selectedSubcategory = useState<String>(budgetToEdit?.subcategoryId ?? 'All');
    final selectedPeriod = useState<BudgetPeriod>(budgetToEdit?.period ?? BudgetPeriod.monthly);
    final isRecurring = useState<bool>(budgetToEdit?.isRecurring ?? true);
    final startDate = useState<DateTime?>(budgetToEdit?.startDate);
    final endDate = useState<DateTime?>(budgetToEdit?.endDate);
    
    final isLoading = useState(false);
    final isMounted = useIsMounted();

    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.value ?? [];
    final sortedCategories = categories.where((c) => !c.isIncome).toList()..sort((a, b) => a.name.compareTo(b.name));

    Future<void> submitForm() async {
      final nameText = nameController.text.trim();
      
      final amountText = amountController.text;
      if (amountText.isEmpty || double.tryParse(amountText) == null) {
        AppToast.show(context, 'Please enter a valid amount', isError: true);
        return;
      }
      if (selectedPeriod.value == BudgetPeriod.custom) {
        if (startDate.value == null || endDate.value == null) {
          AppToast.show(context, 'Please select both start and end dates', isError: true);
          return;
        }
        if (endDate.value!.isBefore(startDate.value!)) {
          AppToast.show(context, 'End date cannot be before start date', isError: true);
          return;
        }
      }
      
      final user = ref.read(authStateProvider).value;
      if (user == null) return;
      
      isLoading.value = true;
      
      try {
        final amount = double.tryParse(amountController.text) ?? 0.0;
        final now = DateTime.now();
        final bool isRec = (selectedPeriod.value == BudgetPeriod.monthly || selectedPeriod.value == BudgetPeriod.weekly)
            ? isRecurring.value
            : (selectedPeriod.value == BudgetPeriod.yearly ? true : false);

        DateTime? finalStartDate;
        DateTime? finalEndDate;

        if (selectedPeriod.value == BudgetPeriod.custom) {
          finalStartDate = startDate.value;
          finalEndDate = endDate.value;
        } else if (selectedPeriod.value == BudgetPeriod.monthly) {
          if (!isRec) {
            finalStartDate = budgetToEdit?.startDate ?? DateTime(now.year, now.month, 1);
            finalEndDate = DateTime(finalStartDate.year, finalStartDate.month + 1, 0, 23, 59, 59, 999);
          } else {
            finalStartDate = budgetToEdit?.startDate ?? DateTime(now.year, now.month, 1);
            finalEndDate = (budgetToEdit != null && !budgetToEdit!.isRecurring) ? null : budgetToEdit?.endDate;
          }
        } else if (selectedPeriod.value == BudgetPeriod.weekly) {
          if (!isRec) {
            final base = budgetToEdit?.startDate ?? now;
            final monday = base.subtract(Duration(days: base.weekday - 1));
            finalStartDate = DateTime(monday.year, monday.month, monday.day);
            finalEndDate = DateTime(monday.year, monday.month, monday.day + 6, 23, 59, 59, 999);
          } else {
            finalStartDate = budgetToEdit?.startDate ?? DateTime.now();
            finalEndDate = (budgetToEdit != null && !budgetToEdit!.isRecurring) ? null : budgetToEdit?.endDate;
          }
        } else {
          // Yearly
          finalStartDate = budgetToEdit?.startDate ?? DateTime(now.year, 1, 1);
          finalEndDate = budgetToEdit?.endDate;
        }
        
        final budget = BudgetModel(
          id: budgetToEdit?.id,
          name: nameText,
          amount: amount,
          categoryId: selectedCategory.value == 'All' ? null : selectedCategory.value,
          subcategoryId: selectedSubcategory.value == 'All' ? null : selectedSubcategory.value,
          period: selectedPeriod.value,
          startDate: finalStartDate,
          endDate: finalEndDate,
          isStopped: budgetToEdit?.isStopped ?? false,
          isRecurring: isRec,
        );
        
        await ref.read(budgetRepositoryProvider).saveBudget(user.id, budget);
        
        if (isMounted()) {
          AppToast.show(context, 'Budget saved successfully');
          context.pop();
        }
      } catch (e) {
        if (isMounted()) {
          AppToast.show(context, 'Error saving budget: $e', isError: true);
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
                    Icons.arrow_back_rounded,
                    color: Theme.of(context).colorScheme.onBackground,
                    size: AppSizes.r20,
                  ),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: Text(
            budgetToEdit != null ? 'Edit Budget' : 'Create Budget',
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
                Padding(
                  padding: EdgeInsets.only(bottom: AppSizes.h12, left: AppSizes.w4),
                  child: Text(
                    'Budget Info',
                    style: AppTextStyles.body(
                      context,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                Column(
                  children: [
                    _buildEditField(
                      context,
                      'Budget Name',
                      nameController,
                      Icons.label_rounded,
                      'e.g. Groceries',
                      maxLength: 14,
                    ),
                    _buildEditField(
                      context,
                      'Budget Amount',
                      amountController,
                      Icons.currency_rupee_rounded,
                      '0.00',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    _buildPeriodPicker(
                      context,
                      selectedPeriod,
                      startDate,
                      endDate,
                    ),
                    if (selectedPeriod.value == BudgetPeriod.monthly ||
                        selectedPeriod.value == BudgetPeriod.weekly)
                      _buildRecurringField(
                        context,
                        isRecurring,
                        selectedPeriod.value,
                      ),
                    _buildCategoryPicker(
                      context,
                      ref,
                      selectedCategory,
                      selectedSubcategory,
                      sortedCategories,
                    ),
                    SizedBox(height: AppSizes.h12),
                    const BannerAdWidget(),
                  ],
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.w12,
              AppSizes.h12,
              AppSizes.w12,
              AppSizes.h12,
            ),
            child: PrimaryButton(
              text: 'Save Budget',
              onPressed: submitForm,
              isLoading: isLoading.value,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(
    BuildContext context,
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
      child: Row(
        children: [
          Container(
            width: AppSizes.r(36),
            height: AppSizes.r(36),
            decoration: const BoxDecoration(
              color: AppColors.warning,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.white, size: AppSizes.r20),
          ),
          SizedBox(width: AppSizes.w16),
          Expanded(
            child: AppTextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLength: maxLength,
              labelText: label,
              hintText: hint,
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
    List<CategoryModel> categories,
  ) {
    String displayCategoryName = 'Overall Budget';
    Color catColor = selectedCategory.value == 'All' ? AppColors.warning : AppColors.primary;
    String? emoji;
    
    if (selectedCategory.value != 'All') {
      try {
        final cat = categories.firstWhere((c) => c.id == selectedCategory.value);
        displayCategoryName = cat.name;
        
        if (selectedSubcategory.value != 'All') {
          final subcategoriesAsync = ref.watch(subcategoriesProvider);
          if (subcategoriesAsync.hasValue) {
            try {
               final sub = subcategoriesAsync.value!.firstWhere((s) => s.id == selectedSubcategory.value);
               displayCategoryName = '${cat.name} ➔ ${sub.name}';
            } catch (_) {
               displayCategoryName = '${cat.name} ➔ ${selectedSubcategory.value}';
            }
          } else {
             displayCategoryName = '${cat.name} ➔ ${selectedSubcategory.value}';
          }
        }
        
        catColor = AppColors.getCategoryColor(cat.name);
        emoji = cat.emoji;
      } catch (e) {
        // Fallback
      }
    }

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
              showAllOption: true,
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
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: catColor,
                shape: BoxShape.circle,
              ),
              child: selectedCategory.value == 'All' 
                  ? Icon(Icons.pie_chart_rounded, color: AppColors.white, size: AppSizes.r20)
                  : CategoryIconWidget(
                      categoryName: displayCategoryName,
                      emoji: emoji,
                      color: AppColors.white,
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: AppSizes.h(2)),
                  Text(
                    displayCategoryName.length > 25
                        ? '${displayCategoryName.substring(0, 23)}...'
                        : displayCategoryName,
                    style: AppTextStyles.body(context),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
              size: AppSizes.r20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodPicker(
    BuildContext context,
    ValueNotifier<BudgetPeriod> selectedPeriod,
    ValueNotifier<DateTime?> startDate,
    ValueNotifier<DateTime?> endDate,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.r(36),
                height: AppSizes.r(36),
                decoration: BoxDecoration(
                  color: AppColors.pink,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.date_range_rounded, color: AppColors.white, size: AppSizes.r20),
              ),
              SizedBox(width: AppSizes.w16),
              Expanded(
                child: DropdownButtonFormField<BudgetPeriod>(
                  value: selectedPeriod.value,
                  decoration: InputDecoration(
                    labelText: 'Budget Period',
                    labelStyle: AppTextStyles.body(
                      context,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  style: AppTextStyles.body(context),
                  items: BudgetPeriod.values.map((period) {
                    final label = period.name[0].toUpperCase() + period.name.substring(1);
                    return DropdownMenuItem(
                      value: period,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) selectedPeriod.value = val;
                  },
                ),
              ),
            ],
          ),
          if (selectedPeriod.value == BudgetPeriod.custom) ...[
            SizedBox(height: AppSizes.h12),
            Row(
              children: [
                SizedBox(width: AppSizes.r(36) + AppSizes.w16),
                Expanded(
                  child: _buildDatePickerField(
                    context, 
                    'Start Date', 
                    startDate.value, 
                    (d) => startDate.value = d,
                  ),
                ),
                SizedBox(width: AppSizes.w12),
                Expanded(
                  child: _buildDatePickerField(
                    context, 
                    'End Date', 
                    endDate.value, 
                    (d) => endDate.value = d,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecurringField(
    BuildContext context,
    ValueNotifier<bool> isRecurring,
    BudgetPeriod period,
  ) {
    final periodName = period == BudgetPeriod.monthly ? 'month' : 'week';
    final subtitle = isRecurring.value
        ? 'Repeats every $periodName automatically'
        : 'One-time budget for this $periodName';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => isRecurring.value = !isRecurring.value,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
        child: Row(
          children: [
            Container(
              width: AppSizes.r(36),
              height: AppSizes.r(36),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.repeat_rounded,
                color: AppColors.white,
                size: AppSizes.r20,
              ),
            ),
            SizedBox(width: AppSizes.w16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recurring',
                    style: AppTextStyles.body(
                      context,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: AppSizes.h(2)),
                  Text(
                    subtitle,
                    style: AppTextStyles.body(context),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: isRecurring.value,
                onChanged: (val) => isRecurring.value = val,
                activeColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField(BuildContext context, String label, DateTime? date, Function(DateTime) onSelected) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onSelected(picked);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.w12, vertical: AppSizes.h8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2)),
          borderRadius: AppSizes.boxBorderRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.small(
                context,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
            SizedBox(height: AppSizes.h4),
            Text(
              date != null 
                ? "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}" 
                : "Select Date",
              style: AppTextStyles.body(context),
            ),
          ],
        ),
      ),
    );
  }
}
