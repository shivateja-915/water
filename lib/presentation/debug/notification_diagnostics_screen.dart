import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../firebase/firebase_token_repository.dart';
import '../../notifications/notification_constants.dart';
import '../../notifications/notification_debug.dart';
import '../../notifications/notification_diagnostics.dart';
import '../../notifications/notification_history.dart';
import '../../providers/reminder_provider.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_card.dart';

class NotificationDiagnosticsScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const NotificationDiagnosticsScreen({super.key, required this.onBack});

  @override
  ConsumerState<NotificationDiagnosticsScreen> createState() =>
      _NotificationDiagnosticsScreenState();
}

class _NotificationDiagnosticsScreenState
    extends ConsumerState<NotificationDiagnosticsScreen> {
  bool _loading = true;
  Object? _error;

  NotificationDiagnosticsData? _diagnostics;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      _diagnostics = await NotificationDiagnostics.collect();
      final tokenRepo = FirebaseTokenRepository();
      _fcmToken = await tokenRepo.getCachedToken();
    } catch (e) {
      _error = e;
      debugPrint('NotificationDiagnosticsScreen error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copyReport() async {
    try {
      final report = await NotificationDebug.generateReport();
      await Clipboard.setData(ClipboardData(text: report));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comprehensive Diagnostic Report copied to clipboard!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating report: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _requestBatteryOptimizationExemption() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Battery optimization exemption: ${status.name}'),
            backgroundColor: status.isGranted ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting battery exemption: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      await _loadData();
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
                    child: Text(
                      'UNIFIED DIAGNOSTICS',
                      style: AppTypography.headlineLg
                          .copyWith(color: AppColors.onSurface),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: _loadData,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Error Boundary Widget if exception caught
              if (_error != null) ...[
                NeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: 8),
                          Text('Diagnostics System Error',
                              style: AppTypography.bodyLg.copyWith(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('An exception occurred while gathering system status:',
                          style: AppTypography.labelSm),
                      const SizedBox(height: 4),
                      SelectableText(
                        _error.toString(),
                        style: AppTypography.labelSm.copyWith(
                          fontFamily: 'monospace',
                          color: AppColors.error,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      NeuButton(
                        label: '🔄 Retry Diagnostics',
                        onPressed: _loadData,
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

                // Section 1: System & OS Permissions
                _buildExpandableSection(
                  title: '1. SYSTEM & OS PERMISSIONS',
                  icon: Icons.security_outlined,
                  children: [
                    _diagItem(
                      label: 'Platform',
                      statusText: _diagnostics!.platform,
                      isGood: true,
                      explanation: 'Detected host execution platform.',
                    ),
                    const Divider(color: AppColors.outlineVariant),
                    _diagItem(
                      label: 'OS Notifications Support',
                      statusText: _diagnostics!.osNotificationsSupported ? 'Supported' : 'Unavailable (Web)',
                      isGood: _diagnostics!.osNotificationsSupported,
                      explanation: 'Ability to trigger native OS system shade notifications.',
                    ),
                    const Divider(color: AppColors.outlineVariant),
                    _diagItem(
                      label: 'POST_NOTIFICATIONS',
                      statusText: _diagnostics!.notificationPermission,
                      isGood: _diagnostics!.notificationPermission == 'Granted',
                      explanation: 'Android 13+ runtime permission for showing system shade alarms.',
                    ),
                    const Divider(color: AppColors.outlineVariant),
                    _diagItem(
                      label: 'SCHEDULE_EXACT_ALARM',
                      statusText: _diagnostics!.exactAlarmPermission,
                      isGood: _diagnostics!.exactAlarmPermission == 'Granted',
                      explanation: 'Android 12+ permission to wake the CPU at precise reminder times.',
                    ),
                    const Divider(color: AppColors.outlineVariant),
                    _diagItem(
                      label: 'Battery Optimization Exemption',
                      statusText: _diagnostics!.batteryOptPermission,
                      isGood: _diagnostics!.batteryOptPermission == 'Granted',
                      explanation: _diagnostics!.batteryOptPermission == 'Granted'
                          ? 'Device allows background alarms to fire during Doze mode.'
                          : 'Battery optimization may delay alarms when phone is idle.',
                      fixAction: _diagnostics!.batteryOptPermission != 'Granted'
                          ? _requestBatteryOptimizationExemption
                          : null,
                      fixActionLabel: '⚡ Request Exemption',
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Section 2: Firebase & FCM Status
                _buildExpandableSection(
                  title: '2. FIREBASE & CLOUD MESSAGING',
                  icon: Icons.cloud_done_outlined,
                  children: [
                    _diagItem(
                      label: 'Firebase Core Initialized',
                      statusText: _diagnostics!.firebaseInitialized ? 'Working' : 'Failed',
                      isGood: _diagnostics!.firebaseInitialized,
                      explanation: 'Firebase App connection status.',
                    ),
                    const Divider(color: AppColors.outlineVariant),
                    _diagItem(
                      label: 'FCM Registration Token',
                      statusText: _fcmToken != null && _fcmToken!.isNotEmpty ? 'Active' : 'Not Cached',
                      isGood: _fcmToken != null && _fcmToken!.isNotEmpty,
                      explanation: 'Unique device token used for remote push notifications.',
                    ),
                    if (_fcmToken != null) ...[
                      const SizedBox(height: 4),
                      SelectableText(
                        _fcmToken!,
                        style: AppTypography.labelSm.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Section 3: Alarms & Reminders Engine
                _buildExpandableSection(
                  title: '3. ALARMS & REMINDERS ENGINE',
                  icon: Icons.alarm_on_outlined,
                  children: [
                    _diagItem(
                      label: 'Current Reminder Mode',
                      statusText: (reminderSettings?.mode ?? 'Interval').toUpperCase(),
                      isGood: reminderSettings?.enabled ?? true,
                      explanation: 'Active reminder calculation algorithm.',
                    ),
                    const Divider(color: AppColors.outlineVariant),
                    _diagItem(
                      label: 'Pending OS Alarms Count',
                      statusText: '${_diagnostics!.pendingLocalCount}',
                      isGood: _diagnostics!.pendingLocalCount > 0,
                      explanation: 'Number of active alarms registered in Android AlarmManager.',
                    ),
                    const Divider(color: AppColors.outlineVariant),
                    _diagItem(
                      label: 'Timezone',
                      statusText: _diagnostics!.timezone,
                      isGood: true,
                      explanation: 'Local timezone used for alarm calculations.',
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Section 4: Services & Boot Receiver
                _buildExpandableSection(
                  title: '4. SERVICES & BOOT RECEIVER',
                  icon: Icons.settings_suggest_outlined,
                  children: [
                    _diagItem(
                      label: 'Boot Receiver Status',
                      statusText: _diagnostics!.bootStatus,
                      isGood: true,
                      explanation: 'Verifies alarm restoration state post phone reboot.',
                    ),
                    const Divider(color: AppColors.outlineVariant),
                    _diagItem(
                      label: 'Notification History Count',
                      statusText: '${history.length} items (${history.where((i) => !i.isRead).length} unread)',
                      isGood: true,
                      explanation: 'Total in-app notification records stored locally.',
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Section 5: Channels Inspector
                _buildExpandableSection(
                  title: '5. NOTIFICATION CHANNELS (5)',
                  icon: Icons.list_alt_outlined,
                  children: [
                    _channelRow(
                      NotificationConstants.channelWaterReminderName,
                      NotificationConstants.channelWaterReminderId,
                      'MAX / HIGH (Sound, Vibration, LED)',
                    ),
                    const Divider(color: AppColors.outlineVariant),
                    _channelRow(
                      NotificationConstants.channelHydrationTipsName,
                      NotificationConstants.channelHydrationTipsId,
                      'DEFAULT (Sound)',
                    ),
                    const Divider(color: AppColors.outlineVariant),
                    _channelRow(
                      NotificationConstants.channelAchievementsName,
                      NotificationConstants.channelAchievementsId,
                      'HIGH (Sound, Vibration)',
                    ),
                    const Divider(color: AppColors.outlineVariant),
                    _channelRow(
                      NotificationConstants.channelGeneralUpdatesName,
                      NotificationConstants.channelGeneralUpdatesId,
                      'DEFAULT',
                    ),
                    const Divider(color: AppColors.outlineVariant),
                    _channelRow(
                      NotificationConstants.channelBackgroundSyncName,
                      NotificationConstants.channelBackgroundSyncId,
                      'LOW (Silent)',
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Action Button
                NeuButton(
                  label: '📋 Copy Comprehensive Debug Report',
                  isFullWidth: true,
                  onPressed: _copyReport,
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return NeuCard(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 8),
          leading: Icon(icon, color: AppColors.primary),
          title: Text(
            title,
            style: AppTypography.bodyLg.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          children: children,
        ),
      ),
    );
  }

  Widget _diagItem({
    required String label,
    required String statusText,
    required bool isGood,
    required String explanation,
    VoidCallback? fixAction,
    String? fixActionLabel,
  }) {
    final statusColor = isGood ? AppColors.success : AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: AppTypography.bodyMd
                      .copyWith(fontWeight: FontWeight.w700)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  border: Border.all(color: statusColor, width: 1.5),
                ),
                child: Text(
                  statusText,
                  style: AppTypography.labelSm.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            explanation,
            style: AppTypography.labelSm
                .copyWith(color: AppColors.onSurfaceVariant, fontSize: 11),
          ),
          if (fixAction != null && fixActionLabel != null) ...[
            const SizedBox(height: 6),
            NeuButton.outline(
              label: fixActionLabel,
              onPressed: fixAction,
            ),
          ],
        ],
      ),
    );
  }

  Widget _channelRow(String name, String id, String importance) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTypography.bodyMd
                        .copyWith(fontWeight: FontWeight.w700)),
                Text('ID: $id | $importance',
                    style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
