import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

class NeuButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final double shadowOffset;
  final bool isFullWidth;
  final bool isLoading;
  final IconData? icon;

  const NeuButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor = AppColors.primary,
    this.textColor = AppColors.onPrimary,
    this.borderColor = AppColors.black,
    this.shadowOffset = AppSpacing.shadowOffset,
    this.isFullWidth = false,
    this.isLoading = false,
    this.icon,
  });

  const NeuButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor = AppColors.secondaryContainer,
    this.textColor = AppColors.onSecondaryContainer,
    this.borderColor = AppColors.black,
    this.shadowOffset = AppSpacing.shadowOffset,
    this.isFullWidth = false,
    this.isLoading = false,
    this.icon,
  });

  const NeuButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor = AppColors.surfaceContainerLowest,
    this.textColor = AppColors.onSurface,
    this.borderColor = AppColors.black,
    this.shadowOffset = AppSpacing.shadowOffset,
    this.isFullWidth = false,
    this.isLoading = false,
    this.icon,
  });

  const NeuButton.error({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor = AppColors.error,
    this.textColor = AppColors.onError,
    this.borderColor = AppColors.black,
    this.shadowOffset = AppSpacing.shadowOffset,
    this.isFullWidth = false,
    this.isLoading = false,
    this.icon,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final offset = _isPressed ? 1.0 : widget.shadowOffset;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          _isPressed ? widget.shadowOffset - 1 : 0,
          _isPressed ? widget.shadowOffset - 1 : 0,
          0,
        ),
        width: widget.isFullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          border: Border.all(
            color: widget.borderColor,
            width: AppSpacing.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.borderColor,
              offset: Offset(offset, offset),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: widget.isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.textColor,
                ),
              )
            : Row(
                mainAxisSize: widget.isFullWidth
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: widget.textColor, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    widget.label.toUpperCase(),
                    style: AppTypography.bodyMd.copyWith(
                      color: widget.textColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
