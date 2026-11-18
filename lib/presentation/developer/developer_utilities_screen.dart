import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../notifications/notification_debug.dart';
import '../../notifications/notification_history.dart';
import '../../notifications/notification_service.dart';
import '../../providers/developer_mode_provider.dart';
import '../../providers/reminder_provider.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_card.dart';

class DeveloperUtilitiesScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const DeveloperUtilitiesScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: AppColors.black,
                            width: AppSpacing.borderWidth),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.black,
                            offset: Offset(3, 3),
                          ),
                        ],
                        color: AppColors.surfaceContainerLowest,
                      ),
                      child: const Icon(Icons.arrow_back, size: 20),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'DEVELOPER UTILITIES',
                      style: AppTypography.headlineLg
                          .copyWith(color: AppColors.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              NeuCard(
                child: Column(
                  children: [
                    NeuButton(
                      label: '📄 Export Full System Debug Report',
                      isFullWidth: true,
                      onPressed: () async {
                        final report = await NotificationDebug.generateReport();
                        await Clipboard.setData(ClipboardData(text: report));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Debug report copied to clipboard!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    NeuButton.outline(
                      label: '🔄 Force Cloud Re-Sync',
                      isFullWidth: true,
                      onPressed: () async {
                        final settings =
                            ref.read(reminderSettingsProvider).valueOrNull;
                        if (settings != null) {
                          final result = await ref
                              .read(reminderSettingsProvider.notifier)
                              .saveSettings(settings);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result.success
                                    ? 'Re-sync complete!'
                                    : 'Local saved, cloud error: ${result.errorMessage}'),
                                backgroundColor: result.success
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    NeuButton.outline(
                      label: '🗑️ Clear Local Notification History',
                      isFullWidth: true,
                      onPressed: () async {
                        await ref
                            .read(notificationHistoryProvider.notifier)
                            .clearAll();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notification history cleared.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    NeuButton.outline(
                      label: '🗑️ Clear Pending OS Notifications',
                      isFullWidth: true,
                      onPressed: () async {
                        await NotificationService.cancelAll();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All OS notifications cancelled.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(color: AppColors.outlineVariant),
                    NeuButton(
                      label: '🔒 Lock Developer Mode',
                      isFullWidth: true,
                      onPressed: () async {
                        await ref
                            .read(developerModeProvider.notifier)
                            .lockDeveloperMode();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Developer Mode locked.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          onBack();
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
