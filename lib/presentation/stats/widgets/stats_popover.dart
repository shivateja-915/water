import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../widgets/neu_button.dart';

class StatsPopover {
  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
    String? detailText,
    String? primaryValue,
    String? secondaryValue,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(AppSpacing.screenMargin),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.black, width: 3),
            boxShadow: const [
              BoxShadow(
                color: AppColors.black,
                offset: Offset(5, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: AppTypography.headlineMd.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.black, width: 2),
                        color: const Color(0xFFFFDE00),
                      ),
                      child: const Icon(Icons.close, size: 18, color: AppColors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: AppTypography.bodyLg.copyWith(
                  fontSize: 14,
                  color: const Color(0xFF555555),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (primaryValue != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    border: Border.all(color: AppColors.black, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        primaryValue,
                        style: AppTypography.headlineLg.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0047FF),
                        ),
                      ),
                      if (secondaryValue != null)
                        Text(
                          secondaryValue,
                          style: AppTypography.bodyLg.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.black,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (detailText != null) ...[
                const SizedBox(height: 10),
                Text(
                  detailText,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                NeuButton(
                  label: actionLabel,
                  isFullWidth: true,
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAction();
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
