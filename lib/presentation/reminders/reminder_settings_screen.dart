import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'save_success_card.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/developer_mode_provider.dart';
import '../../data/models/reminder_settings.dart';
import '../../data/models/reminder_config.dart';
import '../../notifications/notification_repository.dart';
import '../../notifications/notification_validator.dart';
import '../../notifications/interval_scheduler.dart';
import '../widgets/neu_card.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_chip.dart';
import '../widgets/neu_modal.dart';

class ReminderSettingsScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const ReminderSettingsScreen({super.key, required this.onBack});

  @override
  ConsumerState<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState
    extends ConsumerState<ReminderSettingsScreen> {
  bool _enabled = true;
  String _mode = 'both';
  int _intervalMinutes = 60;
  final List<int> _intervalOptions = [30, 60, 120, 180, 240, 300, 360];
  String _dndStart = '23:00';
  String _dndEnd = '07:00';
  int _snoozeDuration = 5;
  List<String> _fixedTimes = [];
  List<String> _deletedTimes = [];
  bool _initialized = false;
  bool _isSaving = false;

  void _initFromSettings() {
    final settings = ref.read(reminderSettingsProvider).valueOrNull;
    if (settings != null && !_initialized) {
      setState(() {
        _enabled = settings.enabled;
        _mode = 'both'; // Force 'both' to always show interval + fixed
        _intervalMinutes = settings.computedIntervalMinutes;
        if (!_intervalOptions.contains(_intervalMinutes)) {
           _intervalOptions.add(_intervalMinutes);
           _intervalOptions.sort();
        }
        _dndStart = settings.dndStart;
        _dndEnd = settings.dndEnd;
        _snoozeDuration = settings.snoozeDefaultMinutes;
        _fixedTimes = List<String>.from(settings.fixedTimes);
        _deletedTimes = List<String>.from(settings.deletedTimes);
        _initialized = true;
      });
    }
  }

  /// Builds a [ReminderConfig] from the current UI state for live preview.
  ReminderConfig _currentConfig() {
    return ReminderConfig.fromSettings(
      enabled: _enabled,
      mode: _mode,
      intervalMinutes: _intervalMinutes,
      fixedTimes: _fixedTimes,
      dndStart: _dndStart,
      dndEnd: _dndEnd,
      snoozeDefaultMinutes: _snoozeDuration,
      deletedTimes: _deletedTimes,
    );
  }

  /// Returns the live-computed schedule as a list of [TimeOfDay].
  List<TimeOfDay> _computePreview() {
    return NotificationRepository.computeTimes(_currentConfig());
  }

  /// Formats a [TimeOfDay] to 12-hour string (e.g. "7:00 AM").
  String _formatTime12h(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _formatTime24h(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final existingSettings = ref.read(reminderSettingsProvider).valueOrNull;
      final userId = ref.read(authRepositoryProvider).userId;
      final activeUserId = userId ?? 'guest';

      final activeDeletedTimes = _mode == 'fixed' ? <String>[] : _deletedTimes;
      late ReminderSettings settingsToSave;

      if (existingSettings != null) {
        settingsToSave = existingSettings.copyWith(
          enabled: _enabled,
          mode: _mode,
          intervalHours: _intervalMinutes >= 60 ? _intervalMinutes ~/ 60 : 1,
          weekendOverrides: {
             ...existingSettings.weekendOverrides,
             'interval_minutes': _intervalMinutes,
          },
          dndStart: _dndStart,
          dndEnd: _dndEnd,
          snoozeDefaultMinutes: _snoozeDuration,
          fixedTimes: _fixedTimes,
          deletedTimes: activeDeletedTimes,
        );
      } else {
        settingsToSave = ReminderSettings(
          id: activeUserId,
          userId: activeUserId,
          enabled: _enabled,
          mode: _mode,
          intervalHours: _intervalMinutes >= 60 ? _intervalMinutes ~/ 60 : 1,
          weekendOverrides: {'interval_minutes': _intervalMinutes},
          fixedTimes: _fixedTimes,
          dndStart: _dndStart,
          dndEnd: _dndEnd,
          snoozeDefaultMinutes: _snoozeDuration,
          deletedTimes: activeDeletedTimes,
        );
      }

      final result = await ref
          .read(reminderSettingsProvider.notifier)
          .saveSettings(settingsToSave);

      if (mounted) {
        NeuModal.show(
          context,
          title: 'Pipeline Verification',
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: SaveSuccessCard(result: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showDuplicateAlert(String timeStr) {
    NeuModal.show(
      context,
      title: 'Duplicate Reminder',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'The reminder time $timeStr is already scheduled in your active reminders.',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: AppSpacing.md),
          NeuButton(
            label: 'OK',
            isFullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // INTERVAL CHIP DELETION & SCHEDULE PREVIEW
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildIntervalRemindersList() {
    final activeTimes = _computePreview();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACTIVE REMINDER TIMES',
              style: AppTypography.labelSm
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
            Text(
              '${activeTimes.length} / day',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (activeTimes.isEmpty)
          Text(
            'No reminders generated with these DND hours & interval.',
            style: AppTypography.labelSm
                .copyWith(color: AppColors.onSurfaceVariant),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activeTimes.map((t) {
              final time24 = _formatTime24h(t);
              return Container(
                padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  border: Border.all(
                      color: AppColors.black, width: AppSpacing.borderWidth),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.black,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime12h(t),
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _deletedTimes = [..._deletedTimes, time24];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
                          border: Border.all(color: AppColors.black, width: 1.5),
                        ),
                        child: const Icon(Icons.close, size: 12, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        if (_deletedTimes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () {
              setState(() {
                _deletedTimes.clear();
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.restore, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  'Restore ${_deletedTimes.length} deleted reminder(s)',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // DIAGNOSTICS PANEL
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildDiagnosticsPanel() {
    final devState = ref.watch(developerModeProvider);

    if (!devState.isUnlocked) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: () => context.push('/developer-mode'),
          child: NeuCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.developer_mode,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'DEVELOPER MODE & DIAGNOSTICS 🛠️',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(reminderSettingsProvider);

    settingsAsync.whenData((_) => _initFromSettings());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: settingsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(child: Text('Error loading settings: $e')),
          data: (_) => SingleChildScrollView(
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
                                offset: Offset(3, 3)),
                          ],
                          color: AppColors.surfaceContainerLowest,
                        ),
                        child: const Icon(Icons.arrow_back, size: 20),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'REMINDERS',
                      style: AppTypography.headlineLg
                          .copyWith(color: AppColors.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Master toggle
                NeuCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REMINDERS',
                            style: AppTypography.bodyLg.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _enabled ? 'ON' : 'OFF',
                            style: AppTypography.labelSm.copyWith(
                                color: _enabled
                                    ? AppColors.success
                                    : AppColors.error),
                          ),
                        ],
                      ),
                      Switch(
                        value: _enabled,
                        onChanged: (v) => setState(() => _enabled = v),
                        activeTrackColor: AppColors.primary,
                        activeThumbColor: AppColors.white,
                      ),
                    ],
                  ),
                ),

                if (_enabled) ...[
                  const SizedBox(height: AppSpacing.sm),

                  // Mode selector removed - Both modes are always available

                  const SizedBox(height: AppSpacing.sm),

                  Text('INTERVAL REMINDERS',
                      style: AppTypography.labelSm
                          .copyWith(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.xs),
                    NeuCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              final currentIndex = _intervalOptions.indexOf(_intervalMinutes);
                              if (currentIndex > 0) {
                                setState(() {
                                  _intervalMinutes = _intervalOptions[currentIndex - 1];
                                  // Changing interval clears deleted times so new schedule is clean
                                  _deletedTimes.clear();
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.black, width: 2),
                              ),
                              child: const Icon(Icons.remove, size: 20),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg),
                            child: Text(
                              _intervalMinutes < 60
                                  ? 'EVERY $_intervalMinutes MIN'
                                  : 'EVERY ${_intervalMinutes ~/ 60} ${(_intervalMinutes ~/ 60) == 1 ? 'HOUR' : 'HOURS'}',
                              style: AppTypography.numberSm
                                  .copyWith(color: AppColors.primary),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              final currentIndex = _intervalOptions.indexOf(_intervalMinutes);
                              if (currentIndex != -1 && currentIndex < _intervalOptions.length - 1) {
                                setState(() {
                                  _intervalMinutes = _intervalOptions[currentIndex + 1];
                                  _deletedTimes.clear();
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.black, width: 2),
                              ),
                              child: const Icon(Icons.add, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Deletable interval chips & preview
                    _buildIntervalRemindersList(),

                    const SizedBox(height: AppSpacing.md),

                    Text('FIXED REMINDER TIMES',
                        style: AppTypography.labelSm
                            .copyWith(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: AppSpacing.xs),
                    if (_fixedTimes.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          'No fixed times added yet. Add one below.',
                          style: AppTypography.labelSm
                              .copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      )
                    else
                      ..._fixedTimes.asMap().entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: NeuCard(
                            shadowOffset: 2,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  e.value,
                                  style: AppTypography.numberSm
                                      .copyWith(color: AppColors.onSurface),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _fixedTimes.removeAt(e.key);
                                    });
                                  },
                                  child: const Icon(Icons.delete_outline,
                                      color: AppColors.error, size: 20),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    NeuButton.outline(
                      label: '+ Add Time',
                      isFullWidth: true,
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          final timeStr = _formatTime24h(time);

                          // Check duplicates in existing fixed times
                          if (NotificationValidator.isDuplicateTimeString(
                              timeStr, _fixedTimes)) {
                            _showDuplicateAlert(timeStr);
                            return;
                          }

                          // Also check if time falls inside interval generated schedule
                          final intervalTimes = IntervalScheduler.generate(
                            wakeTime: _dndEnd,
                            sleepTime: _dndStart,
                            intervalMinutes: _intervalMinutes,
                          );
                          final dup = NotificationValidator.findDuplicate(
                              time, intervalTimes);
                          if (dup != null) {
                            _showDuplicateAlert(timeStr);
                            return;
                          }

                          setState(() {
                            _fixedTimes.add(timeStr);
                            _fixedTimes.sort();
                          });
                        }
                      },
                    ),


                  const SizedBox(height: AppSpacing.sm),

                  // DND window
                  Text('QUIET HOURS (DO NOT DISTURB)',
                      style: AppTypography.labelSm
                          .copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.xs),
                  NeuCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final parts = _dndStart.split(':');
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                    hour: int.parse(parts[0]),
                                    minute: int.parse(parts[1])),
                              );
                              if (time != null) {
                                setState(() {
                                  _dndStart = _formatTime24h(time);
                                  _deletedTimes.clear();
                                });
                              }
                            },
                            child: Column(
                              children: [
                                Text('START',
                                    style: AppTypography.labelSm.copyWith(
                                        color: AppColors.onSurfaceVariant)),
                                Text(_dndStart,
                                    style: AppTypography.numberSm
                                        .copyWith(color: AppColors.onSurface)),
                              ],
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward,
                            color: AppColors.outline),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final parts = _dndEnd.split(':');
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                    hour: int.parse(parts[0]),
                                    minute: int.parse(parts[1])),
                              );
                              if (time != null) {
                                setState(() {
                                  _dndEnd = _formatTime24h(time);
                                  _deletedTimes.clear();
                                });
                              }
                            },
                            child: Column(
                              children: [
                                Text('END',
                                    style: AppTypography.labelSm.copyWith(
                                        color: AppColors.onSurfaceVariant)),
                                Text(_dndEnd,
                                    style: AppTypography.numberSm
                                        .copyWith(color: AppColors.onSurface)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Snooze Default
                  Text('DEFAULT SNOOZE TIME',
                      style: AppTypography.labelSm
                          .copyWith(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [2, 5, 10].map((mins) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: NeuChip(
                            label: '${mins}m',
                            isSelected: _snoozeDuration == mins,
                            onTap: () => setState(() => _snoozeDuration = mins),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Diagnostics panel (visible on all platforms)
                  _buildDiagnosticsPanel(),
                ],

                const SizedBox(height: AppSpacing.lg),

                // Save button
                NeuButton(
                  label: _isSaving ? 'SAVING...' : 'SAVE & APPLY SETTINGS',
                  isFullWidth: true,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _save,
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
