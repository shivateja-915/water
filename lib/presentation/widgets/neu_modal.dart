import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

class NeuModal extends StatelessWidget {
  final Widget child;
  final String? title;
  final VoidCallback? onClose;

  const NeuModal({
    super.key,
    required this.child,
    this.title,
    this.onClose,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => NeuModal(
        title: title,
        onClose: () => Navigator.of(context).pop(),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border.all(
            color: AppColors.black,
            width: AppSpacing.borderWidth,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.black,
              offset: Offset(
                AppSpacing.shadowOffset,
                AppSpacing.shadowOffset,
              ),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.black,
                      width: AppSpacing.borderWidth,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (onClose != null)
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.black,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
