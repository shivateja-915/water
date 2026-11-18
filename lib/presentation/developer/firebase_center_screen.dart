import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../firebase/firebase_notification_handler.dart';
import '../../firebase/firebase_service.dart';
import '../../notifications/notification_constants.dart';
import '../../notifications/notification_history.dart';
import '../../notifications/notification_models.dart';
import '../../notifications/notification_service.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_card.dart';

class FirebaseCenterScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const FirebaseCenterScreen({super.key, required this.onBack});

  @override
  ConsumerState<FirebaseCenterScreen> createState() =>
      _FirebaseCenterScreenState();
}

class _FirebaseCenterScreenState extends ConsumerState<FirebaseCenterScreen> {
  bool _loading = false;
  FirebaseDiagnosticInfo? _info;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _loading = true);
    try {
      _info = await FirebaseService.getDiagnostics();
    } catch (e) {
      debugPrint('Error loading Firebase Center: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forceRefreshToken() async {
    setState(() => _loading = true);
    try {
      await FirebaseService.initializeMessaging();
      _info = await FirebaseService.getDiagnostics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('FCM Token refreshed and synced successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Token refresh error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _copyToken() {
    if (_info?.token != null && _info!.token!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _info!.token!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('FCM Token copied to clipboard!'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _testPushSimulation() async {
    await FirebaseNotificationHandler.logReceivedNotification(
      title: '☁️ Firebase Test Push',
      body: 'Firebase Cloud Messaging integration test completed successfully.',
      data: {'type': 'test', 'source': 'Firebase Center'},
      source: 'Firebase Center Simulation',
    );

    ref.read(notificationHistoryProvider.notifier).addNotification(
          title: '☁️ Firebase Test Push',
          body: 'Firebase Cloud Messaging integration test completed successfully.',
          type: NotificationType.achievement,
          channelId: NotificationConstants.channelGeneralUpdatesId,
        );

    await NotificationService.showNotificationNow(
      id: (DateTime.now().millisecondsSinceEpoch % 90000) + 7000,
      title: '☁️ Firebase Test Push',
      body: 'Firebase Cloud Messaging integration test completed successfully.',
      channelId: NotificationConstants.channelGeneralUpdatesId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firebase Remote Push simulated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
    await _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    final isHealthy = info?.isInitialized == true;

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
                            'FIREBASE CENTER',
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

                    // Live Status Card
                    NeuCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Firebase Health Status',
                                  style: AppTypography.bodyLg.copyWith(
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.w800)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isHealthy ? AppColors.success : AppColors.error)
                                      .withValues(alpha: 0.15),
                                  border: Border.all(
                                      color: isHealthy ? AppColors.success : AppColors.error,
                                      width: 1.5),
                                ),
                                child: Text(
                                  isHealthy ? '🟢 CONNECTED' : '🔴 DISCONNECTED',
                                  style: AppTypography.labelSm.copyWith(
                                      color: isHealthy ? AppColors.success : AppColors.error,
                                      fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _infoRow('Firebase Core App', info?.isInitialized == true ? 'Initialized (${info?.appName})' : 'Not Initialized'),
                          _infoRow('Firebase App Name', info?.appName ?? 'None'),
                          _infoRow('Firebase Project ID', info?.projectId ?? 'None'),
                          _infoRow('FCM Messaging Available', info?.isMessagingAvailable == true ? 'Yes' : 'No'),
                          _infoRow('Token Cache Status', info?.isTokenCached == true ? 'Cached in SharedPreferences' : 'Not Cached'),
                          _infoRow('Last Token Refresh', info?.lastTokenRefresh ?? 'Never'),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Underlying Exception / Recovery Card if disconnected or errored
                    if (info?.lastException != null && info!.lastException!.isNotEmpty) ...[
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
                                  'UNDERLYING EXCEPTION',
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              info.lastException!,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onSurface,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            NeuButton(
                              label: '🔄 Retry Firebase Core Initialization',
                              onPressed: _forceRefreshToken,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // FCM Token Card
                    Text('CURRENT FCM REGISTRATION TOKEN',
                        style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: AppSpacing.xs),
                    NeuCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            info?.token ?? 'Token not cached or unavailable',
                            style: AppTypography.labelSm.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: NeuButton(
                                  label: '📋 Copy Token',
                                  onPressed: _copyToken,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: NeuButton(
                                  label: '🔄 Refresh Token',
                                  onPressed: _forceRefreshToken,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Simulation Actions
                    NeuButton.outline(
                      label: '☁️ Simulate Remote Push Notification',
                      isFullWidth: true,
                      onPressed: _testPushSimulation,
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _infoRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11)),
          Text(val, style: AppTypography.labelSm.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w800, fontSize: 11)),
        ],
      ),
    );
  }
}
