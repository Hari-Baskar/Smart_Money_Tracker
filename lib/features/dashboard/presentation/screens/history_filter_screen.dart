import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/subcategory_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/bank_picker_widget.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/payment_method_picker_widget.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/txn_category_picker_sheet.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/txn_subcategory_picker_sheet.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';
import 'package:smart_money_tracker/core/services/analytics_service.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:smart_money_tracker/features/auth/presentation/providers/auth_provider.dart';

// ── Filter state returned to the history screen ───────────────────────────────
class HistoryFilterState {
  final DateTimeRange dateRange;
  final String category;
  final String subcategory;
  final String? bankId;
  final String? paymentMethodId;
  final TransactionType? transactionType;

  const HistoryFilterState({
    required this.dateRange,
    required this.category,
    required this.subcategory,
    this.bankId,
    this.paymentMethodId,
    this.transactionType,
  });

  bool get hasActiveFilters =>
      category != 'All' ||
      subcategory != 'All' ||
      bankId != null ||
      paymentMethodId != null ||
      transactionType != null;
}

// ── History Filter Screen ────────────────────────────────────────────────────
class HistoryFilterScreen extends HookConsumerWidget {
  final HistoryFilterState initial;

  static const List<String> _categoriesList = [
    'All',
    'Food',
    'Travel',
    'Shopping',
    'Bills',
    'Groceries',
    'Entertainment',
    'Health',
    'Investment',
    'Salary',
    'Other',
    'Unknown',
  ];

  const HistoryFilterScreen({super.key, required this.initial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final dateFmt = DateFormat('MMM dd, yyyy');

    // ── Draft state (ValueNotifiers work directly with existing widgets) ──
    final dateRange = useState(initial.dateRange);
    final category = useState(initial.category);
    final subcategory = useState(initial.subcategory);
    final bankId = useState<String?>(initial.bankId);
    final paymentMethodId = useState<String?>(initial.paymentMethodId);
    final transactionType = useState<TransactionType?>(initial.transactionType);
    final customBankController = useTextEditingController();
    final customPaymentController = useTextEditingController();
    final isSyncing = useState(false);

    useEffect(() {
      AnalyticsService.logScreenView('HistoryFilterScreen');
      return null;
    }, const []);

    // Reset subcategory when category changes
    useEffect(() {
      subcategory.value = 'All';
      return null;
    }, [category.value]);

    final subcategoriesAsync = ref.watch(subcategoriesProvider);

    // ── Active filter count ───────────────────────────────────────────────
    final activeCount = [
      category.value != 'All',
      subcategory.value != 'All',
      bankId.value != null,
      paymentMethodId.value != null,
      transactionType.value != null,
    ].where((v) => v).length;

    String subcategoryLabel = subcategory.value;
    if (subcategory.value != 'All' && subcategoriesAsync.hasValue) {
      final match = subcategoriesAsync.value!
          .where((s) => s.id == subcategory.value)
          .firstOrNull;
      if (match != null) {
        subcategoryLabel = match.name;
      }
    }

    String categoryLabel = category.value;
    if (category.value != 'All') {
      final categories = ref.read(categoriesProvider).value ?? const [];
      final match = categories.where((c) => c.id == category.value).firstOrNull;
      if (match != null) {
        categoryLabel = match.name;
      }
    }

    // ── Handlers ─────────────────────────────────────────────────────────
    Future<void> pickDateRange() async {
      final now = DateTime.now();
      DateTime safeStart = dateRange.value.start.isAfter(now) ? now : dateRange.value.start;
      DateTime safeEnd = dateRange.value.end.isAfter(now) ? now : dateRange.value.end;
      if (safeStart.isAfter(safeEnd)) safeStart = safeEnd;

      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: now,
        initialDateRange: DateTimeRange(start: safeStart, end: safeEnd),
        builder: (ctx, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: isDark
                    ? AppColors.primaryContainer
                    : AppColors.primary,
                onPrimary: AppColors.white,
                surface: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                onSurface: isDark ? AppColors.white : AppColors.textLight,
              ),
              datePickerTheme: Theme.of(context).datePickerTheme.copyWith(
                rangeSelectionOverlayColor: WidgetStateProperty.all(
                  isDark
                      ? AppColors.primaryContainer.withOpacity(0.3)
                      : AppColors.primary.withOpacity(0.15),
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        dateRange.value = picked;
      }
    }

    List<String> getFilteredCategories() {
      final categories = ref.read(categoriesProvider).value ?? const [];
      final defaultIncomeCategories = {'Salary'};
      final defaultExpenseCategories = {
        'Food',
        'Travel',
        'Shopping',
        'Bills',
        'Groceries',
        'Entertainment',
        'Health',
        'Investment',
        'Other',
        'Unknown',
      };

      final customIncome = categories
          .where((c) => c.isIncome && c.isCustom)
          .map((c) => c.id)
          .toSet();
      final customExpense = categories
          .where((c) => !c.isIncome && c.isCustom)
          .map((c) => c.id)
          .toSet();

      final finalIncome = {...defaultIncomeCategories, ...customIncome};
      final finalExpense = {...defaultExpenseCategories, ...customExpense};

      List<String> sortByIds(Set<String> catIds) {
        final list = catIds.toList();
        list.sort((a, b) {
          final nameA = categories
              .firstWhere(
                (c) => c.id == a,
                orElse: () => CategoryModel(id: a, name: a),
              )
              .name;
          final nameB = categories
              .firstWhere(
                (c) => c.id == b,
                orElse: () => CategoryModel(id: b, name: b),
              )
              .name;
          return nameA.compareTo(nameB);
        });
        return list;
      }

      if (transactionType.value == TransactionType.credit) {
        return ['All', ...sortByIds(finalIncome)];
      } else if (transactionType.value == TransactionType.debit) {
        return ['All', ...sortByIds(finalExpense)];
      } else {
        final allCategories = {...finalIncome, ...finalExpense};
        return ['All', ...sortByIds(allCategories)];
      }
    }

    void showCategorySheet() {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.transparent,
        isScrollControlled: true,
        builder: (_) => TxnCategoryPickerSheet(
          selectedCategory: category,
          selectedSubcategory: subcategory,
          isIncome: transactionType.value == TransactionType.credit
              ? true
              : (transactionType.value == TransactionType.debit ? false : null),
          showAllOption: true,
        ),
      );
    }

    void showSubcategorySheet() {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.transparent,
        isScrollControlled: true,
        builder: (_) => TxnSubcategoryPickerSheet(
          selectedSubcategory: subcategory,
          parentCategory: category.value,
          isIncome: transactionType.value == TransactionType.credit
              ? true
              : (transactionType.value == TransactionType.debit ? false : null),
          showAllOption: true,
        ),
      );
    }

    void applyFilters() async {
      AnalyticsService.logEvent('apply_filter');

      final userId = ref.read(authStateProvider).value?.id;
      if (userId != null) {
        isSyncing.value = true;
        try {
          final adjustedEnd = DateTime(
            dateRange.value.end.year,
            dateRange.value.end.month,
            dateRange.value.end.day,
            23,
            59,
            59,
          );
          await ref
              .read(transactionRepositoryProvider)
              .syncDateRange(userId, dateRange.value.start, adjustedEnd);
        } catch (e) {
          print('Error syncing date range: $e');
        } finally {
          if (context.mounted) {
            isSyncing.value = false;
          }
        }
      }

      if (context.mounted) {
        Navigator.of(context).pop(
          HistoryFilterState(
            dateRange: dateRange.value,
            category: category.value,
            subcategory: subcategory.value,
            bankId: bankId.value,
            paymentMethodId: paymentMethodId.value,
            transactionType: transactionType.value,
          ),
        );
      }
    }

    void resetFilters() {
      final now = DateTime.now();
      dateRange.value = DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: now,
      );
      category.value = 'All';
      subcategory.value = 'All';
      bankId.value = null;
      paymentMethodId.value = null;
      transactionType.value = null;

      applyFilters();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Filters', style: AppTextStyles.heading(context)),
            if (activeCount > 0) ...[
              SizedBox(width: AppSizes.w8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.w(7),
                  vertical: AppSizes.h(2),
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.r12),
                ),
                child: Text(
                  '$activeCount',
                  style: AppTextStyles.small(
                    context,
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: resetFilters,
            child: Text(
              'Reset',
              style: AppTextStyles.body(context, color: AppColors.error),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.w12),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSizes.h16),
              _buildSectionTitle(context, 'Filter Details'),
              _buildInfoCard(context, [
                _buildTypePicker(
                  context,
                  transactionType,
                  category,
                  subcategory,
                ),
                _buildCategoryPicker(
                  context,
                  ref,
                  category,
                  categoryLabel,
                  showCategorySheet,
                ),
                _buildSubcategoryPicker(
                  context,
                  ref,
                  category,
                  subcategory,
                  subcategoryLabel,
                  showSubcategorySheet,
                ),
                _buildBankPicker(context, bankId, customBankController),
                _buildPaymentMethodPicker(
                  context,
                  paymentMethodId,
                  customPaymentController,
                ),
                _buildDateRangeField(context, dateRange, pickDateRange),
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
          child: Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: 'Reset',
                  onPressed: resetFilters,
                  isOutlined: true,
                  foregroundColor: AppColors.error,
                  borderColor: AppColors.error.withOpacity(0.4),
                ),
              ),
              SizedBox(width: AppSizes.w12),
              Expanded(
                child: PrimaryButton(
                  text: 'Apply',
                  onPressed: isSyncing.value ? null : applyFilters,
                  isLoading: isSyncing.value,
                ),
              ),
            ],
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

  Widget _buildDateRangeField(
    BuildContext context,
    ValueNotifier<DateTimeRange> dateRange,
    VoidCallback onTap,
  ) {
    final dateFmt = DateFormat('MMM dd, yyyy');
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
              decoration: const BoxDecoration(
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
                    'Selected Period',
                    style: AppTextStyles.body(
                      context,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: AppSizes.h(2)),
                  Text(
                    '${dateFmt.format(dateRange.value.start)}  →  ${dateFmt.format(dateRange.value.end)}',
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
    ValueNotifier<TransactionType?> selectedType,
    ValueNotifier<String> selectedCategory,
    ValueNotifier<String> selectedSubcategory,
  ) {
    final isIncome = selectedType.value == TransactionType.credit;
    final isAll = selectedType.value == null;

    final color = isAll
        ? Colors.amber
        : (isIncome ? AppColors.success : AppColors.error);
    final icon = isAll
        ? Icons.swap_horiz_rounded
        : (isIncome
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded);
    final typeName = isAll ? 'All' : (isIncome ? 'Credit' : 'Debit');

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
                      style: AppTextStyles.subHeading(modalContext).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSizes.h16),
                    ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(AppSizes.r8),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.swap_horiz_rounded,
                          color: Colors.white,
                          size: AppSizes.r20,
                        ),
                      ),
                      title: Text(
                        'All',
                        style: AppTextStyles.body(modalContext),
                      ),
                      trailing: isAll
                          ? Icon(Icons.check_rounded, color: Colors.amber)
                          : null,
                      onTap: () {
                        if (selectedType.value != null) {
                          selectedType.value = null;
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
                      trailing: (!isAll && !isIncome)
                          ? Icon(Icons.check_rounded, color: AppColors.error)
                          : null,
                      onTap: () {
                        if (selectedType.value != TransactionType.debit) {
                          selectedType.value = TransactionType.debit;
                          selectedCategory.value = 'All';
                          selectedSubcategory.value = 'All';
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
                      trailing: (!isAll && isIncome)
                          ? Icon(Icons.check_rounded, color: AppColors.success)
                          : null,
                      onTap: () {
                        if (selectedType.value != TransactionType.credit) {
                          selectedType.value = TransactionType.credit;
                          selectedCategory.value = 'All';
                          selectedSubcategory.value = 'All';
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

  Widget _buildCategoryPicker(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<String> selectedCategory,
    String categoryLabel,
    VoidCallback onTap,
  ) {
    final catColor = selectedCategory.value == 'All'
        ? Colors.amber
        : AppColors.getCategoryColor(selectedCategory.value);

    final icon = selectedCategory.value == 'All'
        ? Icons.category_rounded
        : AppColors.getCategoryIcon(selectedCategory.value);

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
                color: catColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: AppSizes.r20),
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
                    categoryLabel.length > 13
                        ? '${categoryLabel.substring(0, 11)}...'
                        : categoryLabel,
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

  Widget _buildSubcategoryPicker(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<String> selectedCategory,
    ValueNotifier<String> selectedSubcategory,
    String subcategoryLabel,
    VoidCallback onTap,
  ) {
    final catColor = selectedCategory.value == 'All'
        ? Colors.amber
        : AppColors.getCategoryColor(selectedCategory.value);

    return Opacity(
      opacity: selectedCategory.value == 'All' ? 0.4 : 1.0,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: selectedCategory.value == 'All' ? null : onTap,
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
                      selectedCategory.value == 'All'
                          ? 'Select a category first'
                          : subcategoryLabel,
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
