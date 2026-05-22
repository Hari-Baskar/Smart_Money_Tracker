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
          initialTime: TimeOfDay.fromDateTime(selectedDate.value),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onBackground, size: AppSizes.r20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Transaction',
          style: AppTextStyles.headline(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.r24),
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
                    SizedBox(height: AppSizes.h8),
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
              _buildCategoryPicker(context, ref, selectedCategory, selectedSubcategory),
              SizedBox(height: AppSizes.h24),

              // Subcategory Selector
              _buildLabel(context, 'Subcategory'),
              SizedBox(height: AppSizes.h8),
              _buildSubcategoryPicker(context, ref, selectedCategory, selectedSubcategory),
              SizedBox(height: AppSizes.h24),

              // Date Selector
              _buildLabel(context, 'Date'),
              SizedBox(height: AppSizes.h8),
              _buildDateField(context, selectedDate, selectDate),
              SizedBox(height: AppSizes.h48),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: AppSizes.h(56),
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
                          height: AppSizes.r24,
                          width: AppSizes.r24,
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceContainerLowest(context),
        borderRadius: BorderRadius.circular(AppSizes.r16),
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
      child: TextFormField(
        controller: controller,
        style: AppTextStyles.body(context),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.small(context, color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)),
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
  ) {
    final subcategoriesAsync = ref.watch(subcategoriesProvider);

    return subcategoriesAsync.when(
      data: (allSubs) {
        final categories = allSubs.map((s) => s.parentCategory).toSet().toList();
        categories.sort();

        final catColor = AppColors.getCategoryColor(selectedCategory.value);
        final catBg = AppColors.getCategoryBgColor(context, selectedCategory.value);

        return InkWell(
          onTap: () => _showCategoryBottomSheet(
            context,
            ref,
            selectedCategory,
            selectedSubcategory,
            categories,
          ),
          borderRadius: BorderRadius.circular(AppSizes.r16),
          child: Container(
            padding: EdgeInsets.all(AppSizes.r16),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceContainerLowest(context),
              borderRadius: BorderRadius.circular(AppSizes.r16),
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: AppSizes.h(2)),
                      Text(
                        selectedCategory.value,
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
        final filteredSubs = allSubs
            .where((s) => s.parentCategory == selectedCategory.value)
            .map((s) => s.name)
            .toSet()
            .toList();

        if (!filteredSubs.contains(selectedSubcategory.value)) {
          filteredSubs.add(selectedSubcategory.value);
        }

        filteredSubs.sort();

        final catColor = AppColors.getCategoryColor(selectedCategory.value);
        final catBg = AppColors.getCategoryBgColor(context, selectedCategory.value);

        return InkWell(
          onTap: () => _showSubcategoryBottomSheet(
            context,
            ref,
            selectedCategory.value,
            selectedSubcategory,
            filteredSubs,
          ),
          borderRadius: BorderRadius.circular(AppSizes.r16),
          child: Container(
            padding: EdgeInsets.all(AppSizes.r16),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceContainerLowest(context),
              borderRadius: BorderRadius.circular(AppSizes.r16),
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: AppSizes.h(2)),
                      Text(
                        selectedSubcategory.value,
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
                    if (index == categories.length) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showAddCategoryDialog(
                            context,
                            ref,
                            selectedCategory,
                            selectedSubcategory,
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
                                'Add Custom...',
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

                    return GestureDetector(
                      onTap: () {
                        selectedCategory.value = cat;
                        selectedSubcategory.value = 'General';
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

  void _showSubcategoryBottomSheet(
    BuildContext context,
    WidgetRef ref,
    String parentCategory,
    ValueNotifier<String> selectedSubcategory,
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
                          '+ Add Custom...',
                          style: AppTextStyles.body(
                            context,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }

                    final sub = subcategories[index];
                    final isSelected = selectedSubcategory.value == sub;
                    final activeCatColor = AppColors.getCategoryColor(parentCategory);

                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSizes.w8,
                        vertical: AppSizes.h4,
                      ),
                      onTap: () {
                        selectedSubcategory.value = sub;
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

  void _showAddCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<String> selectedCategory,
    ValueNotifier<String> selectedSubcategory,
  ) {
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
                                  .addSubcategory('General', name);
                              selectedCategory.value = name;
                              selectedSubcategory.value = 'General';
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

  void _showAddSubcategoryDialog(
    BuildContext context,
    WidgetRef ref,
    String category,
    ValueNotifier<String> selectedSubcategory,
  ) {
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: AppSizes.h16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: AppTextStyles.body(context),
                    decoration: InputDecoration(
                      hintText: 'Enter name (e.g. Netflix, Gym)',
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
                            if (controller.text.trim().isNotEmpty) {
                              final name = controller.text.trim();
                              await ref
                                  .read(subcategoriesProvider.notifier)
                                  .addSubcategory(name, category);
                              selectedSubcategory.value = name;
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



  Widget _buildDateField(BuildContext context, ValueNotifier<DateTime> selectedDate, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSizes.r16),
        decoration: BoxDecoration(
          color: AppColors.getSurfaceContainerLowest(context),
          borderRadius: BorderRadius.circular(AppSizes.r16),
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
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: AppSizes.r20),
            SizedBox(width: AppSizes.w12),
            Text(
              DateFormat('MMM dd, yyyy • hh:mm a').format(selectedDate.value),
              style: AppTextStyles.body(context),
            ),
            const Spacer(),
            Icon(Icons.edit_calendar_rounded, color: AppColors.primary, size: AppSizes.r20),
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
        padding: EdgeInsets.symmetric(vertical: AppSizes.h12),
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
