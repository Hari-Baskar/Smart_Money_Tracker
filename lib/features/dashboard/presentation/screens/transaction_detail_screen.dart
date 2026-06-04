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
import 'package:smart_money_tracker/core/utils/app_toast.dart';
import 'package:intl/intl.dart';

import '../providers/subcategory_provider.dart';

import '../widgets/bank_picker_widget.dart';
import '../widgets/payment_method_picker_widget.dart';
import '../widgets/split_summary_widget.dart';
import '../widgets/split_item_widget.dart';
import '../widgets/txn_category_picker_sheet.dart';
import '../widgets/txn_subcategory_picker_sheet.dart';

class TransactionDetailScreen extends HookConsumerWidget {
  final TransactionModel transaction;
  const TransactionDetailScreen({super.key, required this.transaction});

  static const List<String> _expenseCategories = [
    'Bills',
    'Entertainment',
    'Food',
    'Groceries',
    'Health',
    'Investment',
    'Other',
    'Shopping',
    'Travel',
    'Unknown',
  ];

  static const List<String> _incomeCategories = ['Salary', 'Unknown'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantController = useTextEditingController(
      text: transaction.merchant,
    );
    final amountController = useTextEditingController(
      text: transaction.amount.toStringAsFixed(2),
    );
    final selectedDate = useState(transaction.date);
    final selectedCategory = useState(transaction.category);
    final selectedSubcategory = useState(transaction.subcategory);
    final splits = useState<List<TransactionSplit>>(
      List.from(transaction.splits),
    );
    final splitControllers = useState<List<TextEditingController>>([]);
    final isSaving = useState(false);
    final isMounted = useIsMounted();

    final initialBankId = useMemoized(() {
      final id = transaction.bankId;
      if (id == null) return null;
      if (id.startsWith('custom:')) return 'custom';
      return id;
    });

    final initialCustomBank = useMemoized(() {
      final id = transaction.bankId;
      if (id != null && id.startsWith('custom:')) return id.substring(7);
      return '';
    });

    final initialPaymentId = useMemoized(() {
      final id = transaction.paymentMethodId;
      if (id == null) return null;
      if (id.startsWith('custom:')) return 'custom';
      return id;
    });

    final initialCustomPayment = useMemoized(() {
      final id = transaction.paymentMethodId;
      if (id != null && id.startsWith('custom:')) return id.substring(7);
      return '';
    });

    final selectedBankId = useState<String?>(initialBankId);
    final customBankController = useTextEditingController(
      text: initialCustomBank,
    );

    final selectedPaymentMethodId = useState<String?>(initialPaymentId);
    final customPaymentController = useTextEditingController(
      text: initialCustomPayment,
    );

    // Register rebuild triggers for custom bank and payment method changes
    final _ = selectedBankId.value;
    final __ = selectedPaymentMethodId.value;

    useEffect(() {
      splitControllers.value = transaction.splits
          .map(
            (s) => TextEditingController(
              text: s.amount > 0 ? s.amount.toString() : '',
            ),
          )
          .toList();
      return () {
        for (var controller in splitControllers.value) {
          controller.dispose();
        }
      };
    }, [transaction.id]);

    Future<void> selectDateTime(
      DateTime initialDate,
      Function(DateTime) onPicked,
    ) async {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
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
          initialTime: TimeOfDay.fromDateTime(initialDate),
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
          onPicked(
            DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            ),
          );
        }
      }
    }

    void addSplit() {
      final newList = List<TransactionSplit>.from(splits.value);
      newList.add(
        TransactionSplit(
          amount: 0,
          category: 'Other',
          date: selectedDate.value,
        ),
      );
      splits.value = newList;

      final newControllers = List<TextEditingController>.from(
        splitControllers.value,
      );
      newControllers.add(TextEditingController());
      splitControllers.value = newControllers;
    }

    Future<void> saveChanges() async {
      isSaving.value = true;
      try {
        final authState = ref.read(authStateProvider);
        final userId = authState.value?.id;
        if (userId == null) return;

        final totalAmount = double.tryParse(amountController.text) ?? 0.0;
        final totalSplit = splits.value.fold(
          0.0,
          (sum, item) => sum + item.amount,
        );

        if (totalSplit > totalAmount + 0.01) {
          AppToast.show(context, 'Split exceeds total', isError: true);
          isSaving.value = false;
          return;
        }

        final repository = ref.read(transactionRepositoryProvider);
        final subcategories = ref.read(subcategoriesProvider).value ?? const [];

        String getMappedCategoryId(String catName) => catName;
        String getMappedSubcategoryId(String catName, String subName) => subName;

        final mappedCategoryId = getMappedCategoryId(selectedCategory.value);
        final mappedSubcategoryId = getMappedSubcategoryId(
          selectedCategory.value,
          selectedSubcategory.value,
        );

        final finalBankId = selectedBankId.value == 'custom'
            ? 'custom:${customBankController.text.trim()}'
            : selectedBankId.value;

        final finalPaymentMethodId = selectedPaymentMethodId.value == 'custom'
            ? 'custom:${customPaymentController.text.trim()}'
            : selectedPaymentMethodId.value;

        final resolvedSplits = splits.value
            .where((split) => split.amount > 0)
            .map(
              (split) => TransactionSplit(
                amount: split.amount,
                category: getMappedCategoryId(split.category),
                subcategory: getMappedSubcategoryId(
                  split.category,
                  split.subcategory,
                ),
                notes: split.notes,
                date: split.date ?? selectedDate.value,
              ),
            )
            .toList();

        final updatedTransaction = transaction.copyWith(
          merchant: merchantController.text,
          amount: totalAmount,
          date: selectedDate.value,
          category: mappedCategoryId,
          subcategory: mappedSubcategoryId,
          splits: resolvedSplits,
          isEdited: true,
          bankId: finalBankId?.isEmpty == true ? null : finalBankId,
          paymentMethodId: finalPaymentMethodId?.isEmpty == true
              ? null
              : finalPaymentMethodId,
        );
        await repository.saveTransaction(userId, updatedTransaction);

        if (isMounted()) {
          Navigator.pop(context);
          AppToast.show(context, 'Saved');
        }
      } catch (e) {
        if (isMounted()) {
          AppToast.show(context, 'Save failed', isError: true);
        }
      } finally {
        if (isMounted()) isSaving.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: Theme.of(context).colorScheme.onBackground,
            size: 24.r,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Transaction', style: AppTextStyles.heading(context)),
        actions: [
          IconButton(
            onPressed: () async {
              final shouldDelete = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  title: const Text('Delete Transaction'),
                  content: const Text(
                    'Are you sure you want to delete this transaction?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (shouldDelete == true) {
                await ref
                    .read(transactionSyncProvider.notifier)
                    .deleteTransaction(transaction.id);
                if (isMounted()) {
                  Navigator.pop(context);
                  AppToast.show(context, 'Transaction deleted');
                }
              }
            },
            icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
          ),
          TextButton(
            onPressed: isSaving.value ? null : saveChanges,
            child: isSaving.value
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    'Total Amount',
                    style: AppTextStyles.body(
                      context,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: AppSizes.h8),
                  IntrinsicWidth(
                    child: TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading(
                        context,
                        color: AppColors.primary,
                      ),
                      decoration: const InputDecoration(
                        prefixText: '₹',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSizes.h40),

            _buildSectionTitle(context, 'General Info'),
            _buildInfoCard(context, [
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
              ),
              _buildSubcategoryPicker(
                context,
                ref,
                selectedCategory,
                selectedSubcategory,
              ),
              _buildBankPicker(context, selectedBankId, customBankController),
              _buildPaymentMethodPicker(
                context,
                selectedPaymentMethodId,
                customPaymentController,
              ),
              _buildDateField(context, selectedDate, selectDateTime),
            ]),

            SizedBox(height: AppSizes.h32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle(context, 'Split Transaction'),
                IconButton(
                  onPressed: addSplit,
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.primary,
                    size: AppSizes.r24,
                  ),
                ),
              ],
            ),

            if (splits.value.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
                child: Text(
                  'No splits added. Tap the + icon to split this expense.',
                  style: AppTextStyles.small(
                    context,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else ...[
              ...splits.value.asMap().entries.map(
                (entry) => SplitItemWidget(
                  index: entry.key,
                  split: entry.value,
                  splits: splits,
                  splitControllers: splitControllers,
                  selectDateTime: selectDateTime,
                  isIncome: transaction.type == TransactionType.credit,
                  expenseCategories: _expenseCategories,
                  incomeCategories: _incomeCategories,
                ),
              ),
              _buildSplitSummary(context, splits, amountController),
            ],

            SizedBox(height: AppSizes.h32),
            _buildSectionTitle(context, 'Original SMS'),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSizes.r16),
              decoration: BoxDecoration(
                color: AppColors.getSurfaceContainerLowest(context),
                borderRadius: AppSizes.cardBorderRadius,
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
              child: Text(
                transaction.rawSms,
                style: AppTextStyles.small(
                  context,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(height: AppSizes.h40),
          ],
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainerLowest(context),
        borderRadius: AppSizes.cardBorderRadius,
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
      child: Column(children: children),
    );
  }

  Widget _buildEditField(
    BuildContext context,
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Padding(
      padding: EdgeInsets.all(AppSizes.r16),
      child: Row(
        children: [
          Container(
            width: AppSizes.r(36),
            height: AppSizes.r(36),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: AppSizes.r20),
          ),
          SizedBox(width: AppSizes.w16),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTextStyles.body(context),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: AppTextStyles.small(
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
  ) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        final isIncome = transaction.type == TransactionType.credit;
        final catColor = AppColors.getCategoryColor(selectedCategory.value);
        final catBg = AppColors.getCategoryBgColor(
          context,
          selectedCategory.value,
        );

        final displayCategoryName = categories.firstWhere(
          (c) => c.id == selectedCategory.value,
          orElse: () => CategoryModel(id: selectedCategory.value, name: selectedCategory.value),
        ).name;

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
          child: Padding(
            padding: EdgeInsets.all(AppSizes.r16),
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
                        style: AppTextStyles.small(
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
  ) {
    final subcategoriesAsync = ref.watch(subcategoriesProvider);

    return subcategoriesAsync.when(
      data: (allSubs) {
        final isIncome = transaction.type == TransactionType.credit;
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
              isIncome: isIncome,
            ),
          ),
          borderRadius: AppSizes.boxBorderRadius,
          child: Padding(
            padding: EdgeInsets.all(AppSizes.r16),
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
                        style: AppTextStyles.small(
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
    Function(DateTime, Function(DateTime)) selectDateTime,
  ) {
    return GestureDetector(
      onTap: () => selectDateTime(selectedDate.value, (dt) {
        selectedDate.value = dt;
      }),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.r16),
        child: Row(
          children: [
            Container(
              width: AppSizes.r(36),
              height: AppSizes.r(36),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: AppColors.primary,
                size: AppSizes.r20,
              ),
            ),
            SizedBox(width: AppSizes.w16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date & Time',
                  style: AppTextStyles.small(
                    context,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  DateFormat(
                    'MMM dd, yyyy • hh:mm a',
                  ).format(selectedDate.value),
                  style: AppTextStyles.body(context),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.edit_rounded,
              color: AppColors.primary,
              size: AppSizes.r16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitItem(
    BuildContext context,
    WidgetRef ref,
    int index,
    TransactionSplit split,
    ValueNotifier<List<TransactionSplit>> splits,
    ValueNotifier<List<TextEditingController>> splitControllers,
    Function(DateTime, Function(DateTime)) selectDateTime,
  ) {
    return const SizedBox.shrink();
  }

  void _showCategoryBottomSheetForSplit(
    BuildContext context,
    WidgetRef ref,
    int index,
    ValueNotifier<List<TransactionSplit>> splits,
    TransactionSplit split,
  ) {
    final isIncome = transaction.type == TransactionType.credit;
    final categoriesAsync = ref.read(categoriesProvider);
    final allCategories = categoriesAsync.value
            ?.where((c) => c.isIncome == isIncome)
            .toList() ??
        <CategoryModel>[];
    allCategories.sort((a, b) => a.name.compareTo(b.name));

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
                  itemCount: allCategories.length + 1,
                  itemBuilder: (context, indexGrid) {
                    // Last item: Add Custom
                    if (indexGrid == allCategories.length) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showAddCategoryDialog(
                            context,
                            ref,
                            isIncome: isIncome,
                            onAdded: (cat) {
                              final newList = List<TransactionSplit>.from(
                                splits.value,
                              );
                              newList[index] = TransactionSplit(
                                amount: split.amount,
                                category: cat.id,
                                subcategory: 'General',
                                notes: split.notes,
                              );
                              splits.value = newList;
                            },
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
                                style: AppTextStyles.small(
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

                    final catModel = allCategories[indexGrid];
                    final isSelected = split.category == catModel.id;
                    final catColor = AppColors.getCategoryColor(catModel.id);
                    final catBg = AppColors.getCategoryBgColor(context, catModel.id);

                    return GestureDetector(
                      onTap: () {
                        final newList = List<TransactionSplit>.from(
                          splits.value,
                        );
                        newList[index] = TransactionSplit(
                          amount: split.amount,
                          category: catModel.id,
                          subcategory: 'General',
                          notes: split.notes,
                        );
                        splits.value = newList;
                        Navigator.pop(context);
                      },
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: AppSizes.r(44),
                              height: AppSizes.r(44),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark
                                          ? AppColors.black.withOpacity(0.2)
                                          : AppColors.white)
                                    : catBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                AppColors.getCategoryIcon(catModel.id),
                                color: catColor,
                                size: AppSizes.r24,
                              ),
                            ),
                            SizedBox(height: AppSizes.h8),
                            Text(
                              catModel.name,
                              style: AppTextStyles.small(
                                context,
                                color: isSelected
                                    ? (isDark ? AppColors.white : catColor)
                                    : AppColors.getText(context),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

  Widget _buildSplitSubcategoryPickerWidget(
    BuildContext context,
    WidgetRef ref,
    int index,
    TransactionSplit split,
    ValueNotifier<List<TransactionSplit>> splits,
  ) {
    final subcategoriesAsync = ref.watch(subcategoriesProvider);
    final isDark = AppColors.isDark(context);
    final catColor = AppColors.getCategoryColor(split.category);

    return subcategoriesAsync.when(
      data: (allSubs) {
        final filteredSubs = allSubs
            .where((s) => s.parentCategoryId == split.category)
            .toList();

        // Check if selected subcategory exists in filtered list, if not add a temporary placeholder model
        final hasSelected = filteredSubs.any((s) => s.id == split.subcategory);
        if (!hasSelected) {
          filteredSubs.add(SubcategoryModel(
            id: split.subcategory,
            name: split.subcategory, // using raw value as fallback name
            parentCategoryId: split.category,
          ));
        }

        filteredSubs.sort((a, b) => a.name.compareTo(b.name));

        final selectedSubModel = allSubs.firstWhere(
          (s) => s.id == split.subcategory,
          orElse: () => SubcategoryModel(
            id: split.subcategory,
            name: split.subcategory,
            parentCategoryId: split.category,
          ),
        );

        return InkWell(
          onTap: () {
            _showSubcategoryBottomSheetForSplit(
              context,
              ref,
              index,
              splits,
              split,
              filteredSubs,
            );
          },
          borderRadius: AppSizes.boxBorderRadius,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.w12,
              vertical: AppSizes.h(10),
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.white.withOpacity(0.03)
                  : AppColors.black.withOpacity(0.02),
              border: Border.all(
                color: isDark
                    ? AppColors.white.withOpacity(0.08)
                    : AppColors.black.withOpacity(0.06),
              ),
              borderRadius: AppSizes.boxBorderRadius,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedSubModel.name,
                    style: AppTextStyles.small(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: AppSizes.r16,
                  color: catColor,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        height: AppSizes.h(38),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.white.withOpacity(0.03)
              : AppColors.black.withOpacity(0.02),
          border: Border.all(
            color: isDark
                ? AppColors.white.withOpacity(0.08)
                : AppColors.black.withOpacity(0.06),
          ),
          borderRadius: AppSizes.boxBorderRadius,
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showSubcategoryBottomSheetForSplit(
    BuildContext context,
    WidgetRef ref,
    int index,
    ValueNotifier<List<TransactionSplit>> splits,
    TransactionSplit split,
    List<SubcategoryModel> subcategories,
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
              Text('Select Subcategory', style: AppTextStyles.heading(context)),
              SizedBox(height: AppSizes.h16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: subcategories.length + 1,
                  separatorBuilder: (context, idx) => Divider(
                    color: isDark
                        ? AppColors.white.withOpacity(0.05)
                        : AppColors.black.withOpacity(0.04),
                    height: 1,
                  ),
                  itemBuilder: (context, subIndex) {
                    if (subIndex == subcategories.length) {
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
                            category: split.category,
                            onAdded: (newSub) {
                              final newList = List<TransactionSplit>.from(
                                splits.value,
                              );
                              newList[index] = TransactionSplit(
                                amount: split.amount,
                                category: split.category,
                                subcategory: newSub.id,
                                notes: split.notes,
                              );
                              splits.value = newList;
                            },
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

                    final subModel = subcategories[subIndex];
                    final isSelected = split.subcategory == subModel.id;
                    final activeCatColor = AppColors.getCategoryColor(
                      split.category,
                    );

                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSizes.w8,
                        vertical: AppSizes.h4,
                      ),
                      onTap: () {
                        final newList = List<TransactionSplit>.from(
                          splits.value,
                        );
                        newList[index] = TransactionSplit(
                          amount: split.amount,
                          category: split.category,
                          subcategory: subModel.id,
                          notes: split.notes,
                        );
                        splits.value = newList;
                        Navigator.pop(context);
                      },
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
                        subModel.name,
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

  Widget _buildSplitSummary(
    BuildContext context,
    ValueNotifier<List<TransactionSplit>> splits,
    TextEditingController amountController,
  ) {
    return SplitSummaryWidget(
      splits: splits,
      amountController: amountController,
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

  void _showAddCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    required Function(CategoryModel) onAdded,
    required bool isIncome,
  }) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
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
                          hintStyle: AppTextStyles.small(
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
                                final name = controller.text.trim();
                                if (name.isNotEmpty) {
                                  await ref
                                      .read(categoriesProvider.notifier)
                                      .addCategory(
                                        name,
                                        isIncome: isIncome,
                                      );
                                  // Find the newly added category to trigger callback
                                  final cats = ref.read(categoriesProvider).value ?? [];
                                  final newCat = cats.firstWhere(
                                    (c) => c.name == name && c.isIncome == isIncome,
                                    orElse: () => CategoryModel(id: 'cat_temp', name: name),
                                  );
                                  onAdded(newCat);
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
      },
    );
  }

  void _showAddSubcategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    required String category,
    required Function(SubcategoryModel) onAdded,
    bool isIncome = false,
  }) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
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
                      SizedBox(height: AppSizes.h16),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        style: AppTextStyles.body(context),
                        maxLength: 20,
                        decoration: InputDecoration(
                          hintText: 'Enter name (e.g. Netflix, Gym)',
                          hintStyle: AppTextStyles.small(
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
                                final name = controller.text.trim();
                                if (name.isNotEmpty) {
                                  await ref
                                      .read(subcategoriesProvider.notifier)
                                      .addSubcategory(
                                        name,
                                        category,
                                        isIncome: isIncome,
                                      );
                                  // Find the newly added subcategory
                                  final subs = ref.read(subcategoriesProvider).value ?? [];
                                  final newSub = subs.firstWhere(
                                    (s) => s.name == name && s.parentCategoryId == category,
                                    orElse: () => SubcategoryModel(id: 'sub_temp', name: name, parentCategoryId: category),
                                  );
                                  onAdded(newSub);
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
      },
    );
  }
}
