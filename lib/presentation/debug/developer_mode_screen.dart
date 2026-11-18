import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/reminder_config.dart';
import '../../firebase/firebase_notification_handler.dart';
import '../../firebase/firebase_token_repository.dart';
import '../../notifications/notification_constants.dart';
import '../../notifications/notification_debug.dart';
import '../../notifications/notification_diagnostics.dart';
import '../../notifications/notification_history.dart';
import '../../notifications/notification_manager.dart';
import '../../notifications/notification_models.dart';
import '../../notifications/notification_repository.dart';
import '../../notifications/notification_service.dart';
import '../../providers/developer_mode_provider.dart';
import '../../providers/reminder_provider.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_card.dart';

class DeveloperModeScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const DeveloperModeScreen({super.key, required this.onBack});

  @override
  ConsumerState<DeveloperModeScreen> createState() =>
      _DeveloperModeScreenState();
}

class _DeveloperModeScreenState extends ConsumerState<DeveloperModeScreen> {
  bool _loading = true;
  Object? _error;
  NotificationDiagnosticsData? _diagnostics;
  String? _fcmToken;
  List<PendingNotificationRequest> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _loadDeveloperData();
  }

  Future<void> _loadDeveloperData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      _diagnostics = await NotificationDiagnostics.collect();
      final tokenRepo = FirebaseTokenRepository();
      _fcmToken = await tokenRepo.getCachedToken();
      _pendingRequests = await NotificationService.getPendingNotifications();
    } catch (e) {
      _error = e;
      debugPrint('DeveloperModeScreen error: $e');
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
          content: Text('Test notification fired on $channelId!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
    await _loadDeveloperData();
  }

  Future<void> _sendDummyFcmPayload() async {
    await FirebaseNotificationHandler.logReceivedNotification(
      title: '🎁 Dev FCM Push Test',
      body: 'Developer Mode active: Simulated remote push payload!',
      data: {'type': 'achievement', 'dev': 'true'},
      source: 'Developer Mode Test',
    );

    ref.read(notificationHistoryProvider.notifier).addNotification(
          title: '🎁 Dev FCM Push Test',
          body: 'Developer Mode active: Simulated remote push payload!',
          type: NotificationType.achievement,
          channelId: NotificationConstants.channelAchievementsId,
        );

    await NotificationService.showNotificationNow(
      id: (DateTime.now().millisecondsSinceEpoch % 90000) + 5000,
      title: '🎁 Dev FCM Push Test',
      body: 'Developer Mode active: Simulated remote push payload!',
      channelId: NotificationConstants.channelAchievementsId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dummy FCM Remote Push Payload simulated!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
    await _loadDeveloperData();
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
            content: Text('OS Alarm Schedule Rebuilt Successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
    await _loadDeveloperData();
  }

  Future<void> _cancelAllNotifications() async {
    await NotificationService.cancelAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All pending OS notifications cancelled.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    await _loadDeveloperData();
  }

  Future<void> _copyReport() async {
    final report = await NotificationDebug.generateReport();
    await Clipboard.setData(ClipboardData(text: report));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comprehensive Diagnostic Report copied!'),
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
    final reminderSettings = ref.watch(reminderSettingsProvider).valueOrNull;

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEVELOPER MODE',
                          style: AppTypography.headlineLg
                              .copyWith(color: AppColors.primary),
                        ),
                        Text(
                          'Siply Engineering & Debug Suite',
                          style: AppTypography.labelSm
                              .copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: _loadDeveloperData,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              if (_error != null) ...[
                NeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Developer Diagnostics Error',
                          style: AppTypography.bodyLg
                              .copyWith(color: AppColors.error)),
                      const SizedBox(height: 4),
                      Text(_error.toString(), style: AppTypography.labelSm),
                      const SizedBox(height: 8),
                      NeuButton(
                        label: 'Retry',
                        onPressed: _loadDeveloperData,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (_loading)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ))
              else if (_diagnostics != null) ...[

                // Section 1: System & OS Status
                _buildCardSection(
                  title: '1. SYSTEM & PERMISSIONS STATUS',
                  icon: Icons.developer_board_outlined,
                  children: [
                    _statusRow('Host Platform', _diagnostics!.platform, true),
                    const Divider(color: AppColors.outlineVariant),
                    _statusRow('OS Notifications',
                        _diagnostics!.osNotificationsSupported ? 'Supported' : 'Web Stub', _diagnostics!.osNotificationsSupported),
                    const Divider(color: AppColors.outlineVariant),
                    _statusRow('POST_NOTIFICATIONS', _diagnostics!.notificationPermission,
                        _diagnostics!.notificationPermission == 'Granted'),
                    const Divider(color: AppColors.outlineVariant),
                    _statusRow('SCHEDULE_EXACT_ALARM', _diagnostics!.exactAlarmPermission,
                        _diagnostics!.exactAlarmPermission == 'Granted'),
                    const Divider(color: AppColors.outlineVariant),
                    _statusRow('Battery Optimization', _diagnostics!.batteryOptPermission,
                        _diagnostics!.batteryOptPermission == 'Granted'),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Section 2: Firebase FCM Suite
                _buildCardSection(
                  title: '2. FIREBASE & CLOUD MESSAGING',
                  icon: Icons.cloud_done_outlined,
                  children: [
                    _statusRow('Firebase Core',
                        _diagnostics!.firebaseInitialized ? 'Connected' : 'Disconnected', _diagnostics!.firebaseInitialized),
                    const Divider(color: AppColors.outlineVariant),
                    _statusRow('FCM Token Status',
                        _fcmToken != null ? 'Active & Cached' : 'Not Cached', _fcmToken != null),
                    if (_fcmToken != null) ...[
                      const SizedBox(height: 6),
                      SelectableText(
                        _fcmToken!,
                        style: AppTypography.labelSm.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      NeuButton(
                        label: '📋 Copy FCM Token',
                        onPressed: _copyToken,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Section 3: Notification Test Lab
                _buildCardSection(
                  title: '3. NOTIFICATION TEST LAB',
                  icon: Icons.science_outlined,
                  children: [
                    NeuButton(
                      label: '💧 Trigger Water Alarm Notification',
                      isFullWidth: true,
                      onPressed: () => _sendTestLocal(
                        NotificationConstants.channelWaterReminderId,
                        '💧 Drink Water Now!',
                        'Time for a 250ml glass of water to maintain your hydration streak.',
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
                      label: '💡 Trigger Hydration Tip Alert',
                      isFullWidth: true,
                      onPressed: () => _sendTestLocal(
                        NotificationConstants.channelHydrationTipsId,
                        '💡 Daily Hydration Tip',
                        'Drinking water regularly boosts cognitive function and physical performance.',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Section 4: Pending Alarms Inspector & Rebuilder
                _buildCardSection(
                  title: '4. PENDING OS ALARMS (${_diagnostics!.pendingLocalCount})',
                  icon: Icons.alarm_on_outlined,
                  children: [
                    Text(
                      'Mode: ${(reminderSettings?.mode ?? 'interval').toUpperCase()} | Total Alarms: ${_diagnostics!.pendingLocalCount}',
                      style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (_pendingRequests.isNotEmpty)
                      ..._pendingRequests.take(5).map((req) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '• Alarm ID #${req.id}: ${req.title ?? 'Reminder'}',
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

                const SizedBox(height: AppSpacing.sm),

                // Section 5: History Log & Debug Report
                _buildCardSection(
                  title: '5. DEBUG LOGS & REPORT',
                  icon: Icons.description_outlined,
                  children: [
                    Text(
                      'In-App History Log Count: ${history.length} items',
                      style: AppTypography.bodyMd,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    NeuButton(
                      label: '📋 Copy Full Diagnostic Report',
                      isFullWidth: true,
                      onPressed: _copyReport,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Lock Developer Mode Button
                NeuButton.outline(
                  label: '🔒 Lock Developer Mode',
                  isFullWidth: true,
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await ref.read(developerModeProvider.notifier).lockDeveloperMode();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Developer Mode Locked.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    widget.onBack();
                  },
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.bodyLg.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...children,
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, bool isGood) {
    final color = isGood ? AppColors.success : AppColors.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
          Text(value, style: AppTypography.bodyMd.copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
