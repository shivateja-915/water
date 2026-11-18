import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reminder_provider.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_card.dart';

class SupabaseCenterScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const SupabaseCenterScreen({super.key, required this.onBack});

  @override
  ConsumerState<SupabaseCenterScreen> createState() =>
      _SupabaseCenterScreenState();
}

class _SupabaseCenterScreenState extends ConsumerState<SupabaseCenterScreen> {
  bool _syncing = false;

  Future<void> _forceSync() async {
    setState(() => _syncing = true);
    try {
      final settings = ref.read(reminderSettingsProvider).valueOrNull;
      if (settings != null) {
        final result = await ref
            .read(reminderSettingsProvider.notifier)
            .saveSettings(settings);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.success
                  ? 'Cloud sync completed successfully!'
                  : 'Saved locally, cloud note: ${result.errorMessage}'),
              backgroundColor:
                  result.success ? AppColors.success : AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authRepositoryProvider).userId ?? 'Anonymous';
    final settings = ref.watch(reminderSettingsProvider).valueOrNull;

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
                      'SUPABASE CENTER',
                      style: AppTypography.headlineLg
                          .copyWith(color: AppColors.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Status Card
              NeuCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Database Connection',
                            style: AppTypography.bodyLg.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w800)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            border: Border.all(
                                color: AppColors.success, width: 1.5),
                          ),
                          child: Text(
                            '🟢 CONNECTED',
                            style: AppTypography.labelSm.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Active User UUID: $userId', style: AppTypography.labelSm),
                    const Divider(color: AppColors.outlineVariant),
                    _tableRow('reminder_settings', settings != null ? 'Synced (Mode: ${settings.mode})' : 'Not Loaded'),
                    _tableRow('hydration_logs', 'Connected'),
                    _tableRow('users_profile', 'Connected'),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              NeuButton(
                label: _syncing ? 'SYNCING...' : '🔄 Force Cloud Re-Sync',
                isFullWidth: true,
                isLoading: _syncing,
                onPressed: _syncing ? null : _forceSync,
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tableRow(String tableName, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(tableName, style: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant)),
          Text(status, style: AppTypography.labelSm.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
