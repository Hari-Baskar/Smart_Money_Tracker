import 'package:expense_tracker/core/constants/app_colors.dart';
import 'package:expense_tracker/core/theme/app_text_styles.dart';
import 'package:expense_tracker/core/models/transaction_model.dart';
import 'package:expense_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_tracker/features/dashboard/presentation/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/subcategory_provider.dart';

class TransactionDetailScreen extends HookConsumerWidget {
  final TransactionModel transaction;
  const TransactionDetailScreen({super.key, required this.transaction});

  static const List<String> _categories = [
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantController = useTextEditingController(text: transaction.merchant);
    final amountController = useTextEditingController(text: transaction.amount.toStringAsFixed(2));
    final selectedDate = useState(transaction.date);
    final selectedCategory = useState(transaction.category);
    final selectedSubcategory = useState(transaction.subcategory);
    final splits = useState<List<TransactionSplit>>(List.from(transaction.splits));
    final splitControllers = useState<List<TextEditingController>>([]);
    final isSaving = useState(false);
    final isMounted = useIsMounted();

    useEffect(() {
      splitControllers.value = transaction.splits
          .map((s) => TextEditingController(text: s.amount > 0 ? s.amount.toString() : ''))
          .toList();
      return () {
        for (var controller in splitControllers.value) {
          controller.dispose();
        }
      };
    }, [transaction.id]);

    Future<void> selectDateTime(DateTime initialDate, Function(DateTime) onPicked) async {
      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate,
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
          initialTime: TimeOfDay.fromDateTime(initialDate),
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
          onPicked(DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          ));
        }
      }
    }

    void addSplit() {
      final newList = List<TransactionSplit>.from(splits.value);
      newList.add(TransactionSplit(
        amount: 0,
        category: 'Other',
        date: selectedDate.value,
      ));
      splits.value = newList;
      
      final newControllers = List<TextEditingController>.from(splitControllers.value);
      newControllers.add(TextEditingController());
      splitControllers.value = newControllers;
    }

    void removeSplit(int index) {
      final newList = List<TransactionSplit>.from(splits.value);
      newList.removeAt(index);
      splits.value = newList;

      final newControllers = List<TextEditingController>.from(splitControllers.value);
      newControllers[index].dispose();
      newControllers.removeAt(index);
      splitControllers.value = newControllers;
    }

    Future<void> saveChanges() async {
      isSaving.value = true;
      try {
        final authState = ref.read(authStateProvider);
        final userId = authState.value?.id;
        if (userId == null) return;

        final totalAmount = double.tryParse(amountController.text) ?? 0.0;
        final totalSplit = splits.value.fold(0.0, (sum, item) => sum + item.amount);

        if (totalSplit > totalAmount + 0.01) {
          Fluttertoast.showToast(
            msg: 'Split exceeds total',
            backgroundColor: AppColors.error,
            textColor: Colors.white,
          );
          isSaving.value = false;
          return;
        }

        final repository = ref.read(transactionRepositoryProvider);

        if (splits.value.isEmpty) {
          final updatedTransaction = transaction.copyWith(
            merchant: merchantController.text,
            amount: totalAmount,
            date: selectedDate.value,
            category: selectedCategory.value,
            subcategory: selectedSubcategory.value,
            splits: [],
            isEdited: true,
          );
          await repository.saveTransaction(userId, updatedTransaction);
        } else {
          final remaining = totalAmount - totalSplit;
          final originalUpdated = transaction.copyWith(
            merchant: merchantController.text,
            amount: remaining > 0 ? remaining : 0,
            date: selectedDate.value,
            category: selectedCategory.value,
            subcategory: selectedSubcategory.value,
            splits: [],
            isEdited: true,
          );
          await repository.saveTransaction(userId, originalUpdated);

          for (var split in splits.value) {
            if (split.amount <= 0) continue;

            final splitTransaction = TransactionModel(
              id: const Uuid().v4(),
              amount: split.amount,
              merchant: merchantController.text,
              date: split.date ?? selectedDate.value,
              type: transaction.type,
              category: split.category,
              subcategory: split.subcategory,
              rawSms: transaction.rawSms,
              splits: [],
              isEdited: true,
            );
            await repository.saveTransaction(userId, splitTransaction);
          }
        }

        if (isMounted()) {
          Navigator.pop(context);
          Fluttertoast.showToast(msg: 'Saved');
        }
      } catch (e) {
        if (isMounted()) {
          Fluttertoast.showToast(
            msg: 'Save failed',
            backgroundColor: AppColors.error,
            textColor: Colors.white,
          );
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
          icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onBackground, size: 24.r),
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
                  Fluttertoast.showToast(msg: 'Transaction deleted');
                }
              }
            },
            icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
          ),
          TextButton(
            onPressed: isSaving.value ? null : saveChanges,
            child: isSaving.value
                ? SizedBox(
                    width: 20.r,
                    height: 20.r,
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
        padding: EdgeInsets.all(24.r),
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
                  SizedBox(height: 8.h),
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
            SizedBox(height: 40.h),

            _buildSectionTitle(context, 'General Info'),
            _buildInfoCard(context, [
              _buildEditField(
                context,
                'Merchant',
                merchantController,
                Icons.storefront_rounded,
              ),
              _buildCategoryPicker(context, selectedCategory, selectedSubcategory),
              _buildSubcategoryPicker(context, ref, selectedCategory, selectedSubcategory),
              _buildDateField(context, selectedDate, selectDateTime),
            ]),

            SizedBox(height: 32.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle(context, 'Split Transaction'),
                IconButton(
                  onPressed: addSplit,
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.primary,
                    size: 24.r,
                  ),
                ),
              ],
            ),

            if (splits.value.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
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
                (entry) => _buildSplitItem(context, ref, entry.key, entry.value, splits, splitControllers, selectDateTime),
              ),
              _buildSplitSummary(context, splits, amountController),
            ],

            SizedBox(height: 32.h),
            _buildSectionTitle(context, 'Original SMS'),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Theme.of(context).colorScheme.surfaceVariant),
              ),
              child: Text(
                transaction.rawSms,
                style: AppTextStyles.small(context, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, left: 4.w),
      child: Text(
        title,
        style: AppTextStyles.small(context, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20.r),
          SizedBox(width: 16.w),
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

  Widget _buildCategoryPicker(BuildContext context, ValueNotifier<String> selectedCategory, ValueNotifier<String> selectedSubcategory) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          Icon(Icons.category_rounded, color: AppColors.primary, size: 20.r),
          SizedBox(width: 16.w),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCategory.value,
                isExpanded: true,
                dropdownColor: Theme.of(context).colorScheme.surface,
                items: _categories
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, style: AppTextStyles.body(context)),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    selectedCategory.value = val;
                    selectedSubcategory.value = 'General';
                  }
                },
              ),
            ),
          ),
        ],
      ),
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

        return Padding(
          padding: EdgeInsets.all(16.r),
          child: Row(
            children: [
              Icon(
                Icons.subdirectory_arrow_right_rounded,
                color: AppColors.primary,
                size: 20.r,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSubcategory.value,
                    isExpanded: true,
                    dropdownColor: Theme.of(context).colorScheme.surface,
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
                        _showAddSubcategoryDialog(
                          context,
                          ref,
                          category: selectedCategory.value,
                          onAdded: (name) => selectedSubcategory.value = name,
                        );
                      } else if (val != null) {
                        selectedSubcategory.value = val;
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showAddSubcategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    required String category,
    required Function(String) onAdded,
  }) {
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
                onAdded(name);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(BuildContext context, ValueNotifier<DateTime> selectedDate, Function(DateTime, Function(DateTime)) selectDateTime) {
    return InkWell(
      onTap: () => selectDateTime(selectedDate.value, (dt) {
        selectedDate.value = dt;
      }),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20.r),
            SizedBox(width: 16.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date & Time',
                  style: AppTextStyles.small(context, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(selectedDate.value),
                  style: AppTextStyles.body(context),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.edit_rounded, color: AppColors.primary, size: 16.r),
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
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: split.category,
                    isExpanded: true,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, style: AppTextStyles.small(context)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final newList = List<TransactionSplit>.from(splits.value);
                        newList[index] = TransactionSplit(
                          amount: split.amount,
                          category: val,
                          subcategory: 'General',
                          notes: split.notes,
                        );
                        splits.value = newList;
                      }
                    },
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 1,
                child: TextField(
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.body(context),
                  decoration: const InputDecoration(
                    prefixText: '₹',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final amount = double.tryParse(val) ?? 0;
                    final newList = List<TransactionSplit>.from(splits.value);
                    newList[index] = TransactionSplit(
                      amount: amount,
                      category: split.category,
                      subcategory: split.subcategory,
                      notes: split.notes,
                    );
                    splits.value = newList;
                  },
                  controller: splitControllers.value[index],
                ),
              ),
              IconButton(
                onPressed: () => selectDateTime(split.date ?? DateTime.now(), (dt) {
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
                icon: Icon(
                  Icons.access_time_rounded,
                  color: split.date != null ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  size: 20.r,
                ),
              ),
              IconButton(
                onPressed: () {
                  final newList = List<TransactionSplit>.from(splits.value);
                  newList.removeAt(index);
                  splits.value = newList;

                  final newControllers = List<TextEditingController>.from(splitControllers.value);
                  newControllers[index].dispose();
                  newControllers.removeAt(index);
                  splitControllers.value = newControllers;
                },
                icon: Icon(
                  Icons.remove_circle_outline_rounded,
                  color: AppColors.error.withOpacity(0.5),
                  size: 20.r,
                ),
              ),
            ],
          ),
          if (split.category != 'Other') ...[
            Divider(height: 24.h, color: AppColors.primary.withOpacity(0.05)),
            _buildSplitSubcategoryPicker(context, ref, index, split, splits),
          ],
        ],
      ),
    );
  }

  Widget _buildSplitSubcategoryPicker(BuildContext context, WidgetRef ref, int index, TransactionSplit split, ValueNotifier<List<TransactionSplit>> splits) {
    final subcategoriesAsync = ref.watch(subcategoriesProvider);

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

        return Row(
          children: [
            Icon(
              Icons.subdirectory_arrow_right_rounded,
              color: AppColors.primary.withOpacity(0.5),
              size: 16.r,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: split.subcategory,
                  isDense: true,
                  isExpanded: true,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  style: AppTextStyles.small(context),
                  items: [
                    ...filteredSubs.map(
                      (s) => DropdownMenuItem(value: s, child: Text(s)),
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
                      _showAddSubcategoryDialog(
                        context,
                        ref,
                        category: split.category,
                        onAdded: (name) {
                          final newList = List<TransactionSplit>.from(splits.value);
                          newList[index] = TransactionSplit(
                            amount: split.amount,
                            category: split.category,
                            subcategory: name,
                            notes: split.notes,
                          );
                          splits.value = newList;
                        },
                      );
                    } else if (val != null) {
                      final newList = List<TransactionSplit>.from(splits.value);
                      newList[index] = TransactionSplit(
                        amount: split.amount,
                        category: split.category,
                        subcategory: val,
                        notes: split.notes,
                      );
                      splits.value = newList;
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSplitSummary(BuildContext context, ValueNotifier<List<TransactionSplit>> splits, TextEditingController amountController) {
    final totalSplit = splits.value.fold(0.0, (sum, item) => sum + item.amount);
    final totalAmount = double.tryParse(amountController.text) ?? 0.0;
    final remaining = totalAmount - totalSplit;
    final isMatched = remaining.abs() < 0.01;
    final isExceeded = remaining < -0.01;

    return Container(
      margin: EdgeInsets.only(top: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isMatched
            ? AppColors.success.withOpacity(0.05)
            : isExceeded
            ? AppColors.error.withOpacity(0.1)
            : AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
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
            SizedBox(height: 8.h),
            Text(
              'Your split total (₹${totalSplit.toStringAsFixed(2)}) is more than the original amount (₹${totalAmount.toStringAsFixed(2)}). Please reduce the split amounts.',
              style: AppTextStyles.small(context, color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}
