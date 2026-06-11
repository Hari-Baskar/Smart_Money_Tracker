import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:smart_money_tracker/core/models/transaction_model.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/subcategory_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/bank_picker_widget.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/payment_method_picker_widget.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/category_picker_sheet.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/widgets/subcategory_picker_sheet.dart';
import 'package:smart_money_tracker/core/common/widgets/banner_ad_widget.dart';
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

// ── History Filter Screen ─────────────────────────────────────────────────────
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

    // ── Handlers ─────────────────────────────────────────────────────────
    Future<void> pickDateRange() async {
      final picked = await showDateRangePicker(
        context: context,
        initialDateRange: dateRange.value,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF078644),
                    onPrimary: AppColors.white,
                    primaryContainer: Color(0xFF004D25),
                    onPrimaryContainer: AppColors.white,
                    surface: AppColors.surfaceDark,
                    onSurface: AppColors.white,
                    secondary: Color(0xFF078644),
                    onSecondary: AppColors.white,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: AppColors.white,
                    onSurface: AppColors.textLight,
                  ),
          ),
          child: child!,
        ),
      );
      if (picked != null) dateRange.value = picked;
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
          .map((c) => c.name)
          .toSet();
      final customExpense = categories
          .where((c) => !c.isIncome && c.isCustom)
          .map((c) => c.name)
          .toSet();

      final finalIncome = {...defaultIncomeCategories, ...customIncome};
      final finalExpense = {...defaultExpenseCategories, ...customExpense};

      if (transactionType.value == TransactionType.credit) {
        return ['All', ...finalIncome.toList()..sort()];
      } else if (transactionType.value == TransactionType.debit) {
        return ['All', ...finalExpense.toList()..sort()];
      } else {
        final allCategories = {...finalIncome, ...finalExpense};
        return ['All', ...allCategories.toList()..sort()];
      }
    }

    void showCategorySheet() {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.transparent,
        isScrollControlled: true,
        builder: (_) => CategoryPickerSheet(
          selectedCategory: category,
          customSubcategories: subcategoriesAsync.value ?? const [],
          categoriesList: getFilteredCategories(),
        ),
      );
    }

    void showSubcategorySheet() {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.transparent,
        isScrollControlled: true,
        builder: (_) => SubcategoryPickerSheet(
          activeCategory: category.value,
          selectedSubcategory: subcategory,
          subcategoriesAsync: subcategoriesAsync,
          transactionType: transactionType.value,
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
            23, 59, 59,
          );
          await ref.read(transactionRepositoryProvider).syncDateRange(userId, dateRange.value.start, adjustedEnd);
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
      dateRange.value = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      );
      category.value = 'All';
      subcategory.value = 'All';
      bankId.value = null;
      paymentMethodId.value = null;
      transactionType.value = null;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.w16,
          vertical: AppSizes.h8,
        ),
        children: [
          // ── Date Range ───────────────────────────────────────────────────
          _SectionHeader(
            title: 'Date Range',
            icon: Icons.calendar_month_rounded,
          ),
          SizedBox(height: AppSizes.h8),
          _FilterCard(
            child: InkWell(
              borderRadius: AppSizes.cardBorderRadius,
              onTap: pickDateRange,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.w16,
                  vertical: AppSizes.h(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSizes.r8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.primary,
                        size: AppSizes.r16,
                      ),
                    ),
                    SizedBox(width: AppSizes.w12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Period',
                            style: AppTextStyles.small(
                              context,
                              color: AppColors.getTextMuted(context),
                            ),
                          ),
                          SizedBox(height: AppSizes.h(2)),
                          Text(
                            '${dateFmt.format(dateRange.value.start)}  →  '
                            '${dateFmt.format(dateRange.value.end)}',
                            style: AppTextStyles.body(
                              context,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.getTextMuted(context),
                      size: AppSizes.r20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: AppSizes.h20),

          // ── Transaction Type ─────────────────────────────────────────────
          _SectionHeader(
            title: 'Transaction Type',
            icon: Icons.swap_horiz_rounded,
            trailing: transactionType.value != null
                ? GestureDetector(
                    onTap: () {
                      transactionType.value = null;
                    },
                    child: Text(
                      'Clear',
                      style: AppTextStyles.small(
                        context,
                        color: AppColors.error,
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(height: AppSizes.h8),
          Row(
            children: [
              Expanded(
                child: _buildTypeButton(
                  context,
                  'All',
                  null,
                  AppColors.primary,
                  transactionType,
                  category,
                  subcategory,
                  subcategoriesAsync,
                ),
              ),
              SizedBox(width: AppSizes.w8),
              Expanded(
                child: _buildTypeButton(
                  context,
                  'Expense',
                  TransactionType.debit,
                  AppColors.error,
                  transactionType,
                  category,
                  subcategory,
                  subcategoriesAsync,
                ),
              ),
              SizedBox(width: AppSizes.w8),
              Expanded(
                child: _buildTypeButton(
                  context,
                  'Income',
                  TransactionType.credit,
                  AppColors.success,
                  transactionType,
                  category,
                  subcategory,
                  subcategoriesAsync,
                ),
              ),
            ],
          ),

          SizedBox(height: AppSizes.h20),

          // ── Category ─────────────────────────────────────────────────────
          _SectionHeader(
            title: 'Category',
            icon: Icons.grid_view_rounded,
            trailing: category.value != 'All'
                ? GestureDetector(
                    onTap: () {
                      category.value = 'All';
                      subcategory.value = 'All';
                    },
                    child: Text(
                      'Clear',
                      style: AppTextStyles.small(
                        context,
                        color: AppColors.error,
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(height: AppSizes.h8),
          _FilterCard(
            child: InkWell(
              borderRadius: AppSizes.cardBorderRadius,
              onTap: showCategorySheet,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.w16,
                  vertical: AppSizes.h(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSizes.r8),
                      decoration: BoxDecoration(
                        color: AppColors.getCategoryColor(
                          category.value,
                        ).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppColors.getCategoryIcon(category.value),
                        color: AppColors.getCategoryColor(category.value),
                        size: AppSizes.r16,
                      ),
                    ),
                    SizedBox(width: AppSizes.w12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category',
                            style: AppTextStyles.small(
                              context,
                              color: AppColors.getTextMuted(context),
                            ),
                          ),
                          SizedBox(height: AppSizes.h(2)),
                          Text(
                            category.value,
                            style: AppTextStyles.body(
                              context,
                              color: category.value == 'All'
                                  ? AppColors.getText(context)
                                  : AppColors.getCategoryColor(category.value),
                              fontWeight: category.value == 'All'
                                  ? FontWeight.w400
                                  : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (category.value != 'All')
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.w(6),
                          vertical: AppSizes.h(2),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.getCategoryColor(
                            category.value,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSizes.r4),
                        ),
                        child: Text(
                          'Active',
                          style: AppTextStyles.small(
                            context,
                            color: AppColors.getCategoryColor(category.value),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    SizedBox(width: AppSizes.w8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.getTextMuted(context),
                      size: AppSizes.r20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Subcategory ───────────────────────────────────────────────────
          SizedBox(height: AppSizes.h20),
          _SectionHeader(
            title: 'Subcategory',
            icon: Icons.layers_rounded,
            trailing: subcategory.value != 'All'
                ? GestureDetector(
                    onTap: () => subcategory.value = 'All',
                    child: Text(
                      'Clear',
                      style: AppTextStyles.small(
                        context,
                        color: AppColors.error,
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(height: AppSizes.h8),
          Opacity(
            opacity: category.value == 'All' ? 0.4 : 1.0,
            child: _FilterCard(
              child: InkWell(
                borderRadius: AppSizes.cardBorderRadius,
                onTap: category.value == 'All' ? null : showSubcategorySheet,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.w16,
                    vertical: AppSizes.h(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(AppSizes.r8),
                        decoration: BoxDecoration(
                          color:
                              (category.value == 'All'
                                      ? AppColors.primary
                                      : AppColors.getCategoryColor(
                                          category.value,
                                        ))
                                  .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.layers_rounded,
                          color: category.value == 'All'
                              ? AppColors.primary
                              : AppColors.getCategoryColor(category.value),
                          size: AppSizes.r16,
                        ),
                      ),
                      SizedBox(width: AppSizes.w12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Subcategory',
                              style: AppTextStyles.small(
                                context,
                                color: AppColors.getTextMuted(context),
                              ),
                            ),
                            SizedBox(height: AppSizes.h(2)),
                            Text(
                              category.value == 'All'
                                  ? 'Select a category first'
                                  : subcategoryLabel,
                              style: AppTextStyles.body(
                                context,
                                color: category.value == 'All'
                                    ? AppColors.getTextMuted(context)
                                    : (subcategory.value == 'All'
                                          ? AppColors.getText(context)
                                          : AppColors.getCategoryColor(
                                              category.value,
                                            )),
                                fontWeight: subcategory.value == 'All'
                                    ? FontWeight.w400
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (subcategory.value != 'All')
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSizes.w(6),
                            vertical: AppSizes.h(2),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.getCategoryColor(
                              category.value,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppSizes.r4),
                          ),
                          child: Text(
                            'Active',
                            style: AppTextStyles.small(
                              context,
                              color: AppColors.getCategoryColor(category.value),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      SizedBox(width: AppSizes.w8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.getTextMuted(context),
                        size: AppSizes.r20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: AppSizes.h20),

          // ── Bank Name ─────────────────────────────────────────────────────
          _SectionHeader(
            title: 'Bank Name',
            icon: Icons.account_balance_rounded,
            trailing: bankId.value != null
                ? GestureDetector(
                    onTap: () => bankId.value = null,
                    child: Text(
                      'Clear',
                      style: AppTextStyles.small(
                        context,
                        color: AppColors.error,
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(height: AppSizes.h8),
          _FilterCard(
            child: BankPickerWidget(
              selectedBankId: bankId,
              customBankController: customBankController,
            ),
          ),

          SizedBox(height: AppSizes.h20),

          // ── Payment Method ────────────────────────────────────────────────
          _SectionHeader(
            title: 'Payment Method',
            icon: Icons.payment_rounded,
            trailing: paymentMethodId.value != null
                ? GestureDetector(
                    onTap: () => paymentMethodId.value = null,
                    child: Text(
                      'Clear',
                      style: AppTextStyles.small(
                        context,
                        color: AppColors.error,
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(height: AppSizes.h8),
          _FilterCard(
            child: PaymentMethodPickerWidget(
              selectedPaymentMethodId: paymentMethodId,
              customPaymentController: customPaymentController,
            ),
          ),
          SizedBox(height: AppSizes.h20),
          const BannerAdWidget(),
          SizedBox(height: AppSizes.h(100)),
        ],
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
                child: OutlinedButton.icon(
                  onPressed: resetFilters,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                    padding: EdgeInsets.symmetric(vertical: AppSizes.h(14)),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSizes.cardBorderRadius,
                    ),
                    textStyle: AppTextStyles.body(context),
                  ),
                ),
              ),
              SizedBox(width: AppSizes.w12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: isSyncing.value ? null : applyFilters,
                  icon: isSyncing.value 
                      ? SizedBox(
                          height: AppSizes.r20,
                          width: AppSizes.r20,
                          child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(isSyncing.value ? 'Syncing...' : 'Apply Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: AppSizes.h(14)),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSizes.cardBorderRadius,
                    ),
                    textStyle: AppTextStyles.body(
                      context,
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    BuildContext context,
    String label,
    TransactionType? type,
    Color color,
    ValueNotifier<TransactionType?> selectedType,
    ValueNotifier<String> selectedCategory,
    ValueNotifier<String> selectedSubcategory,
    AsyncValue<List<dynamic>> subcategoriesAsync,
  ) {
    final isSelected = selectedType.value == type;
    return GestureDetector(
      onTap: () {
        if (selectedType.value != type) {
          selectedType.value = type;
          if (type != null) {
            final isIncome = type == TransactionType.credit;
            final allSubs = subcategoriesAsync.value ?? const [];

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

            final customIncome = allSubs
                .where((s) => s.isIncome && s.isCustom)
                .map((s) => s.parentCategory)
                .toSet();
            final customExpense = allSubs
                .where((s) => !s.isIncome && s.isCustom)
                .map((s) => s.parentCategory)
                .toSet();

            final validCategories = isIncome
                ? {...defaultIncomeCategories, ...customIncome}
                : {...defaultExpenseCategories, ...customExpense};

            if (!validCategories.contains(selectedCategory.value)) {
              selectedCategory.value = 'All';
              selectedSubcategory.value = 'All';
            }
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
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.body(
            context,
            color: AppColors.getText(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _FilterCard extends StatelessWidget {
  final Widget child;
  const _FilterCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerLowestDark : AppColors.white,
        borderRadius: AppSizes.cardBorderRadius,
        border: Border.all(
          color: isDark
              ? AppColors.white.withValues(alpha: 0.06)
              : AppColors.black.withValues(alpha: 0.06),
        ),
      ),
      child: child,
    );
  }
}
