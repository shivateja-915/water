import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class NeuCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final double shadowOffset;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const NeuCard({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.surfaceContainerLowest,
    this.borderColor = AppColors.black,
    this.shadowOffset = AppSpacing.shadowOffset,
    this.padding,
    this.onTap,
    this.width,
    this.height,
  });

  const NeuCard.primary({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.primaryContainer,
    this.borderColor = AppColors.black,
    this.shadowOffset = AppSpacing.shadowOffset,
    this.padding,
    this.onTap,
    this.width,
    this.height,
  });

  const NeuCard.secondary({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.secondaryContainer,
    this.borderColor = AppColors.black,
    this.shadowOffset = AppSpacing.shadowOffset,
    this.padding,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding ??
            const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: AppSpacing.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor,
              offset: Offset(shadowOffset, shadowOffset),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
