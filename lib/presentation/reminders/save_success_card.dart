import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../notifications/notification_models.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_card.dart';

class SaveSuccessCard extends StatelessWidget {
  final SaveResult result;

  const SaveSuccessCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final hasActive = result.dailyActiveCount > 0;
    final statusColor = hasActive ? AppColors.success : AppColors.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Status Banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            border: Border.all(color: statusColor, width: 2),
          ),
          child: Row(
            children: [
              Icon(
                hasActive ? Icons.check_circle : Icons.warning_amber_rounded,
                color: statusColor,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasActive ? 'REMINDERS UPDATED' : 'SCHEDULING NOTICE',
                      style: AppTypography.labelSm.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${result.dailyActiveCount} reminder(s) active daily',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Root Cause Diagnostic Card if 0 active reminders
        if (!hasActive && result.rootCauseDiagnostic != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              border: Border.all(color: AppColors.error, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'ROOT CAUSE DIAGNOSTIC',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  result.rootCauseDiagnostic!,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Pipeline Verification Summary
        Text(
          'PIPELINE VERIFICATION',
          style: AppTypography.labelSm.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        NeuCard(
          child: Column(
            children: [
              _summaryRow('Local DB Storage', result.localSaved ? '✓ PASS (Saved)' : '✗ FAIL'),
              _summaryRow('Supabase Cloud Sync', result.cloudSynced ? '✓ SYNCED' : 'ℹ OFFLINE CACHED'),
              _summaryRow('Daily Active Reminders', '${result.dailyActiveCount} times'),
              _summaryRow('OS Verified Pending Alarms', '${result.pendingNotificationCount} alarms'),
              _summaryRow('Next Scheduled Reminder', result.nextReminderTime ?? 'None'),
              _summaryRow('Mode', result.mode == 'interval' ? 'Interval (${result.intervalMinutes}m)' : 'Fixed Times'),
              _summaryRow('Quiet Hours (DND)', '${result.dndStart} - ${result.dndEnd}'),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Active Daily Schedule Chips
        if (result.dailyScheduleTimes.isNotEmpty) ...[
          Text(
            'ACTIVE DAILY SCHEDULE TIMES (${result.dailyScheduleTimes.length})',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: result.dailyScheduleTimes.map((t) {
              final hour = (t.hour % 12 == 0) ? 12 : t.hour % 12;
              final minute = t.minute.toString().padLeft(2, '0');
              final period = t.hour >= 12 ? 'PM' : 'AM';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  border: Border.all(color: AppColors.black, width: 1.5),
                ),
                child: Text(
                  '$hour:$minute $period',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        NeuButton(
          label: 'OK',
          isFullWidth: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11),
          ),
          Text(
            value,
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
