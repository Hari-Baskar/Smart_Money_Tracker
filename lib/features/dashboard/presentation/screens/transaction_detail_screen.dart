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
import 'package:smart_money_tracker/core/constants/payment_constants.dart';

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

  static const List<String> _incomeCategories = [
    'Salary',
    'Unknown',
  ];

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
    final customBankController = useTextEditingController(text: initialCustomBank);
    
    final selectedPaymentMethodId = useState<String?>(initialPaymentId);
    final customPaymentController = useTextEditingController(text: initialCustomPayment);

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
                      onPrimary: Colors.white,
                      primaryContainer: Color(0xFF004D25),
                      onPrimaryContainer: Colors.white,
                      surface: AppColors.surfaceDark,
                      onSurface: Colors.white,
                    )
                  : const ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: Colors.white,
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
                        onPrimary: Colors.white,
                        primaryContainer: Color(0xFF004D25),
                        onPrimaryContainer: Colors.white,
                        surface: AppColors.surfaceDark,
                        onSurface: Colors.white,
                      )
                    : const ColorScheme.light(
                        primary: AppColors.primary,
                        onPrimary: Colors.white,
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

        String getMappedCategoryId(String catName) {
          if (_isDefaultCategory(catName)) {
            return catName;
          }
          final match = subcategories.firstWhere(
            (sub) => sub.isCustom && sub.name == 'General' && sub.parentCategory == catName,
            orElse: () => SubcategoryModel(id: '', name: '', parentCategory: ''),
          );
          return match.id.isNotEmpty ? match.id : catName;
        }

        String getMappedSubcategoryId(String catName, String subName) {
          final catId = getMappedCategoryId(catName);
          final match = subcategories.firstWhere(
            (sub) => sub.name == subName && 
                (sub.parentCategory == catName || sub.parentCategory == catId),
            orElse: () => SubcategoryModel(id: '', name: '', parentCategory: ''),
          );
          return match.id.isNotEmpty ? match.id : subName;
        }

        final mappedCategoryId = getMappedCategoryId(selectedCategory.value);
        final mappedSubcategoryId = getMappedSubcategoryId(selectedCategory.value, selectedSubcategory.value);

        final finalBankId = selectedBankId.value == 'custom'
            ? 'custom:${customBankController.text.trim()}'
            : selectedBankId.value;

        final finalPaymentMethodId = selectedPaymentMethodId.value == 'custom'
            ? 'custom:${customPaymentController.text.trim()}'
            : selectedPaymentMethodId.value;

        final resolvedSplits = splits.value
            .where((split) => split.amount > 0)
            .map((split) => TransactionSplit(
                  amount: split.amount,
                  category: getMappedCategoryId(split.category),
                  subcategory: getMappedSubcategoryId(split.category, split.subcategory),
                  notes: split.notes,
                  date: split.date ?? selectedDate.value,
                ))
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
          paymentMethodId: finalPaymentMethodId?.isEmpty == true ? null : finalPaymentMethodId,
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: Theme.of(context).colorScheme.onBackground,
            size: 24.r,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Transaction', style: AppTextStyles.headline(context)),
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.r24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    'Total Amount',
                    style: AppTextStyles.small(
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
                      style: AppTextStyles.display(
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
                (entry) => _buildSplitItem(
                  context,
                  ref,
                  entry.key,
                  entry.value,
                  splits,
                  splitControllers,
                  selectDateTime,
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
                        ? Colors.black.withOpacity(0.2)
                        : Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: AppColors.isDark(context)
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03),
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
        style: AppTextStyles.small(
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
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.isDark(context)
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
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
          Icon(icon, color: AppColors.primary, size: AppSizes.r20),
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
    final subcategoriesAsync = ref.watch(subcategoriesProvider);

    return subcategoriesAsync.when(
      data: (allSubs) {
        final isIncome = transaction.type == TransactionType.credit;
        final defaultCats = isIncome ? _incomeCategories : _expenseCategories;
        final categories = allSubs
            .where((s) => s.isIncome == isIncome)
            .map((s) => s.parentCategory)
            .toSet()
            .toList();
        final mergedCategories = {...defaultCats, ...categories}.toList();
        mergedCategories.sort();

        final catColor = AppColors.getCategoryColor(selectedCategory.value);
        final catBg = AppColors.getCategoryBgColor(
          context,
          selectedCategory.value,
        );

        return InkWell(
          onTap: () => _showCategoryBottomSheet(
            context,
            ref,
            selectedCategory,
            selectedSubcategory,
            mergedCategories,
          ),
          borderRadius: BorderRadius.circular(AppSizes.r16),
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
                        selectedCategory.value.length > 13
                            ? '${selectedCategory.value.substring(0, 11)}...'
                            : selectedCategory.value,
                        style: AppTextStyles.body(
                          context,
                          fontWeight: FontWeight.bold,
                        ),
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
            .where((s) => s.parentCategory == selectedCategory.value && s.isIncome == isIncome)
            .toList();

        if (!filteredSubs.any((s) => s.name == selectedSubcategory.value)) {
          filteredSubs.add(SubcategoryModel(
            id: 'temp',
            name: selectedSubcategory.value,
            parentCategory: selectedCategory.value,
            isCustom: false,
            isIncome: isIncome,
          ));
        }

        filteredSubs.sort((a, b) => a.name.compareTo(b.name));

        final catColor = AppColors.getCategoryColor(selectedCategory.value);
        final catBg = AppColors.getCategoryBgColor(
          context,
          selectedCategory.value,
        );

        return InkWell(
          onTap: () => _showSubcategoryBottomSheet(
            context,
            ref,
            selectedCategory.value,
            selectedSubcategory,
            filteredSubs,
            isIncome: isIncome,
          ),
          borderRadius: BorderRadius.circular(AppSizes.r16),
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
                        selectedSubcategory.value,
                        style: AppTextStyles.body(
                          context,
                          fontWeight: FontWeight.bold,
                        ),
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
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Text(
                'Select Category',
                style: AppTextStyles.headline(
                  context,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                    // Last item: Add Custom
                    if (index == categories.length) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showAddCategoryDialog(
                            context,
                            ref,
                            isIncome: transaction.type == TransactionType.credit,
                            onAdded: (name) {
                              selectedCategory.value = name;
                              selectedSubcategory.value = 'General';
                            },
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.15)
                                  : Colors.black.withOpacity(0.1),
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
                                  fontWeight: FontWeight.bold,
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
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isSelected
                                ? catColor
                                : (isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.black.withOpacity(0.04)),
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
                                                ? Colors.black.withOpacity(0.2)
                                                : Colors.white)
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
                                    cat.length > 13 ? '${cat.substring(0, 11)}...' : cat,
                                    style: AppTextStyles.small(
                                      context,
                                      color: isSelected
                                          ? (isDark ? Colors.white : catColor)
                                          : AppColors.getText(context),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
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
    return const ['Food', 'Travel', 'Shopping', 'Bills', 'Entertainment', 'Health', 'Investment', 'Other', 'Salary'].contains(category);
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                          ? Colors.white.withOpacity(0.12)
                          : Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                Text(
                  'Manage Category',
                  style: AppTextStyles.headline(
                    context,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                    child: Icon(Icons.edit_rounded, color: AppColors.primary, size: AppSizes.r20),
                  ),
                  title: Text(
                    'Rename Category',
                    style: AppTextStyles.body(context, fontWeight: FontWeight.w600),
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
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.04),
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(AppSizes.r8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delete_forever_rounded, color: AppColors.error, size: AppSizes.r20),
                  ),
                  title: Text(
                    'Delete Category',
                    style: AppTextStyles.body(context, fontWeight: FontWeight.w600, color: AppColors.error),
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                            ? Colors.white.withOpacity(0.12)
                            : Colors.black.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  Text(
                    'Rename Category',
                    style: AppTextStyles.headline(
                      context,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSizes.h16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: AppTextStyles.body(context),
                    maxLength: 15,
                    decoration: InputDecoration(
                      hintText: 'Enter new category name',
                      hintStyle: AppTextStyles.small(
                        context,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.category_rounded,
                        color: AppColors.primary,
                        size: AppSizes.r20,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.r16),
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
                            padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.body(
                              context,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.r12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Save',
                            style: AppTextStyles.body(
                              context,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                          ? Colors.white.withOpacity(0.12)
                          : Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(2.r),
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
                  style: AppTextStyles.headline(context, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.h12),
                Text(
                  'This will permanently delete the custom category "$categoryName" and all of its custom subcategories. This action cannot be undone.',
                  style: AppTextStyles.body(context, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.r12),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: AppTextStyles.body(
                            context,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
    WidgetRef ref, {
    required Function(String) onAdded,
    bool isIncome = false,
  }) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                            ? Colors.white.withOpacity(0.12)
                            : Colors.black.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  Text(
                    'New Main Category',
                    style: AppTextStyles.headline(
                      context,
                      fontWeight: FontWeight.bold,
                    ),
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.category_rounded,
                        color: AppColors.primary,
                        size: AppSizes.r20,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.r16),
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
                            padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.body(
                              context,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                  .addSubcategory('General', name, isIncome: isIncome);
                              onAdded(name);
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.r12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Add',
                            style: AppTextStyles.body(
                              context,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Subcategory',
                    style: AppTextStyles.headline(
                      context,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.h16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: subcategories.length + 1,
                  separatorBuilder: (context, index) => Divider(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.04),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    if (index == subcategories.length) {
                      // Custom Add button
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
                            category: parentCategory,
                            onAdded: (name) => selectedSubcategory.value = name,
                            isIncome: isIncome,
                          );
                        },
                        leading: Container(
                          width: AppSizes.r(36),
                          height: AppSizes.r(36),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10.r),
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
                            fontWeight: FontWeight.bold,
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
                          borderRadius: BorderRadius.circular(10.r),
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
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                          ? Colors.white.withOpacity(0.12)
                          : Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                Text(
                  'Manage Subcategory',
                  style: AppTextStyles.headline(
                    context,
                    fontWeight: FontWeight.bold,
                  ),
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
                    child: Icon(Icons.edit_rounded, color: AppColors.primary, size: AppSizes.r20),
                  ),
                  title: Text(
                    'Rename Subcategory',
                    style: AppTextStyles.body(context, fontWeight: FontWeight.w600),
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
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.04),
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(AppSizes.r8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delete_forever_rounded, color: AppColors.error, size: AppSizes.r20),
                  ),
                  title: Text(
                    'Delete Subcategory',
                    style: AppTextStyles.body(context, fontWeight: FontWeight.w600, color: AppColors.error),
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                            ? Colors.white.withOpacity(0.12)
                            : Colors.black.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  Text(
                    'Rename Subcategory',
                    style: AppTextStyles.headline(
                      context,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSizes.h4),
                  Text(
                    'For ${sub.parentCategory}',
                    style: AppTextStyles.small(
                      context,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
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
                      hintStyle: AppTextStyles.small(
                        context,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.subdirectory_arrow_right_rounded,
                        color: AppColors.primary,
                        size: AppSizes.r20,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.r16),
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
                            padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.body(
                              context,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                Navigator.pop(context); // Close rename subcategory bottom sheet modal
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.r12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Save',
                            style: AppTextStyles.body(
                              context,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                          ? Colors.white.withOpacity(0.12)
                          : Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(2.r),
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
                  style: AppTextStyles.headline(context, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.h12),
                Text(
                  'This will permanently delete the custom subcategory "${sub.name}". This action cannot be undone.',
                  style: AppTextStyles.body(context, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                            Navigator.pop(context); // Close bottom sheet confirmation modal
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: AppSizes.h16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.r12),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: AppTextStyles.body(
                            context,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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

  void _showAddSubcategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    required String category,
    required Function(String) onAdded,
    bool isIncome = false,
  }) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                            ? Colors.white.withOpacity(0.12)
                            : Colors.black.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  Text(
                    'New Subcategory',
                    style: AppTextStyles.headline(
                      context,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSizes.h4),
                  Text(
                    'For $category',
                    style: AppTextStyles.small(
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
                        borderRadius: BorderRadius.circular(AppSizes.r16),
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
                                  .addSubcategory(name, category, isIncome: isIncome);
                              onAdded(name);
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: AppSizes.h16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.r12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Add',
                            style: AppTextStyles.body(
                              context,
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
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
            Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: AppSizes.r20,
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
    final isDark = AppColors.isDark(context);
    final catColor = AppColors.getCategoryColor(split.category);
    final catBg = AppColors.getCategoryBgColor(context, split.category);
    final formattedDate = split.date != null 
        ? DateFormat('MMM dd, hh:mm a').format(split.date!)
        : 'Select Time';

    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.h16),
      padding: EdgeInsets.all(AppSizes.r16),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainerLowest(context),
        borderRadius: BorderRadius.circular(AppSizes.r20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : AppColors.primary.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Split number & Delete button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: AppSizes.r(24),
                    height: AppSizes.r(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: AppTextStyles.small(
                          context,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSizes.w8),
                  Text(
                    'Split Transaction',
                    style: AppTextStyles.body(
                      context,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getText(context),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  final newList = List<TransactionSplit>.from(splits.value);
                  newList.removeAt(index);
                  splits.value = newList;

                  final newControllers = List<TextEditingController>.from(
                    splitControllers.value,
                  );
                  newControllers[index].dispose();
                  newControllers.removeAt(index);
                  splitControllers.value = newControllers;
                },
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error.withOpacity(0.8),
                  size: AppSizes.r(22),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          Divider(
            height: AppSizes.h20,
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
          ),

          // Pickers Row: Category (and optionally Subcategory)
          Row(
            children: [
              // Category Picker
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: AppTextStyles.small(
                        context,
                        color: AppColors.getTextMuted(context),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSizes.h(6)),
                    InkWell(
                      onTap: () {
                        _showCategoryBottomSheetForSplit(
                          context,
                          ref,
                          index,
                          splits,
                          split,
                        );
                      },
                      borderRadius: BorderRadius.circular(AppSizes.r12),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.w12,
                          vertical: AppSizes.h(10),
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                          ),
                          borderRadius: BorderRadius.circular(AppSizes.r12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.all(AppSizes.r(4)),
                              decoration: BoxDecoration(
                                color: catBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                AppColors.getCategoryIcon(split.category),
                                color: catColor,
                                size: AppSizes.r(14),
                              ),
                            ),
                            SizedBox(width: AppSizes.w8),
                            Expanded(
                              child: Text(
                                split.category,
                                style: AppTextStyles.small(
                                  context,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: AppSizes.r16,
                              color: AppColors.getTextMuted(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (split.category != 'Other') ...[
                SizedBox(width: AppSizes.w12),
                // Subcategory Picker
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subcategory',
                        style: AppTextStyles.small(
                          context,
                          color: AppColors.getTextMuted(context),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: AppSizes.h(6)),
                      _buildSplitSubcategoryPickerWidget(context, ref, index, split, splits),
                    ],
                  ),
                ),
              ],
            ],
          ),

          SizedBox(height: AppSizes.h16),

          // Inputs Row: Amount & Date/Time
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Amount Input Field
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: AppTextStyles.small(
                        context,
                        color: AppColors.getTextMuted(context),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSizes.h(6)),
                    Focus(
                      child: Builder(
                        builder: (context) {
                          final hasFocus = Focus.of(context).hasFocus;
                          return Container(
                            height: AppSizes.h(48),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                              border: Border.all(
                                color: hasFocus 
                                    ? AppColors.primary 
                                    : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
                                width: hasFocus ? 1.5 : 1.0,
                              ),
                              borderRadius: BorderRadius.circular(AppSizes.r12),
                            ),
                            alignment: Alignment.center,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              style: AppTextStyles.body(context, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                prefixIcon: Padding(
                                  padding: EdgeInsets.only(left: AppSizes.w12, right: AppSizes.w(6)),
                                  child: Icon(
                                    Icons.currency_rupee_rounded, 
                                    size: AppSizes.r16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                prefixIconConstraints: BoxConstraints(
                                  minWidth: AppSizes.w(28),
                                  minHeight: AppSizes.h20,
                                ),
                                hintText: '0.00',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: AppSizes.h(12),
                                ),
                              ),
                              onChanged: (val) {
                                final amount = double.tryParse(val) ?? 0;
                                final newList = List<TransactionSplit>.from(splits.value);
                                newList[index] = TransactionSplit(
                                  amount: amount,
                                  category: split.category,
                                  subcategory: split.subcategory,
                                  notes: split.notes,
                                  date: split.date,
                                );
                                splits.value = newList;
                              },
                              controller: splitControllers.value[index],
                            ),
                          );
                        }
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(width: AppSizes.w12),

              // Date/Time Button Picker
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date & Time',
                      style: AppTextStyles.small(
                        context,
                        color: AppColors.getTextMuted(context),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSizes.h(6)),
                    InkWell(
                      onTap: () => selectDateTime(split.date ?? DateTime.now(), (dt) {
                        final newList = List<TransactionSplit>.from(splits.value);
                        newList[index] = TransactionSplit(
                          amount: split.amount,
                          category: split.category,
                          subcategory: split.subcategory,
                          notes: split.notes,
                          date: dt,
                        );
                        splits.value = newList;
                      }),
                      borderRadius: BorderRadius.circular(AppSizes.r12),
                      child: Container(
                        height: AppSizes.h(48),
                        padding: EdgeInsets.symmetric(horizontal: AppSizes.w12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                          ),
                          borderRadius: BorderRadius.circular(AppSizes.r12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                formattedDate,
                                style: AppTextStyles.small(
                                  context,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.calendar_month_rounded,
                              size: AppSizes.r16,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCategoryBottomSheetForSplit(
    BuildContext context,
    WidgetRef ref,
    int index,
    ValueNotifier<List<TransactionSplit>> splits,
    TransactionSplit split,
  ) {
    final subcategoriesAsync = ref.read(subcategoriesProvider);
    final isIncome = transaction.type == TransactionType.credit;
    final defaultCats = isIncome ? _incomeCategories : _expenseCategories;
    final customCats = subcategoriesAsync.maybeWhen(
      data: (allSubs) => allSubs
          .where((s) => s.isIncome == isIncome)
          .map((s) => s.parentCategory)
          .toSet()
          .toList(),
      orElse: () => <String>[],
    );
    final allCategories = {...defaultCats, ...customCats}.toList()..sort();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Text(
                'Select Category',
                style: AppTextStyles.headline(
                  context,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                            isIncome: transaction.type == TransactionType.credit,
                            onAdded: (name) {
                              final newList = List<TransactionSplit>.from(splits.value);
                              newList[index] = TransactionSplit(
                                amount: split.amount,
                                category: name,
                                subcategory: 'General',
                                notes: split.notes,
                              );
                              splits.value = newList;
                            },
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(0.15)
                                  : Colors.black.withOpacity(0.1),
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
                                  fontWeight: FontWeight.bold,
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

                    final cat = allCategories[indexGrid];
                    final isSelected = split.category == cat;
                    final catColor = AppColors.getCategoryColor(cat);
                    final catBg = AppColors.getCategoryBgColor(context, cat);

                    return GestureDetector(
                      onTap: () {
                        final newList = List<TransactionSplit>.from(
                          splits.value,
                        );
                        newList[index] = TransactionSplit(
                          amount: split.amount,
                          category: cat,
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
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isSelected
                                ? catColor
                                : (isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.black.withOpacity(0.04)),
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
                                          ? Colors.black.withOpacity(0.2)
                                          : Colors.white)
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
                              cat,
                              style: AppTextStyles.small(
                                context,
                                color: isSelected
                                    ? (isDark ? Colors.white : catColor)
                                    : AppColors.getText(context),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
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
            .where((s) => s.parentCategory == split.category)
            .map((s) => s.name)
            .toSet()
            .toList();

        if (!filteredSubs.contains(split.subcategory)) {
          filteredSubs.add(split.subcategory);
        }

        filteredSubs.sort();

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
          borderRadius: BorderRadius.circular(AppSizes.r12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.w12,
              vertical: AppSizes.h(10),
            ),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
              ),
              borderRadius: BorderRadius.circular(AppSizes.r12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    split.subcategory,
                    style: AppTextStyles.small(
                      context,
                      fontWeight: FontWeight.bold,
                    ),
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
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
          ),
          borderRadius: BorderRadius.circular(AppSizes.r12),
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
    List<String> subcategories,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Text(
                'Select Subcategory',
                style: AppTextStyles.headline(
                  context,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSizes.h16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: subcategories.length + 1,
                  separatorBuilder: (context, index) => Divider(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.04),
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
                            onAdded: (name) {
                              final newList = List<TransactionSplit>.from(
                                splits.value,
                              );
                              newList[index] = TransactionSplit(
                                amount: split.amount,
                                category: split.category,
                                subcategory: name,
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
                            borderRadius: BorderRadius.circular(10.r),
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    final sub = subcategories[subIndex];
                    final isSelected = split.subcategory == sub;
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
                          subcategory: sub,
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
                          borderRadius: BorderRadius.circular(10.r),
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
                        sub,
                        style: AppTextStyles.body(
                          context,
                          color: isSelected
                              ? activeCatColor
                              : AppColors.getText(context),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
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
    final totalSplit = splits.value.fold(0.0, (sum, item) => sum + item.amount);
    final totalAmount = double.tryParse(amountController.text) ?? 0.0;
    final remaining = totalAmount - totalSplit;
    final isMatched = remaining.abs() < 0.01;
    final isExceeded = remaining < -0.01;

    return Container(
      margin: EdgeInsets.only(top: AppSizes.h16),
      padding: EdgeInsets.all(AppSizes.r16),
      decoration: BoxDecoration(
        color: isMatched
            ? AppColors.success.withOpacity(0.05)
            : isExceeded
            ? AppColors.error.withOpacity(0.1)
            : AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(
          color: isMatched
              ? AppColors.success.withOpacity(0.2)
              : isExceeded
              ? AppColors.error
              : AppColors.error.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isMatched
                    ? 'Splits Matched'
                    : isExceeded
                    ? 'Amount Exceeded!'
                    : 'Remaining to Split',
                style: AppTextStyles.small(
                  context,
                  color: isMatched ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isMatched ? '₹$totalSplit' : '₹${remaining.toStringAsFixed(2)}',
                style: AppTextStyles.body(
                  context,
                  color: isMatched ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (isExceeded) ...[
            SizedBox(height: AppSizes.h8),
            Text(
              'Your split total (₹${totalSplit.toStringAsFixed(2)}) is more than the original amount (₹${totalAmount.toStringAsFixed(2)}). Please reduce the split amounts.',
              style: AppTextStyles.small(context, color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBankPicker(
    BuildContext context,
    ValueNotifier<String?> selectedBankId,
    TextEditingController customBankController,
  ) {
    final bankName = PaymentConstants.getBankName(selectedBankId.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showBankBottomSheet(context, selectedBankId),
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
                    Icons.account_balance_rounded,
                    color: AppColors.primary,
                    size: AppSizes.r20,
                  ),
                ),
                SizedBox(width: AppSizes.w16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bank Name',
                        style: AppTextStyles.small(
                          context,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: AppSizes.h(2)),
                      Text(
                        selectedBankId.value == 'custom'
                            ? (customBankController.text.isEmpty
                                ? 'Custom Bank'
                                : customBankController.text)
                            : bankName,
                        style: AppTextStyles.body(context, fontWeight: FontWeight.bold),
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
        ),
        if (selectedBankId.value == 'custom')
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.w16, vertical: AppSizes.h8),
            child: _buildInlineTextField(
              context,
              controller: customBankController,
              hint: 'Enter Custom Bank Name',
              icon: Icons.edit_rounded,
            ),
          ),
      ],
    );
  }

  void _showBankBottomSheet(
    BuildContext context,
    ValueNotifier<String?> selectedBankId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(
            AppSizes.w24,
            AppSizes.h12,
            AppSizes.w24,
            AppSizes.h24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: AppSizes.w(48),
                  height: AppSizes.h4,
                  margin: EdgeInsets.only(bottom: AppSizes.h20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Text(
                'Select Bank',
                style: AppTextStyles.headline(
                  context,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSizes.h16),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.remove_circle_outline_rounded, color: Colors.grey),
                      title: Text('None', style: AppTextStyles.body(context)),
                      trailing: selectedBankId.value == null
                          ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
                          : null,
                      onTap: () {
                        selectedBankId.value = null;
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                      title: Text('Custom...', style: AppTextStyles.body(context, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      trailing: selectedBankId.value == 'custom'
                          ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
                          : null,
                      onTap: () {
                        selectedBankId.value = 'custom';
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(),
                    ...PaymentConstants.indianBanks.map((bank) {
                      final isSelected = selectedBankId.value == bank.id;
                      return ListTile(
                        leading: Icon(Icons.account_balance_rounded, color: isSelected ? AppColors.primary : Colors.grey[600]),
                        title: Text(bank.name, style: AppTextStyles.body(context, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
                            : null,
                        onTap: () {
                          selectedBankId.value = bank.id;
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodPicker(
    BuildContext context,
    ValueNotifier<String?> selectedPaymentMethodId,
    TextEditingController customPaymentController,
  ) {
    final paymentName = PaymentConstants.getPaymentMethodName(selectedPaymentMethodId.value);
    final paymentIcon = PaymentConstants.getPaymentMethodIcon(selectedPaymentMethodId.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showPaymentMethodBottomSheet(context, selectedPaymentMethodId),
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
                    selectedPaymentMethodId.value == 'custom'
                        ? Icons.edit_note_rounded
                        : paymentIcon,
                    color: AppColors.primary,
                    size: AppSizes.r20,
                  ),
                ),
                SizedBox(width: AppSizes.w16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Method',
                        style: AppTextStyles.small(
                          context,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: AppSizes.h(2)),
                      Text(
                        selectedPaymentMethodId.value == 'custom'
                            ? (customPaymentController.text.isEmpty
                                ? 'Custom Method'
                                : customPaymentController.text)
                            : paymentName,
                        style: AppTextStyles.body(context, fontWeight: FontWeight.bold),
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
        ),
        if (selectedPaymentMethodId.value == 'custom')
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.w16, vertical: AppSizes.h8),
            child: _buildInlineTextField(
              context,
              controller: customPaymentController,
              hint: 'Enter Custom Payment Method (e.g. PayPal)',
              icon: Icons.edit_rounded,
            ),
          ),
      ],
    );
  }

  void _showPaymentMethodBottomSheet(
    BuildContext context,
    ValueNotifier<String?> selectedPaymentMethodId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
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
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Text(
                'Select Payment Method',
                style: AppTextStyles.headline(
                  context,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSizes.h16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.remove_circle_outline_rounded, color: Colors.grey),
                      title: Text('None', style: AppTextStyles.body(context)),
                      trailing: selectedPaymentMethodId.value == null
                          ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
                          : null,
                      onTap: () {
                        selectedPaymentMethodId.value = null;
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                      title: Text('Custom...', style: AppTextStyles.body(context, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      trailing: selectedPaymentMethodId.value == 'custom'
                          ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
                          : null,
                      onTap: () {
                        selectedPaymentMethodId.value = 'custom';
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(),
                    ...PaymentConstants.paymentMethods.map((method) {
                      final isSelected = selectedPaymentMethodId.value == method.id;
                      return ListTile(
                        leading: Icon(method.icon, color: isSelected ? AppColors.primary : Colors.grey[600]),
                        title: Text(method.name, style: AppTextStyles.body(context, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
                            : null,
                        onTap: () {
                          selectedPaymentMethodId.value = method.id;
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInlineTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppSizes.r12),
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.body(context),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.small(context, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: AppColors.primary, size: AppSizes.r20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(AppSizes.r12),
        ),
      ),
    );
  }
}
