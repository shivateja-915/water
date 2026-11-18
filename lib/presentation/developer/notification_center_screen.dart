import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/reminder_config.dart';
import '../../firebase/firebase_notification_handler.dart';
import '../../notifications/notification_constants.dart';
import '../../notifications/notification_history.dart';
import '../../notifications/notification_manager.dart';
import '../../notifications/notification_models.dart';
import '../../notifications/notification_repository.dart';
import '../../notifications/notification_service.dart';
import '../../providers/reminder_provider.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_card.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const NotificationCenterScreen({super.key, required this.onBack});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  bool _loading = false;
  int _pendingCount = 0;
  List<PendingNotificationRequest> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _loading = true);
    try {
      _pendingCount = await NotificationService.getPendingNotificationCount();
      _pendingRequests = await NotificationService.getPendingNotifications();
    } catch (e) {
      debugPrint('Error refreshing Notification Center: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendTestLocal(String channelId, String title, String body) async {
    final manager = ref.read(notificationManagerProvider);
    await manager.sendTestNotification(
      channelId: channelId,
      title: title,
      body: body,
    );

    ref.read(notificationHistoryProvider.notifier).addNotification(
          title: title,
          body: body,
          type: NotificationType.reminder,
          channelId: channelId,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test notification sent on $channelId!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
    await _refreshData();
  }

  Future<void> _sendDummyFcmPayload() async {
    await FirebaseNotificationHandler.logReceivedNotification(
      title: '🎁 Test FCM Remote Push',
      body: 'Achievement unlocked: 3-Day Water Streak!',
      data: {'type': 'achievement', 'streak': '3'},
      source: 'Test Lab Simulation',
    );

    ref.read(notificationHistoryProvider.notifier).addNotification(
          title: '🎁 Test FCM Remote Push',
          body: 'Achievement unlocked: 3-Day Water Streak!',
          type: NotificationType.achievement,
          channelId: NotificationConstants.channelAchievementsId,
        );

    await NotificationService.showNotificationNow(
      id: (DateTime.now().millisecondsSinceEpoch % 90000) + 5000,
      title: '🎁 Test FCM Remote Push',
      body: 'Achievement unlocked: 3-Day Water Streak!',
      channelId: NotificationConstants.channelAchievementsId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dummy FCM notification payload simulated!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
    await _refreshData();
  }

  Future<void> _generateReminderIn1Min() async {
    final target = DateTime.now().add(const Duration(minutes: 1));
    await NotificationService.scheduleSingleNotification(
      id: 9999,
      dateTime: target,
      title: '⏱️ 1-Minute Test Reminder',
      body: 'This test reminder was scheduled 1 minute ago!',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('1-Minute Test Reminder Scheduled!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
    await _refreshData();
  }

  Future<void> _rebuildSchedule() async {
    final settings = ref.read(reminderSettingsProvider).valueOrNull;
    if (settings != null) {
      final config = ReminderConfig.fromSettings(
        enabled: settings.enabled,
        mode: settings.mode,
        intervalMinutes: settings.computedIntervalMinutes,
        fixedTimes: settings.fixedTimes,
        dndStart: settings.dndStart,
        dndEnd: settings.dndEnd,
        snoozeDefaultMinutes: settings.snoozeDefaultMinutes,
        deletedTimes: settings.deletedTimes,
      );

      final repo = NotificationRepository();
      await repo.applySchedule(config);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder schedule rebuilt successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
    await _refreshData();
  }

  Future<void> _cancelAllNotifications() async {
    await NotificationService.cancelAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All pending local notifications cancelled.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    await _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenMargin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onBack,
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
                            'NOTIFICATION CENTER',
                            style: AppTypography.headlineLg
                                .copyWith(color: AppColors.onSurface),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: AppColors.primary),
                          onPressed: _refreshData,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Test Lab Tools
                    Text(
                      'TEST LAB ACTIONS',
                      style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    NeuCard(
                      child: Column(
                        children: [
                          NeuButton(
                            label: '💧 Trigger Local Alarm (Water Reminder)',
                            isFullWidth: true,
                            onPressed: () => _sendTestLocal(
                              NotificationConstants.channelWaterReminderId,
                              '💧 Time to Drink Water!',
                              'Time for a 250ml glass of water to keep your daily goal on track.',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          NeuButton.outline(
                            label: '📲 Simulate FCM Push Payload',
                            isFullWidth: true,
                            onPressed: _sendDummyFcmPayload,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          NeuButton.outline(
                            label: '⏱️ Generate Reminder in 1 Minute',
                            isFullWidth: true,
                            onPressed: _generateReminderIn1Min,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Pending Alarms List
                    Text(
                      'PENDING ALARMS LIST ($_pendingCount)',
                      style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    NeuCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_pendingRequests.isEmpty)
                            Text('No pending alarms registered.', style: AppTypography.bodyMd)
                          else
                            ..._pendingRequests.map((req) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Text(
                                    '• Alarm #${req.id}: ${req.title ?? 'Reminder'} - ${req.body ?? ''}',
                                    style: AppTypography.labelSm.copyWith(
                                        color: AppColors.onSurfaceVariant, fontSize: 11),
                                  ),
                                )),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: NeuButton(
                                  label: '🔄 Rebuild Schedule',
                                  onPressed: _rebuildSchedule,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: NeuButton.outline(
                                  label: '🗑️ Cancel All',
                                  onPressed: _cancelAllNotifications,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // History Link
                    NeuButton.outline(
                      label: '📜 Open Notification History',
                      isFullWidth: true,
                      onPressed: () => context.push('/notification-history'),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
      ),
    );
  }
}
