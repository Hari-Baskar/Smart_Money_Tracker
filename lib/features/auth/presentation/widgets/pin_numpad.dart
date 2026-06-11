import 'package:flutter/material.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';

class PinNumpad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onDeletePressed;

  const PinNumpad({
    super.key,
    required this.onNumberPressed,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSizes.h8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNumberButton(context, '${i * 3 + 1}'),
                _buildNumberButton(context, '${i * 3 + 2}'),
                _buildNumberButton(context, '${i * 3 + 3}'),
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSizes.h8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(width: AppSizes.w(70)), // Empty space for alignment
              _buildNumberButton(context, '0'),
              _buildDeleteButton(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNumberButton(BuildContext context, String number) {
    return InkWell(
      onTap: () => onNumberPressed(number),
      customBorder: const CircleBorder(),
      child: Container(
        width: AppSizes.w(70),
        height: AppSizes.w(70),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withOpacity(0.05),
        ),
        alignment: Alignment.center,
        child: Text(
          number,
          style: AppTextStyles.heading(context).copyWith(
            fontSize: AppSizes.w(28),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return InkWell(
      onTap: onDeletePressed,
      customBorder: const CircleBorder(),
      child: Container(
        width: AppSizes.w(70),
        height: AppSizes.w(70),
        alignment: Alignment.center,
        child: Icon(
          Icons.backspace_outlined,
          size: AppSizes.w(28),
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
