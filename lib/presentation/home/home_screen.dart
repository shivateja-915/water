import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/profile_provider.dart';
import '../../providers/hydration_provider.dart';
import '../../providers/drink_type_provider.dart';
import '../../providers/container_preset_provider.dart';
import '../../providers/weather_provider.dart';
import '../../data/models/avatar_options.dart';
import '../../data/models/drink_type.dart';
import '../widgets/hydration_ring.dart';
import '../shared/custom_log_modal.dart';
import '../shared/log_edit_modal.dart';
import '../shared/undo_overlay.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToProfile; const HomeScreen({super.key, this.onNavigateToProfile});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _drinkScrollController = ScrollController();



  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  String _formatMl(int ml) {
    if (ml >= 1000) return '${(ml / 1000).toStringAsFixed(1)}L';
    return '${ml}ml';
  }

  void _quickAdd(int amountMl) {
    final selectedType = ref.read(selectedDrinkTypeProvider);
    if (selectedType == null) return;

    ref.read(todayLogsProvider.notifier).addLog(
          amountMl: amountMl,
          drinkType: selectedType,
        );

    UndoOverlay.show(
      context,
      message: 'ADDED ${_formatMl(amountMl)} ${selectedType.name.toUpperCase()}',
      durationSeconds: 3,
      onUndo: () {
        final logs = ref.read(todayLogsProvider).valueOrNull;
        if (logs != null && logs.isNotEmpty) {
          ref.read(todayLogsProvider.notifier).deleteLog(logs.first.id);
        }
      },
    );
  }

  Color _getCategoryColor(String name) {
    switch (name.toUpperCase()) {
      case 'WATER':
        return const Color(0xFF1976D2);
      case 'COFFEE':
        return const Color(0xFF6D4C41);
      case 'TEA':
        return const Color(0xFF2E7D32);
      case 'JUICE':
        return const Color(0xFFF5C518);
      case 'OTHER':
        return const Color(0xFFD81B60);
      default:
        return const Color(0xFFFFDE00);
    }
  }

  IconData _getIconForName(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'water_drop':
      case 'water':
        return Icons.water_drop;
      case 'coffee':
      case 'coffee_maker':
        return Icons.coffee;
      case 'tea':
      case 'emoji_food_beverage':
        return Icons.emoji_food_beverage;
      case 'juice':
      case 'local_drink':
        return Icons.local_drink;
      case 'other':
        return Icons.local_bar;
      default:
        return Icons.local_cafe;
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  void dispose() {
    _drinkScrollController.dispose();
    UndoOverlay.dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final todayLogs = ref.watch(todayLogsProvider);
    final drinkTypesAsync = ref.watch(drinkTypesProvider);
    final presetsAsync = ref.watch(containerPresetsProvider);
    final weather = ref.watch(weatherProvider);
    final selectedType = ref.watch(selectedDrinkTypeProvider);

    final profileData = profile.valueOrNull;
    final goal = profileData?.dailyGoalMl ?? 2500;
    final todayLogsList = todayLogs.valueOrNull ?? [];
    final todayTotal = todayLogsList.fold<int>(0, (sum, l) => sum + l.amountMl);
    final progress = goal > 0 ? todayTotal / goal : 0.0;

    String getMotivationMessage(double p) {
      if (p >= 1.0) {
        return 'YOU CRUSHED IT! 🎉';
      } else if (p >= 0.75) {
        return 'ALMOST THERE! KEEP GOING! 💪';
      } else if (p >= 0.50) {
        return 'HALFWAY DONE! YOU\'RE DOING GREAT! 🌊';
      } else if (p >= 0.25) {
        return 'GREAT START! KEEP IT UP! 🚀';
      } else {
        return 'LET\'S START HYDRATING! 💧';
      }
    }

    final motivationMessage = getMotivationMessage(progress);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting + Streak Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => widget.onNavigateToProfile?.call(),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: AppColors.black, width: 2.5),
                            boxShadow: const [
                              BoxShadow(color: AppColors.black, offset: Offset(2, 2)),
                            ],
                          ),
                          child: ClipOval(
                            child: (profileData?.toAvatarOptions() ?? AvatarOptions.defaultForUser('user')).buildWidget(size: 44),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_greeting,',
                              style: AppTypography.bodyLg.copyWith(
                                color: const Color(0xFF666666),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              (profileData?.name ?? 'Friend').toUpperCase(),
                              style: AppTypography.headlineMd.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Streak Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDE00),
                      border: Border.all(color: AppColors.black, width: 3),
                      boxShadow: const [
                        BoxShadow(color: AppColors.black, offset: Offset(3, 3))
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          '${profileData?.streakCurrent ?? 0} DAY STREAK',
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.black,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Weather / Location Card - Tappable to navigate to Settings
              weather.when(
                data: (result) {
                  final data = result.data;
                  final isStaleOrDenied = result.isDeviceLocationOff || (data?.isStale ?? true);

                  if (data == null) {
                    return GestureDetector(
                      onTap: () => context.push('/settings'),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.black, width: 3),
                          boxShadow: const [
                            BoxShadow(color: AppColors.black, offset: Offset(3, 3))
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_off_outlined, size: 24, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                result.isDeviceLocationOff
                                    ? 'Location paused. Tap here to enable and fetch fast hydration tips based on your local weather!'
                                    : 'Enable location for weather-based tips',
                                style: AppTypography.bodyMd.copyWith(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 20, color: AppColors.black),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return GestureDetector(
                    onTap: () => context.push('/settings'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isStaleOrDenied ? const Color(0xFFFFF8E1) : Colors.white,
                        border: Border.all(color: AppColors.black, width: 3),
                        boxShadow: const [
                          BoxShadow(color: AppColors.black, offset: Offset(3, 3))
                        ],
                      ),
                      child: Row(
                        children: [
                          Text(data.weatherIcon, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (data.cityName != null && data.cityName!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isStaleOrDenied ? Icons.location_off_outlined : Icons.location_on_outlined, 
                                          size: 14, 
                                          color: isStaleOrDenied ? Colors.orange : const Color(0xFF0047FF)
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          isStaleOrDenied ? '${data.cityName!.toUpperCase()} (NOT SYNCED)' : data.cityName!.toUpperCase(),
                                          style: AppTypography.labelSm.copyWith(
                                            color: isStaleOrDenied ? Colors.orange[800] : const Color(0xFF0047FF),
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Text(
                                  isStaleOrDenied 
                                      ? 'Data not synced. Showing older weather. Tap to turn on location for live tips.' 
                                      : data.hydrationTip,
                                  style: AppTypography.bodyMd.copyWith(
                                    color: AppColors.black,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Humidity: ${data.humidity.round()}%',
                                  style: AppTypography.labelSm.copyWith(color: const Color(0xFF666666)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 20, color: AppColors.black),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.black, width: 3),
                      boxShadow: const [
                        BoxShadow(color: AppColors.black, offset: Offset(3, 3))
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF0047FF)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Fetching location & weather...',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20, color: AppColors.black),
                      ],
                    ),
                  ),
                ),
                error: (_, _) => GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.black, width: 3),
                      boxShadow: const [
                        BoxShadow(color: AppColors.black, offset: Offset(3, 3))
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_off_outlined, size: 20, color: AppColors.black),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Enable location for weather-based tips',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20, color: AppColors.black),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Main Hydration Progress Card
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: progress >= 1.0
                      ? const Color(0xFFD32F2F)
                      : const Color(0xFF0047FF),
                  border: Border.all(color: AppColors.black, width: 3),
                  boxShadow: const [
                    BoxShadow(color: AppColors.black, offset: Offset(5, 5))
                  ],
                ),
                child: Column(
                  children: [
                    Center(
                      child: HydrationRing(
                        progress: progress,
                        currentMl: todayTotal,
                        goalMl: goal,
                        size: 180,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      motivationMessage,
                      style: AppTypography.bodyLg.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Daily Goal bar — Tappable
              GestureDetector(
                onTap: () => widget.onNavigateToProfile?.call(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.black, width: 3),
                    boxShadow: const [
                      BoxShadow(color: AppColors.black, offset: Offset(3, 3))
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_outlined, color: Color(0xFF0047FF), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'DAILY GOAL',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.black,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_formatMl(todayTotal)} / ${_formatMl(goal)}',
                        style: AppTypography.numberSm.copyWith(
                          color: const Color(0xFF0047FF),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_outlined, color: Color(0xFF0047FF), size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),



              // DRINK TYPE Header & Selector Chips
              Text(
                'DRINK TYPE',
                style: AppTypography.headlineMd.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: drinkTypesAsync.when(
                  data: (types) {
                    final defaultTypes = [
                      {'name': 'WATER', 'icon': 'water_drop', 'color': '#1976D2'},
                      {'name': 'COFFEE', 'icon': 'coffee', 'color': '#6D4C41'},
                      {'name': 'TEA', 'icon': 'tea', 'color': '#2E7D32'},
                      {'name': 'JUICE', 'icon': 'juice', 'color': '#F5C518'},
                      {'name': 'OTHER', 'icon': 'other', 'color': '#D81B60'},
                    ];

                    return ListView.builder(
                      controller: _drinkScrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: defaultTypes.length,
                      itemBuilder: (context, index) {
                        final item = defaultTypes[index];
                        final name = item['name']!;
                        final isSelected = (selectedType?.name.toUpperCase() ?? 'WATER') == name;
                        final color = _getCategoryColor(name);
                        final icon = _getIconForName(item['icon']);

                        return GestureDetector(
                          onTap: () {
                            // Find matching drink type object or set selected
                            final match = types.where((t) => t.name.toUpperCase() == name).firstOrNull;
                            if (match != null) {
                              ref.read(selectedDrinkTypeProvider.notifier).state = match;
                            } else {
                              ref.read(selectedDrinkTypeProvider.notifier).state = DrinkType(
                                id: name.toLowerCase(),
                                name: name,
                                icon: item['icon']!,
                                color: item['color']!,
                              );
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFFDE00) : Colors.white,
                              border: Border.all(color: AppColors.black, width: 3),
                            ),
                            child: Row(
                              children: [
                                Icon(icon, size: 18, color: isSelected ? AppColors.black : color),
                                const SizedBox(width: 8),
                                Text(
                                  name,
                                  style: AppTypography.bodyLg.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 6),
              // Neubrutalist Theme Horizontal Scrollbar
              AnimatedBuilder(
                animation: _drinkScrollController,
                builder: (context, _) {
                  double scrollFraction = 0.0;
                  if (_drinkScrollController.hasClients && _drinkScrollController.positions.isNotEmpty) {
                    try {
                      final position = _drinkScrollController.position;
                      if (position.hasContentDimensions && position.maxScrollExtent > 0) {
                        scrollFraction = (position.pixels / position.maxScrollExtent).clamp(0.0, 1.0);
                      }
                    } catch (_) {}
                  }

                  return Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      border: Border.all(color: AppColors.black, width: 1.5),
                    ),
                    alignment: Alignment.centerLeft,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final totalWidth = constraints.maxWidth;
                        final thumbWidth = totalWidth * 0.45;
                        final thumbOffset = scrollFraction * (totalWidth - thumbWidth);

                        return Transform.translate(
                          offset: Offset(thumbOffset, 0),
                          child: Container(
                            width: thumbWidth,
                            height: 4,
                            color: const Color(0xFFFFDE00),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // QUICK ADD Header & Preset Cards
              Text(
                'QUICK ADD',
                style: AppTypography.headlineMd.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 10),

              presetsAsync.when(
                data: (containerPresets) {
                  return Column(
                    children: [
                      // Side by side preset cards matching Image 2
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _quickAdd(250),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFDE00),
                                  border: Border.all(color: AppColors.black, width: 3),
                                  boxShadow: const [
                                    BoxShadow(color: AppColors.black, offset: Offset(4, 4))
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '+250 ML',
                                      style: AppTypography.headlineMd.copyWith(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'GLASS',
                                      style: AppTypography.labelSm.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF555555),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _quickAdd(500),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: AppColors.black, width: 3),
                                  boxShadow: const [
                                    BoxShadow(color: AppColors.black, offset: Offset(4, 4))
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '+500 ML',
                                      style: AppTypography.headlineMd.copyWith(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'BOTTLE',
                                      style: AppTypography.labelSm.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Full Width + CUSTOM LOG Button
                      GestureDetector(
                        onTap: () => CustomLogModal.show(context, ref),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0047FF),
                            border: Border.all(color: AppColors.black, width: 3),
                            boxShadow: const [
                              BoxShadow(color: AppColors.black, offset: Offset(4, 4))
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '+ CUSTOM LOG',
                                style: AppTypography.headlineMd.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 22),

              // TODAY'S TIMELINE Header & List
              todayLogs.when(
                data: (logs) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TODAY\'S TIMELINE',
                            style: AppTypography.headlineMd.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.black,
                            ),
                          ),
                          Text(
                            '${logs.length} logs',
                            style: AppTypography.bodyLg.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (logs.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.black, width: 3),
                            boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(4, 4))],
                          ),
                          child: Column(
                            children: [
                              const Text('🫗', style: TextStyle(fontSize: 40)),
                              const SizedBox(height: 8),
                              Text(
                                'NO LOGS YET TODAY',
                                style: AppTypography.headlineMd.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap a quick-add button above to start tracking!',
                                style: AppTypography.bodyMd.copyWith(
                                  color: const Color(0xFF666666),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      ...logs.map((log) {
                        final drinkName = (log.drinkTypeName ?? 'WATER').toUpperCase();
                        final color = _getCategoryColor(drinkName);
                        final icon = _getIconForName(log.drinkTypeIcon ?? drinkName);
                        final relativeTime = _formatRelativeTime(log.loggedAt.toLocal());
                        final timeString = DateFormat('h:mm a').format(log.loggedAt.toLocal());

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () {
                              LogEditModal.show(context, ref, log);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppColors.black, width: 3),
                                boxShadow: const [
                                  BoxShadow(color: AppColors.black, offset: Offset(4, 4))
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Colored icon box
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: color,
                                      border: Border.all(color: AppColors.black, width: 2),
                                    ),
                                    child: Icon(icon, size: 22, color: Colors.black),
                                  ),
                                  const SizedBox(width: 14),
                                  // Log titles
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$drinkName · ${log.amountMl} ML',
                                          style: AppTypography.bodyLg.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$timeString · $relativeTime',
                                          style: AppTypography.labelSm.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF666666),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Score display
                                  Text(
                                    '+${log.amountMl} ML',
                                    style: AppTypography.headlineMd.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0052D4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.black),
                ),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
