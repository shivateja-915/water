import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../firebase/firebase_constants.dart';
import '../../firebase/firebase_service.dart';
import '../../firebase/firebase_token_repository.dart';
import '../../providers/auth_provider.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_card.dart';

class NotificationDebugScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const NotificationDebugScreen({super.key, required this.onBack});

  @override
  ConsumerState<NotificationDebugScreen> createState() =>
      _NotificationDebugScreenState();
}

class _NotificationDebugScreenState
    extends ConsumerState<NotificationDebugScreen> {
  bool _loading = true;
  String? _fcmToken;
  String _permissionStatus = 'Checking...';
  String _initStatus = 'Unknown';
  Map<String, dynamic>? _lastReceived;
  Map<String, dynamic>? _lastTapped;
  String _bgHandlerStatus = 'Active';

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() => _loading = true);

    try {
      // 1. Permission status
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      _permissionStatus = settings.authorizationStatus.name.toUpperCase();

      // 2. FCM Token
      final repo = FirebaseTokenRepository();
      _fcmToken = await repo.getCachedToken();
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        try {
          _fcmToken = await FirebaseMessaging.instance.getToken();
          if (_fcmToken != null) {
            await repo.saveToken(_fcmToken!);
          }
        } catch (e) {
          _fcmToken = 'Error getting token: $e';
        }
      }

      // 3. SharedPreferences logs
      final prefs = await SharedPreferences.getInstance();
      _initStatus = prefs.getString(FirebaseConstants.prefsInitStatus) ??
          (FirebaseService.isInitialized ? 'Initialized' : 'Not initialized');
      _bgHandlerStatus =
          prefs.getString(FirebaseConstants.prefsBgHandlerStatus) ??
              'Registered & Listening';

      final rawReceived = prefs.getString(FirebaseConstants.prefsLastReceived);
      if (rawReceived != null && rawReceived.isNotEmpty) {
        _lastReceived = jsonDecode(rawReceived) as Map<String, dynamic>?;
      }

      final rawTapped = prefs.getString(FirebaseConstants.prefsLastTapped);
      if (rawTapped != null && rawTapped.isNotEmpty) {
        _lastTapped = jsonDecode(rawTapped) as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('Error loading FCM debug info: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshAndSyncToken() async {
    setState(() => _loading = true);
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        final repo = FirebaseTokenRepository();
        await repo.saveToken(token);
        _fcmToken = token;

        final user = ref.read(authRepositoryProvider).currentUser;
        if (user != null) {
          await repo.syncTokenToSupabase(user.id, token);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('FCM Token refreshed and synced to Supabase!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing token: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      await _loadDebugInfo();
    }
  }

  void _copyTokenToClipboard() {
    if (_fcmToken != null && _fcmToken!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('FCM Token copied to clipboard!'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
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
                            'NOTIFICATION DEBUG',
                            style: AppTypography.headlineLg
                                .copyWith(color: AppColors.onSurface),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppColors.primary),
                          onPressed: _loadDebugInfo,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Section 1: System Status
                    Text(
                      'FIREBASE & FCM SYSTEM STATUS',
                      style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    NeuCard(
                      child: Column(
                        children: [
                          _statusRow(
                            'Firebase Initialized',
                            FirebaseService.isInitialized ? 'YES' : 'NO',
                            isSuccess: FirebaseService.isInitialized,
                          ),
                          const Divider(color: AppColors.outlineVariant),
                          _statusRow(
                            'Notification Permission',
                            _permissionStatus,
                            isSuccess: _permissionStatus == 'AUTHORIZED',
                          ),
                          const Divider(color: AppColors.outlineVariant),
                          _statusRow(
                            'Background Handler',
                            _bgHandlerStatus,
                            isSuccess: true,
                          ),
                          const Divider(color: AppColors.outlineVariant),
                          _statusRow(
                            'Init Status Log',
                            _initStatus,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Section 2: FCM Token
                    Text(
                      'CURRENT FCM TOKEN',
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
                            _fcmToken ?? 'No token available',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.onSurface,
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
                                  onPressed: _copyTokenToClipboard,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: NeuButton.outline(
                                  label: '🔄 Sync Token',
                                  onPressed: _refreshAndSyncToken,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Section 3: Last Notification Received
                    Text(
                      'LAST NOTIFICATION RECEIVED',
                      style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    NeuCard(
                      child: _lastReceived == null
                          ? Text(
                              'No FCM notification received yet.',
                              style: AppTypography.bodyMd
                                  .copyWith(color: AppColors.onSurfaceVariant),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _dataRow('Title', _lastReceived!['title'] ?? ''),
                                _dataRow('Body', _lastReceived!['body'] ?? ''),
                                _dataRow('Source', _lastReceived!['source'] ?? ''),
                                _dataRow('Time', _lastReceived!['timestamp'] ?? ''),
                                _dataRow(
                                    'Payload / Data',
                                    jsonEncode(
                                        _lastReceived!['data'] ?? {})),
                              ],
                            ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Section 4: Last Notification Tapped
                    Text(
                      'LAST NOTIFICATION TAP EVENT',
                      style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    NeuCard(
                      child: _lastTapped == null
                          ? Text(
                              'No notification tap event recorded yet.',
                              style: AppTypography.bodyMd
                                  .copyWith(color: AppColors.onSurfaceVariant),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _dataRow('Title', _lastTapped!['title'] ?? ''),
                                _dataRow('Body', _lastTapped!['body'] ?? ''),
                                _dataRow('Source', _lastTapped!['source'] ?? ''),
                                _dataRow('Time', _lastTapped!['timestamp'] ?? ''),
                                _dataRow(
                                    'Payload',
                                    jsonEncode(
                                        _lastTapped!['payload'] ?? {})),
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

  Widget _statusRow(String label, String value, {bool? isSuccess}) {
    Color valColor = AppColors.onSurface;
    if (isSuccess == true) valColor = AppColors.success;
    if (isSuccess == false) valColor = AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.bodyMd
                  .copyWith(color: valColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: AppTypography.labelSm
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurface, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
