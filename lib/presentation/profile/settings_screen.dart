import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../widgets/neu_card.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_modal.dart';

import '../../providers/app_settings_provider.dart';
import '../../providers/developer_mode_provider.dart';

import 'package:geolocator/geolocator.dart';
import '../../providers/weather_provider.dart';
import '../../notifications/notification_history.dart';

class SettingsScreen extends ConsumerWidget {
  final VoidCallback onBack;
  final VoidCallback onReminderSettings;

  const SettingsScreen({
    super.key,
    required this.onBack,
    required this.onReminderSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(appSettingsProvider);
    final hasUnreadNotifs = ref.watch(notificationHistoryProvider).any((item) => !item.isRead);

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
                    onTap: onBack,
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
                  Text(
                    'SETTINGS',
                    style: AppTypography.headlineLg
                        .copyWith(color: AppColors.onSurface),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              if (ref.watch(developerModeProvider).isUnlocked) ...[
                NeuCard(
                  child: Row(
                    children: [
                      const Icon(Icons.developer_mode, color: AppColors.primary, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DEVELOPER DASHBOARD ACTIVE',
                              style: AppTypography.bodyLg.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Tap to open Mission Control Diagnostic Hub',
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      NeuButton(
                        label: 'OPEN',
                        onPressed: () => context.push('/developer-dashboard'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // App Settings section
              Text(
                'APP SETTINGS',
                style: AppTypography.labelSm
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xs),
              NeuCard(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        final profile = ref.read(profileProvider).valueOrNull;
                        if (profile == null) return;
                        final newUnit = profile.unitPreference == 'metric'
                            ? 'imperial'
                            : 'metric';
                        ref.read(profileProvider.notifier).updateProfile(
                              profile.copyWith(unitPreference: newUnit),
                            );
                      },
                      child: _settingsRow(
                        icon: Icons.straighten_outlined,
                        label: 'UNITS',
                        trailing: Text(
                          ref.watch(profileProvider).valueOrNull?.unitPreference == 'imperial'
                              ? 'OZ / CUPS'
                              : 'ML / LITRES',
                          style: AppTypography.bodyMd.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const Divider(color: AppColors.outlineVariant),
                    _settingsRow(
                      icon: Icons.palette_outlined,
                      label: 'THEME',
                      trailing: Text(
                        'LIGHT',
                        style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant),
                      ),
                    ),
                    const Divider(color: AppColors.outlineVariant),
                    _settingsRow(
                      icon: Icons.notifications_active_outlined,
                      label: 'NOTIFICATIONS',
                      trailing: _neuToggle(
                        appSettings.notificationsEnabled,
                        (val) => ref
                            .read(appSettingsProvider.notifier)
                            .setNotificationsEnabled(val),
                      ),
                    ),
                    const Divider(color: AppColors.outlineVariant),
                    _settingsRow(
                      icon: Icons.location_on_outlined,
                      label: 'LOCATION',
                      trailing: _neuToggle(
                        appSettings.locationEnabled,
                        (val) async {
                          if (val) {
                            LocationPermission permission = await Geolocator.checkPermission();
                            if (permission == LocationPermission.denied) {
                              permission = await Geolocator.requestPermission();
                            }
                            if (permission == LocationPermission.deniedForever) {
                              if (kIsWeb) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable location in your browser settings.')));
                              } else {
                                await Geolocator.openAppSettings();
                              }
                              return;
                            }
                            bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                            if (!serviceEnabled) {
                              if (kIsWeb) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable location in your browser settings.')));
                              } else {
                                await Geolocator.openLocationSettings();
                              }
                            } else {
                              await ref.read(appSettingsProvider.notifier).syncLocationState();
                              ref.read(weatherProvider.notifier).loadWeather();
                            }
                          } else {
                            if (kIsWeb) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please disable location in your browser settings.')));
                            } else {
                              await Geolocator.openLocationSettings();
                            }
                          }
                        },
                      ),
                    ),
                    const Divider(color: AppColors.outlineVariant),
                    GestureDetector(
                      onTap: onReminderSettings,
                      child: _settingsRow(
                        icon: Icons.notifications_outlined,
                        label: 'REMINDER SCHEDULE SETTINGS',
                        trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.outline),
                      ),
                    ),

                    const Divider(color: AppColors.outlineVariant),
                    GestureDetector(
                      onTap: () => context.push('/notification-history'),
                      child: _settingsRow(
                        icon: Icons.history_outlined,
                        label: 'NOTIFICATION HISTORY',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasUnreadNotifs) ...[
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            const Icon(
                                Icons.chevron_right,
                                color: AppColors.outline),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),



              // Account section
              Text(
                'ACCOUNT',
                style: AppTypography.labelSm
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xs),
              NeuCard(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await ref
                            .read(authNotifierProvider.notifier)
                            .signOut();
                      },
                      child: _settingsRow(
                        icon: Icons.logout_outlined,
                        label: 'LOG OUT',
                        trailing: const Icon(Icons.chevron_right,
                            color: AppColors.outline),
                      ),
                    ),
                    const Divider(color: AppColors.outlineVariant),
                    GestureDetector(
                      onTap: () {
                        final deleteController = TextEditingController();
                        NeuModal.show(
                          context,
                          title: 'Delete Account',
                          child: StatefulBuilder(
                            builder: (context, setModalState) {
                              return Column(
                                children: [
                                  Text(
                                    'Are you sure you want to delete your account and all data? This action cannot be undone.',
                                    style: AppTypography.bodyMd.copyWith(
                                        color: AppColors.onSurface),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Type "delete" to confirm:',
                                    style: AppTypography.labelSm.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  TextField(
                                    controller: deleteController,
                                    onChanged: (_) => setModalState(() {}),
                                    decoration: InputDecoration(
                                      hintText: 'Type "delete" here',
                                      hintStyle: AppTypography.bodyMd.copyWith(
                                          color: AppColors.onSurfaceVariant),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: AppColors.black, width: 2),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: AppColors.black, width: 2),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: AppColors.error, width: 2),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                    ),
                                    style: AppTypography.bodyMd
                                        .copyWith(color: AppColors.onSurface),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: NeuButton.outline(
                                          label: 'Cancel',
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Expanded(
                                        child: NeuButton.error(
                                          label: 'DELETE',
                                          onPressed: deleteController.text
                                                      .trim()
                                                      .toLowerCase() ==
                                                  'delete'
                                              ? () async {
                                                  Navigator.of(context).pop();
                                                  await ref
                                                      .read(
                                                          authNotifierProvider
                                                              .notifier)
                                                      .deleteAccount();
                                                  if (context.mounted) {
                                                    context.go('/signup');
                                                  }
                                                }
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      },
                      child: _settingsRow(
                        icon: Icons.delete_outline,
                        label: 'DELETE ACCOUNT',
                        trailing: const Icon(Icons.chevron_right,
                            color: AppColors.error),
                        textColor: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // About
              Text(
                'ABOUT',
                style: AppTypography.labelSm
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xs),
              NeuCard(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final msg = await ref
                            .read(developerModeProvider.notifier)
                            .registerTap();
                        if (msg != null && context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              backgroundColor: AppColors.primary,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: _settingsRow(
                        icon: Icons.info_outline,
                        label: 'APP VERSION',
                        trailing: Text(
                          'V1.0.0',
                          style: AppTypography.bodyMd
                              .copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    ),
                    if (ref.watch(developerModeProvider).isUnlocked) ...[
                      const Divider(color: AppColors.outlineVariant),
                      GestureDetector(
                        onTap: () => context.push('/developer-dashboard'),
                        child: _settingsRow(
                          icon: Icons.developer_mode,
                          label: 'DEVELOPER DASHBOARD 🛠️',
                          textColor: AppColors.primary,
                          trailing: const Icon(Icons.chevron_right,
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                    const Divider(color: AppColors.outlineVariant),
                    GestureDetector(
                      onTap: () => context.push('/about'),
                      child: _settingsRow(
                        icon: Icons.info_outline,
                        label: 'ABOUT SIPLY',
                        trailing: const Icon(Icons.chevron_right,
                            color: AppColors.outline),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required String label,
    required Widget trailing,
    Color textColor = AppColors.onSurface,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMd.copyWith(
                  color: textColor, fontWeight: FontWeight.w600),
            ),
          ),
          trailing,
        ],
      ),
    );
  }


  Widget _neuToggle(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 28,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF0047FF) : const Color(0xFFE0E0E0),
          border: Border.all(color: AppColors.black, width: 2.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 19,
            height: 19,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? const Color(0xFFFFDE00) : AppColors.black,
              border: Border.all(color: AppColors.black, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
