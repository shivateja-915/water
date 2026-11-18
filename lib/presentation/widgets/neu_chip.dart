import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

class NeuChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color selectedColor;

  const NeuChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
    this.selectedColor = AppColors.secondaryContainer,
  });

  @override
  State<NeuChip> createState() => _NeuChipState();
}

class _NeuChipState extends State<NeuChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final offset = _isPressed ? 1.0 : 3.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          _isPressed ? 2.0 : 0,
          _isPressed ? 2.0 : 0,
          0,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? widget.selectedColor
              : AppColors.surfaceContainerLowest,
          border: Border.all(
            color: AppColors.black,
            width: AppSpacing.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black,
              offset: Offset(offset, offset),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: 16,
                color: widget.isSelected
                    ? AppColors.onSecondaryContainer
                    : AppColors.onSurface,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              widget.label.toUpperCase(),
              style: AppTypography.labelSm.copyWith(
                color: widget.isSelected
                    ? AppColors.onSecondaryContainer
                    : AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
