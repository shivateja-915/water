import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

class NeuInput extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int maxLines;
  final bool enabled;

  const NeuInput({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.onChanged,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppColors.black,
                offset: const Offset(
                  AppSpacing.inputShadowOffset,
                  AppSpacing.inputShadowOffset,
                ),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            maxLines: maxLines,
            enabled: enabled,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.bodyMd.copyWith(
                color: AppColors.outline,
              ),
              suffixIcon: suffixIcon,
              prefixIcon: prefixIcon,
              errorText: errorText,
              errorStyle: AppTypography.labelSm.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
