import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/hydration_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/drink_type_provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/avatar_options.dart';
import '../../data/models/hydration_log.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  late final ScrollController _dateScrollController;
  late final ScrollController _filterScrollController;
  double _dateScrollRatio = 1.0;
  double _filterScrollRatio = 0.0;
  String _searchQuery = '';
  String _selectedFilter = 'ALL';

  // Standard filter categories from mockup
  final List<Map<String, String>> _defaultCategories = [
    {'name': 'ALL', 'icon': 'all', 'color': '#FFDE00'},
    {'name': 'WATER', 'icon': 'water_drop', 'color': '#1976D2'},
    {'name': 'COFFEE', 'icon': 'coffee', 'color': '#6D4C41'},
    {'name': 'TEA', 'icon': 'tea', 'color': '#2E7D32'},
    {'name': 'JUICE', 'icon': 'juice', 'color': '#F5C518'},
    {'name': 'OTHER', 'icon': 'other', 'color': '#D81B60'},
  ];

  void _changeDate(int days) {
    final current = ref.read(selectedHistoryDateProvider);
    ref.read(selectedHistoryDateProvider.notifier).state = current.add(Duration(days: days));
  }

  String _formatMlToL(int ml) {
    return '${(ml / 1000).toStringAsFixed(2)} L';
  }

  Color _parseColor(String? hex, {Color fallback = AppColors.primary}) {
    if (hex == null || hex.isEmpty) return fallback;
    String cleanHex = hex.replaceFirst('#', '');
    if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
    return Color(int.tryParse(cleanHex, radix: 16) ?? fallback.toARGB32());
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

  @override
  void initState() {
    super.initState();
    _dateScrollController = ScrollController(initialScrollOffset: 30 * 75.0);
    _dateScrollController.addListener(_onDateScroll);
    _filterScrollController = ScrollController();
    _filterScrollController.addListener(_onFilterScroll);
  }

  void _onDateScroll() {
    if (!_dateScrollController.hasClients) return;
    final max = _dateScrollController.position.maxScrollExtent;
    if (max > 0) {
      final ratio = (_dateScrollController.offset / max).clamp(0.0, 1.0);
      if (ratio != _dateScrollRatio) {
        setState(() => _dateScrollRatio = ratio);
      }
    }
  }

  void _onFilterScroll() {
    if (!_filterScrollController.hasClients) return;
    final max = _filterScrollController.position.maxScrollExtent;
    if (max > 0) {
      final ratio = (_filterScrollController.offset / max).clamp(0.0, 1.0);
      if (ratio != _filterScrollRatio) {
        setState(() => _filterScrollRatio = ratio);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateScrollController.dispose();
    _filterScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    // Past dates strip
    final dates = List.generate(30, (index) => today.subtract(Duration(days: 29 - index)));

    final selectedDate = ref.watch(selectedHistoryDateProvider);
    final logsAsync = ref.watch(dateLogsProvider(selectedDate));
    final profile = ref.watch(profileProvider).valueOrNull;
    final drinkTypesAsync = ref.watch(drinkTypesProvider);
    final goal = profile?.dailyGoalMl ?? 10000;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title Header
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.screenMargin,
                right: AppSpacing.screenMargin,
                top: AppSpacing.md,
                bottom: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: Container(
                      width: 44,
                      height: 44,
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
                        child: (profile?.toAvatarOptions() ?? AvatarOptions.defaultForUser('user')).buildWidget(size: 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'HISTORY',
                    style: AppTypography.headlineLg.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                      letterSpacing: -1.2,
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Date Selector Strip
            SizedBox(
              height: 72,
              child: ListView.separated(
                controller: _dateScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                itemCount: dates.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final date = dates[index];
                  final isSelected = date.isAtSameMomentAs(selectedDate);
                  final isToday = date.isAtSameMomentAs(today);

                  return GestureDetector(
                    onTap: () => ref.read(selectedHistoryDateProvider.notifier).state = DateTime(date.year, date.month, date.day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 66,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFDE00) : Colors.white,
                        border: Border.all(color: AppColors.black, width: 3),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: AppColors.black,
                                  offset: Offset(4, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE').format(date).toUpperCase(),
                            style: AppTypography.labelSm.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.black,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('d').format(date),
                            style: AppTypography.headlineMd.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.black,
                              height: 1.0,
                            ),
                          ),
                          if (isSelected && isToday) ...[
                            const SizedBox(height: 2),
                            Text(
                              'TODAY',
                              style: AppTypography.labelSm.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppColors.black,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            // Custom scrollbar line under date strip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  border: Border.all(color: AppColors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment(-1.0 + 2.0 * _dateScrollRatio, 0.0),
                child: Container(
                  width: 70,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0047FF),
                    border: Border.all(color: AppColors.black, width: 1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Date Navigation Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _changeDate(-1),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.black, width: 3),
                        boxShadow: const [
                          BoxShadow(color: AppColors.black, offset: Offset(3, 3))
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.chevron_left, color: AppColors.black, size: 24),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        DateFormat('EEE, MMM d').format(selectedDate).toUpperCase(),
                        style: AppTypography.headlineMd.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                        ),
                      ),
                      if (selectedDate.isAtSameMomentAs(today))
                        Text(
                          'TODAY',
                          style: AppTypography.labelSm.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF777777),
                            letterSpacing: 1.2,
                          ),
                        ),
                    ],
                  ),
                  GestureDetector(
                    onTap: selectedDate.isBefore(today) ? () => _changeDate(1) : null,
                    child: Opacity(
                      opacity: selectedDate.isBefore(today) ? 1.0 : 0.4,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.black, width: 3),
                          boxShadow: const [
                            BoxShadow(color: AppColors.black, offset: Offset(3, 3))
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.chevron_right, color: AppColors.black, size: 24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Expanded(
              child: logsAsync.when(
                data: (dbLogs) {
                  final logs = dbLogs;
                  final totalHydration = logs.fold<int>(0, (sum, log) => sum + log.hydratedMl);
                  final effectiveGoal = goal > 0 ? goal : 2500;
                  final displayTotalMl = totalHydration;
                  final displayGoalMl = effectiveGoal;
                  final goalCompletion = (displayTotalMl / displayGoalMl * 100).clamp(0, 100).toInt();
                  final remainingMl = (displayGoalMl - displayTotalMl).clamp(0, 999999);

                  // Filtering logic
                  List<HydrationLog> filteredLogs = logs;
                  if (_searchQuery.isNotEmpty) {
                    filteredLogs = filteredLogs.where((l) =>
                        (l.drinkTypeName ?? '').toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                  }
                  if (_selectedFilter != 'ALL') {
                    filteredLogs = filteredLogs.where((l) =>
                        (l.drinkTypeName ?? '').toUpperCase() == _selectedFilter.toUpperCase()).toList();
                  }

                  // Breakdown logic
                  final breakdown = <String, int>{};
                  for (final log in filteredLogs) {
                    final name = (log.drinkTypeName ?? 'UNKNOWN').toUpperCase();
                    breakdown[name] = (breakdown[name] ?? 0) + log.amountMl;
                  }

                  final dbDrinkTypes = drinkTypesAsync.valueOrNull ?? [];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.screenMargin,
                      right: AppSpacing.screenMargin,
                      bottom: AppSpacing.screenMargin * 4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Summary Cards Row
                        Row(
                          children: [
                            // Daily Total Card (Blue)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0047FF),
                                  border: Border.all(color: AppColors.black, width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.black,
                                      offset: Offset(4, 4),
                                    )
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DAILY TOTAL',
                                      style: AppTypography.labelSm.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatMlToL(displayTotalMl),
                                      style: AppTypography.numberMd.copyWith(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'of ${_formatMlToL(displayGoalMl)} goal',
                                      style: AppTypography.labelSm.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Goal Completion Card (White)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: AppColors.black, width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.black,
                                      offset: Offset(4, 4),
                                    )
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GOAL COMPLETION',
                                      style: AppTypography.labelSm.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF555555),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$goalCompletion%',
                                      style: AppTypography.numberMd.copyWith(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.black,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_formatMlToL(remainingMl)} to go',
                                      style: AppTypography.labelSm.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Search and Calendar Bar
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: AppColors.black, width: 3),
                                  boxShadow: const [
                                    BoxShadow(color: AppColors.black, offset: Offset(3, 3))
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (val) => setState(() => _searchQuery = val),
                                  style: AppTypography.bodyLg.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.black,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search logs...',
                                    hintStyle: AppTypography.bodyLg.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF777777),
                                      fontSize: 15,
                                    ),
                                    prefixIcon: const Icon(Icons.search, color: Color(0xFF777777), size: 22),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: today,
                                );
                                if (date != null) {
                                  ref.read(selectedHistoryDateProvider.notifier).state = DateTime(date.year, date.month, date.day);
                                }
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: AppColors.black, width: 3),
                                  boxShadow: const [
                                    BoxShadow(color: AppColors.black, offset: Offset(3, 3))
                                  ],
                                ),
                                child: const Icon(Icons.calendar_today_outlined, color: AppColors.black, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Filter Chips Strip
                        SizedBox(
                          height: 46,
                          child: ListView(
                            controller: _filterScrollController,
                            scrollDirection: Axis.horizontal,
                            children: _defaultCategories.map((cat) {
                              return _buildFilterChip(
                                cat['name']!,
                                cat['icon'],
                                cat['color'],
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Scrollbar indicator for filters
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            border: Border.all(color: AppColors.black, width: 1.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment(-1.0 + 2.0 * _filterScrollRatio, 0.0),
                          child: Container(
                            width: 100,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0047FF),
                              border: Border.all(color: AppColors.black, width: 1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // DRINK BREAKDOWN Container Block
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.black, width: 3),
                            boxShadow: const [
                              BoxShadow(color: AppColors.black, offset: Offset(6, 6))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DRINK BREAKDOWN',
                                style: AppTypography.headlineMd.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...breakdown.entries.map((entry) {
                                final drinkName = entry.key;
                                final drinkVol = entry.value;

                                // Find color and icon
                                final customType = dbDrinkTypes.where((d) => d.name.toUpperCase() == drinkName).firstOrNull;
                                final color = customType != null ? _parseColor(customType.color) : _getCategoryColor(drinkName);
                                final icon = _getIconForName(customType?.icon ?? drinkName);

                                final totalBreakdownVol = breakdown.values.fold<int>(0, (sum, v) => sum + v);
                                final pct = totalBreakdownVol > 0 ? (drinkVol / totalBreakdownVol * 100).round() : 0;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Square colored icon box
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: color,
                                          border: Border.all(color: AppColors.black, width: 2),
                                        ),
                                        child: Icon(icon, size: 18, color: Colors.black),
                                      ),
                                      const SizedBox(width: 12),
                                      // Name, Volume, Percentage & Progress Bar
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  drinkName,
                                                  style: AppTypography.bodyLg.copyWith(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w900,
                                                    color: AppColors.black,
                                                  ),
                                                ),
                                                Text(
                                                  '$drinkVol ML · $pct%',
                                                  style: AppTypography.bodyLg.copyWith(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            // Progress Bar
                                            Container(
                                              height: 12,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.all(color: AppColors.black, width: 2),
                                              ),
                                              alignment: Alignment.centerLeft,
                                              child: FractionallySizedBox(
                                                widthFactor: (pct / 100).clamp(0.0, 1.0),
                                                child: Container(color: color),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 22),
                        
                        // TIMELINE Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TIMELINE',
                              style: AppTypography.headlineMd.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.black,
                              ),
                            ),
                            Text(
                              '${filteredLogs.length} logs',
                              style: AppTypography.bodyLg.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (filteredLogs.isEmpty)
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
                                const Text('🗓️', style: TextStyle(fontSize: 40)),
                                const SizedBox(height: 8),
                                Text(
                                  'NO LOGS FOR THIS DATE',
                                  style: AppTypography.headlineMd.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Log a drink on the home screen to see it here!',
                                  style: AppTypography.bodyMd.copyWith(
                                    color: const Color(0xFF666666),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Timeline Log Cards
                        ...filteredLogs.map((log) {
                          final drinkName = (log.drinkTypeName ?? 'WATER').toUpperCase();
                          final customType = dbDrinkTypes.where((d) => d.id == log.drinkTypeId).firstOrNull;
                          final color = customType != null ? _parseColor(customType.color) : _getCategoryColor(drinkName);
                          final icon = _getIconForName(customType?.icon ?? drinkName);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
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
                                  // Icon Square Box
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
                                  // Log Details Column
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
                                          DateFormat('h:mm a').format(log.loggedAt.toLocal()),
                                          style: AppTypography.labelSm.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF666666),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Amount Value
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
                          );
                        }),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.black)),
                error: (e, _) => Center(
                  child: Text('Error: $e', style: AppTypography.bodyLg.copyWith(color: AppColors.error)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? iconName, String? hexColor) {
    final isSelected = _selectedFilter.toUpperCase() == label.toUpperCase();
    final color = _parseColor(hexColor, fallback: _getCategoryColor(label));
    final icon = _getIconForName(iconName ?? label);

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFDE00) : Colors.white,
          border: Border.all(color: AppColors.black, width: 3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != 'ALL') ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
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
  }
}
