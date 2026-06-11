import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/payment_constants.dart';
import 'package:smart_money_tracker/core/models/custom_asset_model.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import '../providers/custom_asset_provider.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';

class PaymentMethodPickerWidget extends ConsumerWidget {
  final ValueNotifier<String?> selectedPaymentMethodId;
  final TextEditingController customPaymentController;

  const PaymentMethodPickerWidget({
    super.key,
    required this.selectedPaymentMethodId,
    required this.customPaymentController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customAssetsAsync = ref.watch(customAssetsProvider);
    final customAssets = customAssetsAsync.value ?? const [];

    String paymentName = 'None';
    IconData paymentIcon = Icons.payment_rounded;

    final paymentId = selectedPaymentMethodId.value;
    if (paymentId != null) {
      final customPayment = customAssets
          .where((a) => a.id == paymentId && a.type == 'payment_method')
          .firstOrNull;
      if (customPayment != null) {
        paymentName = customPayment.isArchived
            ? '${customPayment.name} (Archived)'
            : customPayment.name;
        paymentIcon = Icons.payment_rounded;
      } else {
        paymentName =
            PaymentConstants.getPaymentMethodName(paymentId) ?? 'None';
        paymentIcon = PaymentConstants.getPaymentMethodIcon(paymentId);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showPaymentMethodBottomSheet(context),
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
                    paymentIcon,
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
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: AppSizes.h(2)),
                      Text(paymentName, style: AppTextStyles.body(context)),
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
      ],
    );
  }

  void _showPaymentMethodBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _PaymentMethodBottomSheet(
          selectedPaymentMethodId: selectedPaymentMethodId,
        );
      },
    );
  }
}

class _PaymentMethodBottomSheet extends ConsumerStatefulWidget {
  final ValueNotifier<String?> selectedPaymentMethodId;

  const _PaymentMethodBottomSheet({required this.selectedPaymentMethodId});

  @override
  ConsumerState<_PaymentMethodBottomSheet> createState() =>
      _PaymentMethodBottomSheetState();
}

class _PaymentMethodBottomSheetState
    extends ConsumerState<_PaymentMethodBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    // Watch custom assets for payment methods
    final customAssetsAsync = ref.watch(customAssetsProvider);
    final customAssets = customAssetsAsync.value ?? const [];
    final customMethods = customAssets
        .where((a) => a.type == 'payment_method')
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r16)),
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
                    ? AppColors.white.withOpacity(0.12)
                    : AppColors.black.withOpacity(0.08),
                borderRadius: AppSizes.boxBorderRadius,
              ),
            ),
          ),
          Text('Select Payment Method', style: AppTextStyles.heading(context)),
          SizedBox(height: AppSizes.h16),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _buildNoneOption(context),
                Divider(
                  color: isDark
                      ? AppColors.white.withOpacity(0.05)
                      : AppColors.black.withOpacity(0.04),
                  height: 1,
                ),
                _buildCustomOption(context),
                Divider(
                  color: isDark
                      ? AppColors.white.withOpacity(0.05)
                      : AppColors.black.withOpacity(0.04),
                  height: 1,
                ),

                // ── Custom Methods Section ──
                if (customMethods.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSizes.h8),
                    child: Text(
                      'CUSTOM METHODS',
                      style: AppTextStyles.small(
                        context,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...customMethods.map(
                    (method) => _buildMethodTile(
                      context,
                      method.id,
                      method.name,
                      Icons.payment_rounded,
                      isCustom: true,
                      isArchived: method.isArchived,
                    ),
                  ),
                  Divider(
                    color: isDark
                        ? AppColors.white.withOpacity(0.05)
                        : AppColors.black.withOpacity(0.04),
                    height: 1,
                  ),
                ],

                // ── Default Methods Section ──
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.h8),
                  child: Text(
                    'PAYMENT METHODS',
                    style: AppTextStyles.small(
                      context,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...PaymentConstants.paymentMethods.map(
                  (method) => _buildMethodTile(
                    context,
                    method.id,
                    method.name,
                    method.icon,
                    isCustom: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoneOption(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.remove_circle_outline_rounded,
        color: AppColors.getTextMuted(context),
      ),
      title: Text('None', style: AppTextStyles.body(context)),
      trailing: widget.selectedPaymentMethodId.value == null
          ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: () {
        widget.selectedPaymentMethodId.value = null;
        Navigator.pop(context);
      },
    );
  }

  Widget _buildCustomOption(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
      title: Text(
        'Add Custom...',
        style: AppTextStyles.body(context, color: AppColors.primary),
      ),
      trailing: null,
      onTap: () {
        Navigator.pop(context);
        _showAddCustomPaymentDialog(context);
      },
    );
  }

  void _showAddCustomPaymentDialog(BuildContext context) {
    final controller = TextEditingController();
    final paymentIdNotifier =
        widget.selectedPaymentMethodId; // capture before potential disposal
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return Consumer(
          builder: (_, freshRef, __) {
            final isDark = AppColors.isDark(modalContext);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
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
                        'Custom Payment Method',
                        style: AppTextStyles.heading(modalContext),
                      ),
                      SizedBox(height: AppSizes.h16),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        style: AppTextStyles.body(modalContext),
                        maxLength: 30,
                        decoration: InputDecoration(
                          hintText: 'Enter payment method (e.g. PayPal, GPay)',
                          hintStyle: AppTextStyles.small(
                            modalContext,
                            color: Theme.of(
                              modalContext,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.edit_note_rounded,
                            color: AppColors.primary,
                            size: AppSizes.r20,
                          ),
                          filled: true,
                          fillColor: Theme.of(modalContext).colorScheme.surface,
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
                              onPressed: () => Navigator.pop(modalContext),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSizes.h16,
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: AppTextStyles.body(
                                  modalContext,
                                  color: Theme.of(
                                    modalContext,
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
                                  final newId = await freshRef
                                      .read(customAssetsProvider.notifier)
                                      .addCustomAsset(name, 'payment_method');
                                  paymentIdNotifier.value = newId;
                                  if (modalContext.mounted)
                                    Navigator.pop(modalContext);
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
                                  modalContext,
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

  Widget _buildMethodTile(
    BuildContext context,
    String id,
    String name,
    IconData icon, {
    required bool isCustom,
    bool isArchived = false,
  }) {
    final isSelected = widget.selectedPaymentMethodId.value == id;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.getTextMuted(context),
      ),
      title: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: name, style: AppTextStyles.body(context)),
            if (isArchived)
              TextSpan(
                text: ' (Archived)',
                style: AppTextStyles.body(context, color: AppColors.error),
              ),
          ],
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: () {
        widget.selectedPaymentMethodId.value = id;
        Navigator.pop(context);
      },
      onLongPress: isCustom
          ? () {
              Navigator.pop(context);
              _showManageMethodSheet(context, id, name, isArchived: isArchived);
            }
          : null,
    );
  }

  void _showManageMethodSheet(
    BuildContext context,
    String id,
    String name, {
    bool isArchived = false,
  }) {
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
                  'Manage Payment Method',
                  style: AppTextStyles.heading(context),
                ),
                Text(
                  name,
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
                    'Rename Payment Method',
                    style: AppTextStyles.body(context),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showRenameMethodDialog(context, id, name);
                  },
                ),
                Divider(
                  color: isDark
                      ? AppColors.white.withOpacity(0.05)
                      : AppColors.black.withOpacity(0.04),
                  height: 1,
                ),
                if (isArchived) ...[
                  Consumer(
                    builder: (context, ref, _) {
                      return ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(AppSizes.r8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.unarchive_rounded,
                            color: AppColors.primary,
                            size: AppSizes.r20,
                          ),
                        ),
                        title: Text(
                          'Unarchive Payment Method',
                          style: AppTextStyles.body(context),
                        ),
                        onTap: () async {
                          final notifier = ref.read(customAssetsProvider.notifier);
                          Navigator.pop(context);
                          await notifier.unarchiveCustomAsset(id);
                        },
                      );
                    },
                  ),
                  Divider(
                    color: isDark
                        ? AppColors.white.withOpacity(0.05)
                        : AppColors.black.withOpacity(0.04),
                    height: 1,
                  ),
                ],
                Divider(
                  color: isDark
                      ? AppColors.white.withOpacity(0.05)
                      : AppColors.black.withOpacity(0.04),
                  height: 1,
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(AppSizes.r8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_rounded,
                      color: AppColors.error,
                      size: AppSizes.r20,
                    ),
                  ),
                  title: Text(
                    'Delete Payment Method',
                    style: AppTextStyles.body(context, color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showDeleteMethodDialog(
                      context,
                      id,
                      name,
                      isArchived: isArchived,
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

  void _showRenameMethodDialog(BuildContext context, String id, String name) {
    final controller = TextEditingController(text: name);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return Consumer(
          builder: (_, freshRef, __) {
            final isDark = AppColors.isDark(modalContext);
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom,
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
                        'Rename Payment Method',
                        style: AppTextStyles.heading(modalContext),
                      ),
                      SizedBox(height: AppSizes.h16),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        style: AppTextStyles.body(modalContext),
                        maxLength: 30,
                        decoration: InputDecoration(
                          hintText: 'Enter new name',
                          hintStyle: AppTextStyles.small(
                            modalContext,
                            color: Theme.of(
                              modalContext,
                            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.edit_note_rounded,
                            color: AppColors.primary,
                            size: AppSizes.r20,
                          ),
                          filled: true,
                          fillColor: Theme.of(modalContext).colorScheme.surface,
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
                              onPressed: () => Navigator.pop(modalContext),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSizes.h16,
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: AppTextStyles.body(
                                  modalContext,
                                  color: Theme.of(
                                    modalContext,
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
                                if (newName.isNotEmpty) {
                                  await freshRef
                                      .read(customAssetsProvider.notifier)
                                      .renameCustomAsset(id, newName);
                                  if (modalContext.mounted)
                                    Navigator.pop(modalContext);
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
                                  modalContext,
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

  void _showDeleteMethodDialog(
    BuildContext context,
    String id,
    String name, {
    bool isArchived = false,
  }) {
    final paymentIdNotifier =
        widget.selectedPaymentMethodId; // capture before potential disposal
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (modalContext) {
        return Consumer(
          builder: (_, freshRef, __) {
            final isDark = AppColors.isDark(modalContext);
            final transactionsAsync = freshRef.watch(transactionsProvider);
            final transactions = transactionsAsync.value ?? const [];
            final dependencies = transactions
                .where((t) => t.paymentMethodId == id)
                .length;

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                      dependencies > 0 && !isArchived
                          ? Icons.archive_rounded
                          : Icons.warning_amber_rounded,
                      color: dependencies > 0 && !isArchived
                          ? AppColors.primary
                          : AppColors.error,
                      size: AppSizes.r(40),
                    ),
                    SizedBox(height: AppSizes.h16),
                    Text(
                      dependencies > 0 && !isArchived
                          ? 'Archive Payment Method?'
                          : 'Delete Payment Method?',
                      style: AppTextStyles.heading(modalContext),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSizes.h12),
                    Text(
                      dependencies > 0 && !isArchived
                          ? 'This payment method is used in $dependencies transaction(s). It will be archived instead of deleted, keeping your transaction history intact. It will no longer appear in selection menus.'
                          : (dependencies > 0 && isArchived
                                ? 'This archived payment method is still used in $dependencies transaction(s) and cannot be permanently deleted. Please reassign those transactions first.'
                                : 'This will permanently delete the custom payment method "$name". This action cannot be undone.'),
                      style: AppTextStyles.body(
                        modalContext,
                        color: Theme.of(
                          modalContext,
                        ).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSizes.h24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(modalContext),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSizes.h16,
                              ),
                            ),
                            child: Text(
                              isArchived && dependencies > 0
                                  ? 'Okay'
                                  : 'Cancel',
                              style: AppTextStyles.body(
                                modalContext,
                                color: Theme.of(
                                  modalContext,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        if (!(isArchived && dependencies > 0)) ...[
                          SizedBox(width: AppSizes.w16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (dependencies > 0 && !isArchived) {
                                  await freshRef
                                      .read(customAssetsProvider.notifier)
                                      .archiveCustomAsset(id);
                                } else {
                                  await freshRef
                                      .read(customAssetsProvider.notifier)
                                      .deleteCustomAsset(id);
                                }
                                if (paymentIdNotifier.value == id) {
                                  paymentIdNotifier.value = null;
                                }
                                if (modalContext.mounted)
                                  Navigator.pop(modalContext);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: dependencies > 0
                                    ? AppColors.primary
                                    : AppColors.error,
                                foregroundColor: AppColors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSizes.h16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppSizes.boxBorderRadius,
                                ),
                              ),
                              child: Text(
                                dependencies > 0 ? 'Archive' : 'Delete',
                                style: AppTextStyles.body(
                                  modalContext,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
