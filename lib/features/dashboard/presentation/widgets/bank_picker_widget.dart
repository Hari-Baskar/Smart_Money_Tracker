import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/payment_constants.dart';
import 'package:smart_money_tracker/core/models/custom_asset_model.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import '../providers/custom_asset_provider.dart';
import '../providers/user_bank_provider.dart';
import 'package:smart_money_tracker/core/common/widgets/primary_button.dart';
import 'package:smart_money_tracker/core/common/widgets/app_text_field.dart';
import 'package:smart_money_tracker/core/common/widgets/modal_action_sheet.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/transaction_provider.dart';

class BankPickerWidget extends ConsumerWidget {
  final ValueNotifier<String?> selectedBankId;
  final TextEditingController customBankController;
  final bool showArrow;
  final bool isCompact;

  const BankPickerWidget({
    super.key,
    required this.selectedBankId,
    required this.customBankController,
    this.showArrow = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customAssetsAsync = ref.watch(customAssetsProvider);
    final customAssets = customAssetsAsync.value ?? const [];

    String bankName = 'None';
    final bankId = selectedBankId.value;
    if (bankId != null) {
      final customBank = customAssets
          .where((a) => a.id == bankId && a.type == 'bank')
          .firstOrNull;
      if (customBank != null) {
        bankName = customBank.isArchived
            ? '${customBank.name} (Archived)'
            : customBank.name;
      } else {
        bankName = PaymentConstants.getBankName(bankId) ?? 'None';
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
              if (context.mounted) _showBankBottomSheet(context);
            });
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isCompact ? AppSizes.h8 : AppSizes.h12,
              horizontal: isCompact ? AppSizes.w8 : 0,
            ),
            child: isCompact
                ? Text(
                    bankName == 'None' ? 'Bank' : bankName,
                    style: AppTextStyles.body(context),
                  )
                : Row(
                    children: [
                      Container(
                        width: AppSizes.r(36),
                        height: AppSizes.r(36),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_rounded,
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
                                'Bank Name',
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
                                bankName,
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

  void _showBankBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _BankBottomSheet(selectedBankId: selectedBankId);
      },
    );
  }
}

class _BankBottomSheet extends ConsumerStatefulWidget {
  final ValueNotifier<String?> selectedBankId;

  const _BankBottomSheet({required this.selectedBankId});

  @override
  ConsumerState<_BankBottomSheet> createState() => _BankBottomSheetState();
}

class _BankBottomSheetState extends ConsumerState<_BankBottomSheet> {
  bool _showAllBanks = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    // Watch custom assets for banks
    final customAssetsAsync = ref.watch(customAssetsProvider);
    final customAssets = customAssetsAsync.value ?? const [];
    final customBanks = customAssets.where((a) => a.type == 'bank').toList();

    // Watch user-used bank IDs
    final userBankIdsAsync = ref.watch(userBankIdsProvider);
    final userBankIds = userBankIdsAsync.value ?? const [];

    // Standard list
    final allBanks = PaymentConstants.indianBanks;
    final selectedId = widget.selectedBankId.value;

    final standardBanksToShow = allBanks.where((bank) {
      return userBankIds.contains(bank.id) || bank.id == selectedId;
    }).toList();

    final showAll = _showAllBanks || standardBanksToShow.isEmpty;
    final displayedBanks = showAll ? allBanks : standardBanksToShow;

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
                'Select Bank',
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

                // ── Custom Banks Section ──
                if (customBanks.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSizes.h8),
                    child: Text(
                      'CUSTOM BANKS',
                      style: AppTextStyles.body(
                        context,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...customBanks.map(
                    (bank) => _buildBankTile(
                      context,
                      bank.id,
                      bank.name,
                      isCustom: true,
                      isArchived: bank.isArchived,
                    ),
                  ),
                  Divider(
                    color: isDark
                        ? AppColors.white.withOpacity(0.05)
                        : AppColors.black.withOpacity(0.04),
                    height: 1,
                  ),
                ],

                // ── Standard Banks Section ──
                ...displayedBanks.map(
                  (bank) => _buildBankTile(
                    context,
                    bank.id,
                    bank.name,
                    isCustom: false,
                  ),
                ),

                if (!showAll) ...[
                  Divider(
                    color: isDark
                        ? AppColors.white.withOpacity(0.05)
                        : AppColors.black.withOpacity(0.04),
                    height: 1,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.account_balance_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      'Show All Banks',
                      style: AppTextStyles.body(
                        context,
                        color: AppColors.primary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                    ),
                    onTap: () {
                      setState(() {
                        _showAllBanks = true;
                      });
                    },
                  ),
                ],
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
          color: AppColors.getTextMuted(context).withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.remove_circle_outline_rounded,
          color: AppColors.getTextMuted(context),
          size: AppSizes.r20,
        ),
      ),
      title: Text('None', style: AppTextStyles.body(context)),
      trailing: widget.selectedBankId.value == null
          ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: () {
        widget.selectedBankId.value = null;
        Navigator.pop(context);
      },
    );
  }

  Widget _buildCustomOption(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.add_circle_outline_rounded),
      title: Text('Add Custom', style: AppTextStyles.body(context)),
      trailing: null,
      onTap: () {
        Navigator.pop(context);
        _showAddCustomBankDialog(context);
      },
    );
  }

  void _showAddCustomBankDialog(BuildContext context) {
    final controller = TextEditingController();
    final bankIdNotifier =
        widget.selectedBankId; // capture before potential disposal
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
                              'Add New Bank',
                              style: AppTextStyles.subHeading(
                                modalContext,
                              ).copyWith(fontWeight: FontWeight.bold),
                            ),

                        SizedBox(height: AppSizes.h24),
                        AppTextField(
                          controller: controller,
                          autofocus: true,
                          maxLength: 30,
                          hintText: 'e.g. Chase, Bank of America',
                          prefixIcon: Icon(
                            Icons.account_balance_rounded,
                            color: AppColors.primary,
                            size: AppSizes.r20,
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
                                  'Choose a recognizable name for this bank account.',
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
                                text: 'Add Bank',
                                isExpanded: true,
                                onPressed: () async {
                                  final name = controller.text.trim();
                                  if (name.isNotEmpty) {
                                    final newId = await freshRef
                                        .read(customAssetsProvider.notifier)
                                        .addCustomAsset(name, 'bank');
                                    bankIdNotifier.value = newId;
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

  Widget _buildBankTile(
    BuildContext context,
    String id,
    String name, {
    required bool isCustom,
    bool isArchived = false,
  }) {
    final isSelected = widget.selectedBankId.value == id;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.account_balance_rounded,
        color: isSelected ? AppColors.primary : AppColors.getTextMuted(context),
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
        widget.selectedBankId.value = id;
        Navigator.pop(context);
      },
      onLongPress: isCustom
          ? () {
              Navigator.pop(context);
              _showManageBankSheet(context, id, name, isArchived: isArchived);
            }
          : null,
    );
  }

  void _showManageBankSheet(
    BuildContext context,
    String id,
    String name, {
    bool isArchived = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (bottomSheetContext) {
        return ModalActionSheet(
          children: [
            ModalActionItem(
              icon: Icons.edit_outlined,
              title: 'Edit bank',
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showRenameBankDialog(context, id, name);
              },
            ),
            if (isArchived)
              Consumer(
                builder: (context, ref, _) {
                  return ModalActionItem(
                    icon: Icons.unarchive_outlined,
                    title: 'Unarchive bank',
                    onTap: () async {
                      final notifier = ref.read(
                        customAssetsProvider.notifier,
                      );
                      Navigator.pop(bottomSheetContext);
                      await notifier.unarchiveCustomAsset(id);
                    },
                  );
                },
              ),
            ModalActionItem(
              icon: Icons.delete_outline_rounded,
              title: 'Delete bank',
              isDestructive: true,
              onTap: () {
                Navigator.pop(bottomSheetContext);
                _showDeleteBankDialog(
                  context,
                  id,
                  name,
                  isArchived: isArchived,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showRenameBankDialog(BuildContext context, String id, String name) {
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
                              'Rename Bank',
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
                        AppTextField(
                          controller: controller,
                          autofocus: true,
                          maxLength: 30,
                          hintText: 'Enter new bank name',
                          prefixIcon: Icon(
                            Icons.account_balance_rounded,
                            color: AppColors.primary,
                            size: AppSizes.r20,
                          ),
                        ),
                        SizedBox(height: AppSizes.h24),
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryButton(
                                text: 'Save Bank',
                                isExpanded: true,
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

  void _showDeleteBankDialog(
    BuildContext context,
    String id,
    String name, {
    bool isArchived = false,
  }) {
    final bankIdNotifier =
        widget.selectedBankId; // capture before potential disposal
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
                .where((t) => t.bankId == id)
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
                              ? 'Archive Bank?'
                              : 'Delete Bank?',
                          style: AppTextStyles.subHeading(
                            modalContext,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                    SizedBox(height: AppSizes.h8),
                    Text(
                      dependencies > 0 && !isArchived
                          ? 'This bank is used in $dependencies transaction(s). It will be archived instead of deleted, keeping your transaction history intact. It will no longer appear in selection menus.'
                          : (dependencies > 0 && isArchived
                                ? 'This archived bank is still used in $dependencies transaction(s) and cannot be permanently deleted. Please reassign those transactions first.'
                                : 'This will permanently delete the custom bank "$name". This action cannot be undone.'),
                      style: AppTextStyles.body(
                        modalContext,
                      ).copyWith(color: AppColors.getTextMuted(modalContext)),
                    ),
                    if (!(isArchived && dependencies > 0)) ...[
                      SizedBox(height: AppSizes.h24),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              text: dependencies > 0 && !isArchived
                                  ? 'Archive Bank'
                                  : 'Delete Bank',
                              isExpanded: true,
                              backgroundColor: dependencies > 0 && !isArchived
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
                                if (bankIdNotifier.value == id) {
                                  bankIdNotifier.value = null;
                                }
                                if (modalContext.mounted)
                                  Navigator.pop(modalContext);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
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
