import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/constants/payment_constants.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';

class BankPickerWidget extends StatelessWidget {
  final ValueNotifier<String?> selectedBankId;
  final TextEditingController customBankController;

  const BankPickerWidget({
    super.key,
    required this.selectedBankId,
    required this.customBankController,
  });

  @override
  Widget build(BuildContext context) {
    final bankName = PaymentConstants.getBankName(selectedBankId.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showBankBottomSheet(context),
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

  void _showBankBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = AppColors.isDark(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.r24)),
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
                    borderRadius: BorderRadius.circular(AppSizes.r(2)),
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
                      leading: Icon(Icons.remove_circle_outline_rounded, color: AppColors.getTextMuted(context)),
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
                        leading: Icon(Icons.account_balance_rounded, color: isSelected ? AppColors.primary : AppColors.getTextMuted(context)),
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
