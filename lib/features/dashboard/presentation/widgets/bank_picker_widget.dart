import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/payment_constants.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/features/dashboard/presentation/providers/user_bank_provider.dart';

class BankPickerWidget extends ConsumerWidget {
  final ValueNotifier<String?> selectedBankId;
  final TextEditingController customBankController;

  const BankPickerWidget({
    super.key,
    required this.selectedBankId,
    required this.customBankController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bankName = PaymentConstants.getBankName(selectedBankId.value);

    // Pre-watch here so the data is already loaded before the sheet opens.
    // This keeps the provider alive and avoids re-fetching every time.
    final userBankIdsAsync = ref.watch(userBankIdsProvider);
    final userBankIds = userBankIdsAsync.asData?.value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showBankBottomSheet(context, userBankIds),
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
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: AppSizes.h(2)),
                      Text(
                        selectedBankId.value == 'custom'
                            ? (customBankController.text.isEmpty
                                ? 'Custom Bank'
                                : customBankController.text)
                            : bankName,
                        style: AppTextStyles.body(context),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_right_rounded,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.5),
                  size: AppSizes.r20,
                ),
              ],
            ),
          ),
        ),
        if (selectedBankId.value == 'custom')
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.w16,
              vertical: AppSizes.h8,
            ),
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
    List<String> userBankIds,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _BankBottomSheet(
          selectedBankId: selectedBankId,
          userBankIds: userBankIds,
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
        borderRadius: AppSizes.boxBorderRadius,
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.body(context),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.small(
            context,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withOpacity(0.5),
          ),
          prefixIcon: Icon(icon, color: AppColors.primary, size: AppSizes.r20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(AppSizes.r12),
        ),
      ),
    );
  }
}

// ── Bottom Sheet (StatefulWidget to manage expand/collapse) ──────────────────
class _BankBottomSheet extends StatefulWidget {
  final ValueNotifier<String?> selectedBankId;
  final List<String> userBankIds; // Pre-resolved, passed from parent

  const _BankBottomSheet({
    required this.selectedBankId,
    required this.userBankIds,
  });

  @override
  State<_BankBottomSheet> createState() => _BankBottomSheetState();
}

class _BankBottomSheetState extends State<_BankBottomSheet> {
  bool _showAllBanks = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    // Use the pre-resolved list passed from parent — no async re-fetch
    final userBankIds = widget.userBankIds;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.r16),
        ),
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
          // Drag handle
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

          Text('Select Bank', style: AppTextStyles.heading(context)),
          SizedBox(height: AppSizes.h16),

          Expanded(
            child: _buildBankList(
              context,
              PaymentConstants.indianBanks
                  .where((b) => userBankIds.contains(b.id))
                  .toList(),
              PaymentConstants.indianBanks
                  .where((b) => !userBankIds.contains(b.id))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankList(
    BuildContext context,
    List<BankModel> userBanks,
    List<BankModel> otherBanks,
  ) {
    final isDark = AppColors.isDark(context);

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        // ── None ──────────────────────────────────────────────────────────
        _buildNoneOption(context),
        const Divider(),

        // ── Custom ────────────────────────────────────────────────────────
        _buildCustomOption(context),
        const Divider(),

        // ── Your Banks Section ────────────────────────────────────────────
        if (userBanks.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.h8),
            child: Text(
              'YOUR BANKS',
              style: AppTextStyles.small(
                context,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...userBanks.map((bank) => _buildBankTile(context, bank)),
          SizedBox(height: AppSizes.h8),
        ] else ...[
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.h8),
            child: Text(
              'No banks detected yet from SMS',
              style: AppTextStyles.small(
                context,
                color: AppColors.getTextMuted(context),
              ),
            ),
          ),
        ],

        // ── Show All Banks toggle ─────────────────────────────────────────
        if (otherBanks.isNotEmpty) ...[
          InkWell(
            onTap: () => setState(() => _showAllBanks = !_showAllBanks),
            borderRadius: AppSizes.boxBorderRadius,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.h(10)),
              child: Row(
                children: [
                  Icon(
                    _showAllBanks
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.primary,
                    size: AppSizes.r20,
                  ),
                  SizedBox(width: AppSizes.w8),
                  Text(
                    _showAllBanks ? 'Hide other banks' : 'Show all banks',
                    style: AppTextStyles.body(
                      context,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: AppSizes.w4),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.w(6),
                      vertical: AppSizes.h(2),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.r4),
                    ),
                    child: Text(
                      '${otherBanks.length}',
                      style: AppTextStyles.small(
                        context,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded "all banks" list ─────────────────────────────────
          if (_showAllBanks) ...[
            Divider(
              color: isDark
                  ? AppColors.white.withOpacity(0.08)
                  : AppColors.black.withOpacity(0.06),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSizes.h8),
              child: Text(
                'ALL BANKS',
                style: AppTextStyles.small(
                  context,
                  color: AppColors.getTextMuted(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...otherBanks.map((bank) => _buildBankTile(context, bank)),
          ],
        ],
      ],
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
      leading: Icon(
        Icons.add_circle_outline_rounded,
        color: AppColors.primary,
      ),
      title: Text(
        'Custom...',
        style: AppTextStyles.body(context, color: AppColors.primary),
      ),
      trailing: widget.selectedBankId.value == 'custom'
          ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: () {
        widget.selectedBankId.value = 'custom';
        Navigator.pop(context);
      },
    );
  }

  Widget _buildBankTile(BuildContext context, BankModel bank) {
    final isSelected = widget.selectedBankId.value == bank.id;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.account_balance_rounded,
        color: isSelected ? AppColors.primary : AppColors.getTextMuted(context),
      ),
      title: Text(bank.name, style: AppTextStyles.body(context)),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: () {
        widget.selectedBankId.value = bank.id;
        Navigator.pop(context);
      },
    );
  }
}
