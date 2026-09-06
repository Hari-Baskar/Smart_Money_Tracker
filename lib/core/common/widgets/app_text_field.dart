import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_money_tracker/core/constants/app_colors.dart';
import 'package:smart_money_tracker/core/constants/app_sizes.dart';
import 'package:smart_money_tracker/core/theme/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? suffixText;
  final TextStyle? suffixStyle;
  final bool autofocus;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final int? maxLines;
  final int? minLines;
  final String? counterText;
  final Color? fillColor;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final TextAlign textAlign;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixText,
    this.suffixStyle,
    this.autofocus = false,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
    this.minLines,
    this.counterText = '',
    this.fillColor,
    this.focusNode,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.onTap,
    this.contentPadding,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final effectiveFillColor =
        fillColor ??
        (isDark
            ? AppColors.surfaceContainerLowestDark
            : AppColors.surfaceContainerLight);

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      textAlign: textAlign,
      inputFormatters: inputFormatters,
      validator: validator,
      style: AppTextStyles.body(context),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        hintStyle: AppTextStyles.body(
          context,
          color: AppColors.getTextMuted(context),
        ),
        labelStyle: AppTextStyles.body(
          context,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        suffixText: suffixText,
        suffixStyle: suffixStyle,
        counterText: counterText,
        filled: true,
        fillColor: effectiveFillColor,
        contentPadding:
            contentPadding ??
            EdgeInsets.symmetric(
              horizontal: AppSizes.w16,
              vertical: AppSizes.h10,
            ),
        border: OutlineInputBorder(
          borderRadius: AppSizes.boxBorderRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSizes.boxBorderRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSizes.boxBorderRadius,
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSizes.boxBorderRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppSizes.boxBorderRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}
