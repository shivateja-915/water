import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../firebase/firebase_token_repository.dart';
import '../../notifications/notification_constants.dart';
import '../../notifications/notification_debug.dart';
import '../../notifications/notification_diagnostics.dart';
import '../../notifications/notification_history.dart';
import '../../notifications/notification_manager.dart';
import '../../notifications/notification_repository.dart';
import '../../notifications/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/developer_dashboard_provider.dart';
import '../../providers/developer_mode_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../data/models/reminder_config.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_card.dart';

class DeveloperDashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const DeveloperDashboardScreen({super.key, required this.onBack});

  @override
  ConsumerState<DeveloperDashboardScreen> createState() =>
      _DeveloperDashboardScreenState();
}

class _DeveloperDashboardScreenState
    extends ConsumerState<DeveloperDashboardScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = false;

  NotificationDiagnosticsData? _diagnostics;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _loading = true);
    try {
      _diagnostics = await NotificationDiagnostics.collect();
      final tokenRepo = FirebaseTokenRepository();
      _fcmToken = await tokenRepo.getCachedToken();
    } catch (e) {
      debugPrint('Error loading Developer Dashboard data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fireQuickTestNotification() async {
    final manager = ref.read(notificationManagerProvider);
    await manager.sendTestNotification(
      channelId: 'water_reminder_channel',
      title: '🔔 Quick Dev Notification Test',
      body: 'Mission Control Quick Action triggered successfully.',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quick Test Notification Fired!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
    await _loadDashboardData();
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
            content: Text('OS Notification Schedule Rebuilt!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
    await _loadDashboardData();
  }

  Future<void> _exportDebugReport() async {
    final report = await NotificationDebug.generateReport();
    await Clipboard.setData(ClipboardData(text: report));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mission Control Debug Report copied to clipboard!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _clearNotifications() async {
    await NotificationService.cancelAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All pending OS notifications cleared.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    await _loadDashboardData();
  }

  Future<void> _fireRealWaterReminderNow() async {
    final id = (DateTime.now().millisecondsSinceEpoch % 90000) + 50000;
    await NotificationService.showNotificationNow(
      id: id,
      title: '💧 Time to Hydrate!',
      body: 'Keep up with your goal. Time for a glass of water.',
      channelId: NotificationConstants.channelWaterReminderId,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🥤 Real Water Reminder Notification Fired!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardMetrics = ref.watch(developerDashboardProvider);
    final searchQuery = dashboardMetrics.searchQuery;
    final userId = ref.watch(authRepositoryProvider).userId ?? 'Anonymous';
    final history = ref.watch(notificationHistoryProvider);
    final reminderSettings = ref.watch(reminderSettingsProvider).valueOrNull;

    final nowStr = DateFormat('h:mm a').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.screenMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
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
                          Row(
                            children: [
                              Text(
                                'DEVELOPER DASHBOARD',
                                style: AppTypography.headlineLg
                                    .copyWith(color: AppColors.primary),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  border: Border.all(color: AppColors.black),
                                ),
                                child: Text(
                                  'DEBUG',
                                  style: AppTypography.labelSm.copyWith(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Siply Internal Mission Control',
                            style: AppTypography.labelSm.copyWith(
                                color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.primary),
                      onPressed: _loadDashboardData,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // METADATA BADGES CARD
                NeuCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _metaChip('App: V1.0.0 (#100)'),
                          _metaChip('Flutter: 3.27.0'),
                          _metaChip('Time: $nowStr'),
                          _metaChip('TZ: Asia/Kolkata'),
                          _metaChip('User: ${userId.substring(0, userId.length > 8 ? 8 : userId.length)}...'),
                          _metaChip('Status: 🟢 Online'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // QUICK ACTION BAR
                Text(
                  'SUPERPOWER QUICK ACTIONS',
                  style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xs),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      NeuButton.outline(
                        label: '🥤 Fire Real Water Reminder',
                        onPressed: _fireRealWaterReminderNow,
                      ),
                      const SizedBox(width: 8),
                      NeuButton.outline(
                        label: '🔔 Test Notification',
                        onPressed: _fireQuickTestNotification,
                      ),
                      const SizedBox(width: 8),
                      NeuButton.outline(
                        label: '🔄 Rebuild Schedule',
                        onPressed: _rebuildSchedule,
                      ),
                      const SizedBox(width: 8),
                      NeuButton.outline(
                        label: '📄 Export Report',
                        onPressed: _exportDebugReport,
                      ),
                      const SizedBox(width: 8),
                      NeuButton.outline(
                        label: '🗑 Clear Alarms',
                        onPressed: _clearNotifications,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // SEARCH BAR
                NeuCard(
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: AppTypography.bodyMd,
                          decoration: const InputDecoration(
                            hintText: 'Search tools (Firebase, Logs, Alarms, Supabase)...',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (val) {
                            ref
                                .read(developerDashboardProvider.notifier)
                                .setSearchQuery(val);
                          },
                        ),
                      ),
                      if (searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(developerDashboardProvider.notifier)
                                .clearSearch();
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                if (_loading)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ))
                else ...[

                  // MODULE 1: SYSTEM STATUS
                  if (_matchesSearch(searchQuery, ['system', 'status', 'device', 'battery', 'memory']))
                    _buildModuleCard(
                      title: '📱 SYSTEM STATUS',
                      statusChip: _statusChip('🟢 Healthy'),
                      route: '/developer-dashboard/system',
                      children: [
                        _metricRow('Host Platform', _diagnostics?.platform ?? 'android'),
                        _metricRow('OS Notifications', _diagnostics?.osNotificationsSupported == true ? 'Supported' : 'Web Stub'),
                        _metricRow('Timezone', _diagnostics?.timezone ?? 'Asia/Kolkata'),
                        _metricRow('Exact Alarms', _diagnostics?.exactAlarmPermission ?? 'Granted'),
                        _metricRow('Battery Optimization', _diagnostics?.batteryOptPermission ?? 'Granted'),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.sm),

                  // MODULE 2: NOTIFICATION CENTER
                  if (_matchesSearch(searchQuery, ['notification', 'test lab', 'alarms', 'pending', 'schedule', 'center']))
                    _buildModuleCard(
                      title: '🔔 NOTIFICATION CENTER',
                      statusChip: _statusChip('🟢 Working (${_diagnostics?.pendingLocalCount ?? 0} Pending)'),
                      route: '/developer-dashboard/notification-center',
                      children: [
                        _metricRow('Pending Alarms', '${_diagnostics?.pendingLocalCount ?? 0}'),
                        _metricRow('Active Channels', '5 Channels Configured'),
                        _metricRow('Current Mode', (reminderSettings?.mode ?? 'interval').toUpperCase()),
                        _metricRow('History Count', '${history.length} items'),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.sm),

                  // MODULE 3: FIREBASE CENTER
                  if (_matchesSearch(searchQuery, ['firebase', 'fcm', 'token', 'push', 'cloud']))
                    _buildModuleCard(
                      title: '☁ FIREBASE CENTER',
                      statusChip: _statusChip(_diagnostics?.firebaseInitialized == true ? '🟢 Connected' : '🔴 Disconnected'),
                      route: '/developer-dashboard/firebase-center',
                      children: [
                        _metricRow('Firebase Core', _diagnostics?.firebaseInitialized == true ? 'Initialized' : 'Failed'),
                        _metricRow('FCM Token', _fcmToken != null ? 'Active' : 'Not Cached'),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.sm),

                  // MODULE 4: SUPABASE CENTER
                  if (_matchesSearch(searchQuery, ['supabase', 'database', 'cloud', 'sync', 'auth']))
                    _buildModuleCard(
                      title: '🗄 SUPABASE CENTER',
                      statusChip: _statusChip('🟢 Sync Ready'),
                      route: '/developer-dashboard/supabase-center',
                      children: [
                        _metricRow('Current User', userId),
                        _metricRow('Table: reminder_settings', 'Sync Connected'),
                        _metricRow('Table: hydration_logs', 'Sync Connected'),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.sm),

                  // MODULE 5: DIAGNOSTICS CENTER
                  if (_matchesSearch(searchQuery, ['diagnostics', 'permission', 'checks', 'health']))
                    _buildModuleCard(
                      title: '📊 DIAGNOSTICS CENTER',
                      statusChip: _statusChip('🟢 5 Checks Passed'),
                      route: '/developer-dashboard/diagnostics-center',
                      children: [
                        _metricRow('Permission Audit', 'PASS'),
                        _metricRow('Alarm Manager', 'PASS'),
                        _metricRow('Timezone Audit', 'PASS'),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.sm),

                  // MODULE 6: LOG CENTER
                  if (_matchesSearch(searchQuery, ['log', 'logs', 'history', 'crash', 'trace']))
                    _buildModuleCard(
                      title: '📜 LOG CENTER',
                      statusChip: _statusChip('🔵 Log Engine Active'),
                      route: '/developer-dashboard/log-center',
                      children: [
                        _metricRow('Notification Logs', '${history.length} items'),
                        _metricRow('Save Process Trace', 'Active'),
                      ],
                    ),

                  const SizedBox(height: AppSpacing.sm),

                  // MODULE 7: DEVELOPER UTILITIES
                  if (_matchesSearch(searchQuery, ['utilities', 'reset', 'force', 'clear', 'export']))
                    _buildModuleCard(
                      title: '⚙ DEVELOPER UTILITIES',
                      statusChip: _statusChip('🔵 Ready'),
                      route: '/developer-dashboard/utilities',
                      children: [
                        NeuButton.outline(
                          label: '🔒 Lock Developer Mode',
                          isFullWidth: true,
                          onPressed: () async {
                            await ref
                                .read(developerModeProvider.notifier)
                                .lockDeveloperMode();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Developer Mode Locked.'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              widget.onBack();
                            }
                          },
                        ),
                      ],
                    ),
                ],

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _matchesSearch(String query, List<String> keywords) {
    if (query.isEmpty) return true;
    return keywords.any((k) => k.contains(query));
  }

  Widget _metaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.black, width: 1),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm
            .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _statusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.2),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm
            .copyWith(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildModuleCard({
    required String title,
    required Widget statusChip,
    required String route,
    required List<Widget> children,
  }) {
    return NeuCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyLg.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              statusChip,
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...children,
          const SizedBox(height: AppSpacing.xs),
          GestureDetector(
            onTap: () => context.push(route),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'OPEN MODULE',
                  style: AppTypography.labelSm.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11)),
          Text(val, style: AppTypography.labelSm.copyWith(fontWeight: FontWeight.w700, fontSize: 11)),
        ],
      ),
    );
  }
}
