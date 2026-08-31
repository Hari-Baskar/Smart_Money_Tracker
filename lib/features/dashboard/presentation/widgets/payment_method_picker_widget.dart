import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/payment_constants.dart';
import 'package:smart_money_tracker/core/models/custom_asset_model.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import '../providers/custom_asset_provider.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';

class PaymentMethodPickerWidget extends ConsumerWidget {
  final ValueNotifier<String?> selectedPaymentMethodId;
  final TextEditingController customPaymentController;
  final bool showArrow;
  final bool isCompact;

  const PaymentMethodPickerWidget({
    super.key,
    required this.selectedPaymentMethodId,
    required this.customPaymentController,
    this.showArrow = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customAssetsAsync = ref.watch(customAssetsProvider);
    final customAssets = customAssetsAsync.value ?? const [];

    String paymentName = 'None';
    IconData paymentIcon = Icons.payment_rounded;
    Color paymentColor = Colors.purple;

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
        paymentColor = Colors.purple;
      } else {
        paymentName =
            PaymentConstants.getPaymentMethodName(paymentId) ?? 'None';
        paymentIcon = PaymentConstants.getPaymentMethodIcon(paymentId);
        paymentColor = PaymentConstants.getPaymentMethodColor(paymentId);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Future.delayed(const Duration(milliseconds: 50), () {
              if (context.mounted) _showPaymentMethodBottomSheet(context);
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isCompact ? AppSizes.h8 : AppSizes.h12,
              horizontal: isCompact ? AppSizes.w8 : 0,
            ),
            child: isCompact
                ? Text(
                    paymentName == 'None' ? 'Payment Method' : paymentName,
                    style: AppTextStyles.body(context),
                  )
                : Row(
                    children: [
                      Container(
                        width: AppSizes.r(36),
                        height: AppSizes.r(36),
                        decoration: BoxDecoration(
                          color: paymentColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          paymentIcon,
                          color: Colors.white,
                          size: AppSizes.r20,
                        ),
                      ),
                      SizedBox(width: AppSizes.w16),
                      Builder(
                        builder: (context) {
                          final content = Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment Method',
                                style: AppTextStyles.body(
                                  context,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withOpacity(0.7),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: AppSizes.h(2)),
                              Text(
                                paymentName,
                                style: AppTextStyles.body(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                          return showArrow
                              ? Expanded(child: content)
                              : Container(
                                  constraints: BoxConstraints(
                                    maxWidth: AppSizes.w(150),
                                  ),
                                  child: content,
                                );
                        },
                      ),
                      if (showArrow)
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Payment Method',
                style: AppTextStyles.subHeading(
                  context,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.getTextMuted(context),
                ),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
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
                      style: AppTextStyles.body(
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
                      iconColor: Colors.purple,
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
                ...PaymentConstants.paymentMethods.map(
                  (method) => _buildMethodTile(
                    context,
                    method.id,
                    method.name,
                    method.icon,
                    isCustom: false,
                    iconColor: method.color,
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
      leading: Container(
        width: AppSizes.r(36),
        height: AppSizes.r(36),
        decoration: BoxDecoration(
          color: AppColors.getTextMuted(context).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.remove_circle_outline_rounded,
          color: AppColors.getTextMuted(context),
          size: AppSizes.r20,
        ),
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
      leading: Container(
        width: AppSizes.r(36),
        height: AppSizes.r(36),
        decoration: BoxDecoration(shape: BoxShape.circle),
        child: Icon(Icons.add_circle_outline_rounded, size: AppSizes.r20),
      ),
      title: Text('Add Custom', style: AppTextStyles.body(context)),
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
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: AppSizes.w(48),
                            height: AppSizes.h4,
                            margin: EdgeInsets.only(bottom: AppSizes.h24),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.white.withOpacity(0.12)
                                  : AppColors.black.withOpacity(0.08),
                              borderRadius: AppSizes.boxBorderRadius,
                            ),
                          ),
                        ),
                        Text(
                          'Add Payment Method',
                          style: AppTextStyles.subHeading(
                            modalContext,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),

                        SizedBox(height: AppSizes.h24),
                        TextField(
                          controller: controller,
                          autofocus: true,
                          style: AppTextStyles.body(modalContext),
                          maxLength: 30,
                          decoration: InputDecoration(
                            hintText: 'e.g. Credit Card, PayPal',
                            hintStyle: AppTextStyles.body(
                              modalContext,
                              color: Theme.of(
                                modalContext,
                              ).colorScheme.onSurfaceVariant.withOpacity(0.5),
                            ),
                            prefixIcon: Icon(
                              Icons.payment_rounded,
                              color: AppColors.primary,
                              size: AppSizes.r20,
                            ),
                            filled: false,
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.primary.withOpacity(0.5),
                              ),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.all(AppSizes.r16),
                            counterText: '',
                          ),
                        ),
                        SizedBox(height: AppSizes.h24),
                        Container(
                          padding: EdgeInsets.all(AppSizes.r16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceContainerLowestDark
                                : AppColors.surfaceContainerLight,
                            borderRadius: AppSizes.boxBorderRadius,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.white.withOpacity(0.05)
                                  : AppColors.black.withOpacity(0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(AppSizes.r8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.primary,
                                  size: AppSizes.r16,
                                ),
                              ),
                              SizedBox(width: AppSizes.w16),
                              Expanded(
                                child: Text(
                                  'Choose a descriptive name for this payment method.',
                                  style: AppTextStyles.body(
                                    modalContext,
                                    color: AppColors.getTextMuted(modalContext),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppSizes.h32),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                text: 'Cancel',
                                isOutlined: true,
                                isExpanded: false,
                                onPressed: () => Navigator.pop(modalContext),
                                foregroundColor: AppColors.getTextMuted(
                                  modalContext,
                                ),
                                borderColor: AppColors.getTextMuted(
                                  modalContext,
                                ).withValues(alpha: 0.3),
                                borderWidth: 0.5,
                              ),
                            ),
                            SizedBox(width: AppSizes.w16),
                            Expanded(
                              child: PrimaryButton(
                                text: 'Add',
                                isExpanded: false,
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
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
    required Color iconColor,
  }) {
    final isSelected = widget.selectedPaymentMethodId.value == id;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: AppSizes.r(36),
        height: AppSizes.r(36),
        decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: AppSizes.r20),
      ),
      title: Text.rich(
        TextSpan(
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
                  style: AppTextStyles.subHeading(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: AppSizes.h8),
                Text(
                  'Choose an action below to modify or remove the custom payment method "$name".',
                  style: AppTextStyles.body(
                    context,
                  ).copyWith(color: AppColors.getTextMuted(context)),
                ),
                SizedBox(height: AppSizes.h24),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        text: 'Delete',
                        isOutlined: true,
                        isExpanded: false,
                        foregroundColor: AppColors.error,
                        borderColor: AppColors.error.withValues(alpha: 0.3),
                        onPressed: () {
                          Navigator.pop(context);
                          _showDeleteMethodDialog(
                            context,
                            id,
                            name,
                            isArchived: isArchived,
                          );
                        },
                      ),
                    ),
                    if (isArchived) ...[
                      SizedBox(width: AppSizes.w12),
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, _) {
                            return PrimaryButton(
                              text: 'Unarchive',
                              isExpanded: false,
                              onPressed: () async {
                                final notifier = ref.read(
                                  customAssetsProvider.notifier,
                                );
                                Navigator.pop(context);
                                await notifier.unarchiveCustomAsset(id);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                    SizedBox(width: AppSizes.w12),
                    Expanded(
                      child: PrimaryButton(
                        text: 'Edit',
                        isExpanded: false,
                        backgroundColor: AppColors.warning,
                        foregroundColor: AppColors.black,
                        onPressed: () {
                          Navigator.pop(context);
                          _showRenameMethodDialog(context, id, name);
                        },
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
                child: SafeArea(
                  top: false,
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
                          style: AppTextStyles.subHeading(
                            modalContext,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: AppSizes.h8),
                        Text(
                          'This will change the name across all past and future transactions.',
                          style: AppTextStyles.body(modalContext).copyWith(
                            color: AppColors.getTextMuted(modalContext),
                          ),
                        ),
                        SizedBox(height: AppSizes.h16),
                        TextField(
                          controller: controller,
                          autofocus: true,
                          style: AppTextStyles.body(modalContext),
                          maxLength: 30,
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Enter new name',
                            hintStyle: AppTextStyles.body(
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
                            fillColor: Theme.of(
                              modalContext,
                            ).colorScheme.surface,
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
                              child: PrimaryButton(
                                text: 'Cancel',
                                isOutlined: true,
                                isExpanded: false,
                                onPressed: () => Navigator.pop(modalContext),
                                foregroundColor: AppColors.getTextMuted(
                                  modalContext,
                                ),
                                borderColor: AppColors.getTextMuted(
                                  modalContext,
                                ).withValues(alpha: 0.3),
                                borderWidth: 0.5,
                              ),
                            ),
                            SizedBox(width: AppSizes.w16),
                            Expanded(
                              child: PrimaryButton(
                                text: 'Save',
                                isExpanded: false,
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
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    Text(
                      dependencies > 0 && !isArchived
                          ? 'Archive Payment Method?'
                          : 'Delete Payment Method?',
                      style: AppTextStyles.subHeading(
                        modalContext,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: AppSizes.h8),
                    Text(
                      dependencies > 0 && !isArchived
                          ? 'This payment method is used in $dependencies transaction(s). It will be archived instead of deleted, keeping your transaction history intact. It will no longer appear in selection menus.'
                          : (dependencies > 0 && isArchived
                                ? 'This archived payment method is still used in $dependencies transaction(s) and cannot be permanently deleted. Please reassign those transactions first.'
                                : 'This will permanently delete the custom payment method "$name". This action cannot be undone.'),
                      style: AppTextStyles.body(
                        modalContext,
                      ).copyWith(color: AppColors.getTextMuted(modalContext)),
                    ),
                    SizedBox(height: AppSizes.h24),
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: isArchived && dependencies > 0
                                ? 'Okay'
                                : 'Cancel',
                            isOutlined: true,
                            isExpanded: false,
                            onPressed: () => Navigator.pop(modalContext),
                            foregroundColor: AppColors.getTextMuted(
                              modalContext,
                            ),
                            borderColor: AppColors.getTextMuted(
                              modalContext,
                            ).withValues(alpha: 0.3),
                            borderWidth: 0.5,
                          ),
                        ),
                        if (!(isArchived && dependencies > 0)) ...[
                          SizedBox(width: AppSizes.w16),
                          Expanded(
                            child: PrimaryButton(
                              text: dependencies > 0 ? 'Archive' : 'Delete',
                              isExpanded: false,
                              backgroundColor: dependencies > 0
                                  ? AppColors.primary
                                  : AppColors.error,
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

  Widget _buildOptionColumn(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.r12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.w12,
          vertical: AppSizes.h8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppSizes.r(12)),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.white, size: AppSizes.r16),
            ),
            SizedBox(height: AppSizes.h8),
            Text(
              label,
              style: AppTextStyles.body(context).copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.getText(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
