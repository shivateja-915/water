import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../data/services/cloud_sync_service.dart';
import '../../notifications/notification_diagnostics.dart';
import '../../notifications/notification_service.dart';
import '../../providers/reminder_provider.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_card.dart';

class DiagnosticsCenterScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const DiagnosticsCenterScreen({super.key, required this.onBack});

  @override
  ConsumerState<DiagnosticsCenterScreen> createState() =>
      _DiagnosticsCenterScreenState();
}

class _DiagnosticsCenterScreenState
    extends ConsumerState<DiagnosticsCenterScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  NotificationDiagnosticsData? _diagnostics;
  SyncReport? _syncReport;
  int _pendingNotifCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDiagnostics();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDiagnostics();
    }
  }

  Future<void> _loadDiagnostics() async {
    setState(() => _loading = true);
    try {
      _diagnostics = await NotificationDiagnostics.collect();
      _pendingNotifCount =
          await NotificationService.getPendingNotificationCount();
      final settings = ref.read(reminderSettingsProvider).valueOrNull;
      final localRev = settings?.revision ?? 1;
      _syncReport = await CloudSyncService.instance.getSyncReport(localRev);
    } catch (e) {
      debugPrint('Diagnostics error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                            'DIAGNOSTICS CENTER',
                            style: AppTypography.headlineLg
                                .copyWith(color: AppColors.onSurface),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: AppColors.primary),
                          onPressed: _loadDiagnostics,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    NeuCard(
                      child: Column(
                        children: [
                          _diagRow(
                            'Host Platform',
                            _diagnostics?.platform ?? 'android',
                            'PASS',
                            AppColors.success,
                          ),
                          const Divider(color: AppColors.outlineVariant),
                          _diagRow(
                            'OS Notifications',
                            _diagnostics?.osNotificationsSupported == true ? 'Supported' : 'Web Stub',
                            _diagnostics?.osNotificationsSupported == true ? 'PASS' : 'WARNING',
                            _diagnostics?.osNotificationsSupported == true ? AppColors.success : AppColors.error,
                          ),
                          const Divider(color: AppColors.outlineVariant),
                          _diagRow(
                            'POST_NOTIFICATIONS',
                            _diagnostics?.notificationPermission ?? 'Granted',
                            _diagnostics?.notificationPermission == 'Granted' ? 'PASS' : 'FAILED',
                            _diagnostics?.notificationPermission == 'Granted' ? AppColors.success : AppColors.error,
                          ),
                          const Divider(color: AppColors.outlineVariant),
                          _diagRow(
                            'SCHEDULE_EXACT_ALARM',
                            _diagnostics?.exactAlarmPermission ?? 'Granted',
                            _diagnostics?.exactAlarmPermission == 'Granted' ? 'PASS' : 'FAILED',
                            _diagnostics?.exactAlarmPermission == 'Granted' ? AppColors.success : AppColors.error,
                          ),
                          const Divider(color: AppColors.outlineVariant),
                          _diagRow(
                            'Battery Optimization',
                            _diagnostics?.batteryOptPermission ?? 'Granted',
                            _diagnostics?.batteryOptPermission == 'Granted' ? 'PASS' : 'WARNING',
                            _diagnostics?.batteryOptPermission == 'Granted' ? AppColors.success : Colors.orange,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'SYNCHRONIZATION & REPOSITORY REPORT',
                      style: AppTypography.labelSm
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    NeuCard(
                      child: Column(
                        children: [
                          _diagRow(
                            'Local Version / Revision',
                            'Rev ${_syncReport?.localRevision ?? 1}',
                            'LOCAL',
                            AppColors.primary,
                          ),
                          const Divider(color: AppColors.outlineVariant),
                          _diagRow(
                            'Remote Version / Revision',
                            'Rev ${_syncReport?.remoteRevision ?? 0}',
                            'CLOUD',
                            AppColors.secondary,
                          ),
                          const Divider(color: AppColors.outlineVariant),
                          _diagRow(
                            'Conflict State',
                            _syncReport?.conflictState ?? 'NONE',
                            _syncReport?.conflictState == 'SYNCED' ? 'PASS' : 'OK',
                            AppColors.success,
                          ),
                          const Divider(color: AppColors.outlineVariant),
                          _diagRow(
                            'Pending Uploads / Downloads',
                            'Uploads: ${_syncReport?.pendingUploads == true ? "YES" : "NO"} | Downloads: ${_syncReport?.pendingDownloads == true ? "YES" : "NO"}',
                            _syncReport?.pendingUploads == false && _syncReport?.pendingDownloads == false ? 'IDLE' : 'PENDING',
                            _syncReport?.pendingUploads == false ? AppColors.success : Colors.orange,
                          ),
                          const Divider(color: AppColors.outlineVariant),
                          _diagRow(
                            'Current Scheduler Count',
                            'Active Today: ${_diagnostics?.pendingLocalCount ?? 0} reminders',
                            (_diagnostics?.pendingLocalCount ?? 0) > 0 ? 'ACTIVE' : 'IDLE',
                            (_diagnostics?.pendingLocalCount ?? 0) > 0 ? AppColors.success : AppColors.onSurfaceVariant,
                          ),
                          const Divider(color: AppColors.outlineVariant),
                          _diagRow(
                            'Pending Notification Count',
                            'OS Alarms: $_pendingNotifCount registered',
                            _pendingNotifCount > 0 ? 'PASS' : '0 PENDING',
                            _pendingNotifCount > 0 ? AppColors.success : AppColors.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),



                    NeuButton(
                      label: '🔄 Re-Run Full Diagnostic Audit',
                      isFullWidth: true,
                      onPressed: _loadDiagnostics,
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _diagRow(String title, String val, String badgeText, Color badgeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w700)),
                Text(val, style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              border: Border.all(color: badgeColor, width: 1.5),
            ),
            child: Text(
              badgeText,
              style: AppTypography.labelSm.copyWith(
                  color: badgeColor, fontWeight: FontWeight.w900, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
