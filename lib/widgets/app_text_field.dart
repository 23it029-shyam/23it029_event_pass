import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final Widget? leadingIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool isMono;

  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.leadingIcon,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      style: isMono ? AppTextStyles.mono.copyWith(fontSize: 16) : AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: leadingIcon,
        labelStyle: AppTextStyles.bodyMedium,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary.withOpacity(0.5)),
      ),
    );
  }
}
