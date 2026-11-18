import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/reminder_config.dart';
import '../../firebase/firebase_notification_handler.dart';
import '../../firebase/firebase_token_repository.dart';
import '../../notifications/notification_constants.dart';
import '../../notifications/notification_debug.dart';
import '../../notifications/notification_history.dart';
import '../../notifications/notification_manager.dart';
import '../../notifications/notification_models.dart';
import '../../notifications/notification_repository.dart';
import '../../notifications/notification_service.dart';
import '../../providers/reminder_provider.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_card.dart';

class NotificationTestLabScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const NotificationTestLabScreen({super.key, required this.onBack});

  @override
  ConsumerState<NotificationTestLabScreen> createState() =>
      _NotificationTestLabScreenState();
}

class _NotificationTestLabScreenState
    extends ConsumerState<NotificationTestLabScreen> {
  bool _loading = false;
  String? _fcmToken;
  int _pendingCount = 0;
  List<PendingNotificationRequest> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _refreshLab();
  }

  Future<void> _refreshLab() async {
    setState(() => _loading = true);
    try {
      final repo = FirebaseTokenRepository();
      _fcmToken = await repo.getCachedToken();
      _pendingCount = await NotificationService.getPendingNotificationCount();
      _pendingRequests = await NotificationService.getPendingNotifications();
    } catch (e) {
      debugPrint('Error refreshing Test Lab: $e');
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
    await _refreshLab();
  }

  Future<void> _sendDummyFcmPayload() async {
    await FirebaseNotificationHandler.logReceivedNotification(
      title: '🎁 Dummy FCM Remote Push',
      body: 'Stay hydrated! Achievement unlocked: 3-Day Water Streak!',
      data: {'type': 'achievement', 'streak': '3'},
      source: 'Test Lab Simulation',
    );

    ref.read(notificationHistoryProvider.notifier).addNotification(
          title: '🎁 Dummy FCM Remote Push',
          body: 'Stay hydrated! Achievement unlocked: 3-Day Water Streak!',
          type: NotificationType.achievement,
          channelId: NotificationConstants.channelAchievementsId,
        );

    await NotificationService.showNotificationNow(
      id: (DateTime.now().millisecondsSinceEpoch % 90000) + 5000,
      title: '🎁 Dummy FCM Remote Push',
      body: 'Stay hydrated! Achievement unlocked: 3-Day Water Streak!',
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
    await _refreshLab();
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
    await _refreshLab();
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
    await _refreshLab();
  }

  Future<void> _copyReport() async {
    final report = await NotificationDebug.generateReport();
    await Clipboard.setData(ClipboardData(text: report));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debug Report copied to clipboard!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _copyToken() {
    if (_fcmToken != null) {
      Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('FCM Token copied to clipboard!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(notificationHistoryProvider);

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
                            'NOTIFICATION TEST LAB',
                            style: AppTypography.headlineLg
                                .copyWith(color: AppColors.onSurface),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: AppColors.primary),
                          onPressed: _refreshLab,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Test Local & FCM Buttons
                    Text(
                      'SIMULATION & TRIGGER TOOLS',
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
                            label: '📲 Simulate FCM Remote Push Payload',
                            isFullWidth: true,
                            onPressed: _sendDummyFcmPayload,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          NeuButton.outline(
                            label: '💡 Send Hydration Tip Notification',
                            isFullWidth: true,
                            onPressed: () => _sendTestLocal(
                              NotificationConstants.channelHydrationTipsId,
                              '💡 Daily Hydration Tip',
                              'Drinking water before meals boosts metabolism and improves digestion.',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Pending OS Alarms List & Controls
                    Text(
                      'PENDING OS ALARMS LIST ($_pendingCount)',
                      style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    NeuCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active alarms registered in Android AlarmManager: $_pendingCount',
                            style: AppTypography.bodyMd
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          if (_pendingRequests.isNotEmpty)
                            ..._pendingRequests.take(10).map((req) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    '• Alarm ID: ${req.id} | Title: ${req.title ?? 'Reminder'} | Body: ${req.body ?? ''}',
                                    style: AppTypography.labelSm.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 11),
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

                    // Diagnostics & History Shortcuts
                    Text(
                      'REPORTS & HISTORY',
                      style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    NeuCard(
                      child: Column(
                        children: [
                          NeuButton.outline(
                            label:
                                '📜 View History (${history.length} items)',
                            isFullWidth: true,
                            onPressed: () =>
                                context.push('/notification-history'),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          NeuButton.outline(
                            label: '🛠️ Unified Diagnostics Dashboard',
                            isFullWidth: true,
                            onPressed: () =>
                                context.push('/notification-diagnostics'),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          NeuButton(
                            label: '📋 Copy Complete Debug Report',
                            isFullWidth: true,
                            onPressed: _copyReport,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // FCM Token Card
                    Text(
                      'FCM REGISTRATION TOKEN',
                      style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    NeuCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            _fcmToken ?? 'Token not cached',
                            style: AppTypography.labelSm.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          NeuButton(
                            label: '📋 Copy Token for Firebase Console',
                            isFullWidth: true,
                            onPressed: _copyToken,
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
