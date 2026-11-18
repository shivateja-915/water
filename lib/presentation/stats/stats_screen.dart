import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/stats_provider.dart';
import '../../providers/hydration_provider.dart';
import 'widgets/sparkline_widget.dart';
import 'widgets/calendar_heatmap.dart';
import 'widgets/stats_popover.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerAnimation() {
    _animController.reset();
    _animController.forward();
  }

  String _formatMl(int ml) {
    if (ml >= 1000) return '${(ml / 1000).toStringAsFixed(1)}L';
    return '${ml}ml';
  }

  Color _parseColor(String hex, {Color fallback = AppColors.primary}) {
    String cleanHex = hex.replaceFirst('#', '');
    if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
    return Color(int.tryParse(cleanHex, radix: 16) ?? fallback.toARGB32());
  }

  Future<void> _pickAnchorDate() async {
    final timeState = ref.read(statsTimeRangeProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: timeState.anchorDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0047FF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(statsTimeRangeProvider.notifier).setAnchorDate(picked);
      _triggerAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeState = ref.watch(statsTimeRangeProvider);
    final range = timeState.range;
    final overview = ref.watch(statsOverviewProvider);
    final intakeBuckets = ref.watch(statsIntakeBucketsProvider);
    final goalTrend = ref.watch(statsGoalTrendProvider);
    final drinkBreakdown = ref.watch(statsDrinkBreakdownProvider);
    final hourlyPattern = ref.watch(statsHourlyPatternProvider);
    final heatmapCells = ref.watch(statsHeatmapProvider);
    final records = ref.watch(statsRecordsProvider);
    final comparison = ref.watch(statsComparisonProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'STATISTICS',
                        style: AppTypography.headlineLg.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.black,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _pickAnchorDate,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.black, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: AppColors.black, offset: Offset(2, 2)),
                        ],
                      ),
                      child: const Icon(Icons.calendar_month, size: 22, color: AppColors.black),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 2. Time Range Selector
              _buildTimeRangeSelector(range),

              const SizedBox(height: 18),

              // 3. Overview Cards (2x2 Grid)
              _buildOverviewGrid(overview, range),

              const SizedBox(height: 18),

              // 4. Intake Chart (Hidden on Today)
              if (range != TimeRange.today) ...[
                _buildIntakeChartCard(intakeBuckets, range),
                const SizedBox(height: 18),
              ],

              // 5. Goal Completion Trend (Hidden on Today)
              if (range != TimeRange.today) ...[
                _buildGoalTrendCard(goalTrend),
                const SizedBox(height: 18),
              ],

              // 6. Drink Type Breakdown
              _buildDrinkBreakdownCard(drinkBreakdown),

              const SizedBox(height: 18),

              // 7. Drinking Time Pattern
              _buildHourlyPatternCard(hourlyPattern),

              const SizedBox(height: 18),

              // 8. Heat Map (Hidden on Today and Lifetime)
              if (range != TimeRange.today && range != TimeRange.lifetime) ...[
                _buildHeatmapCard(heatmapCells, range),
                const SizedBox(height: 18),
              ],

              // 9. Best Day / Lowest Day Cards (Hidden on Today)
              if (range != TimeRange.today) ...[
                _buildBestLowestDayCards(records),
                const SizedBox(height: 18),
              ],

              // 10. Longest Streak
              _buildLongestStreakCard(records.longestStreakDays),

              const SizedBox(height: 18),

              // 11. Personal Records
              _buildPersonalRecordsCard(records),

              const SizedBox(height: 18),

              // 12. Period Comparison (Hidden on Today & Lifetime)
              if (range != TimeRange.today && range != TimeRange.lifetime) ...[
                _buildComparisonCard(comparison),
                const SizedBox(height: 18),
              ],

              // 13. AI Insights
              _buildAiInsightsCard(hourlyPattern, drinkBreakdown, overview),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Segmented Time Range Selector with horizontal drag & edge fade mask
  Widget _buildTimeRangeSelector(TimeRange activeRange) {
    const tabs = [
      {'label': 'TODAY', 'range': TimeRange.today},
      {'label': 'WEEK', 'range': TimeRange.week},
      {'label': 'MONTH', 'range': TimeRange.month},
      {'label': 'YEAR', 'range': TimeRange.year},
      {'label': 'LIFETIME', 'range': TimeRange.lifetime},
    ];

    return SizedBox(
      height: 44,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.black, Colors.black, Colors.transparent],
            stops: [0.0, 0.88, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final tab = tabs[i];
            final r = tab['range'] as TimeRange;
            final isSelected = activeRange == r;

            return GestureDetector(
              onTap: () {
                ref.read(statsTimeRangeProvider.notifier).setRange(r);
                _triggerAnimation();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFDE00) : Colors.white,
                  border: Border.all(color: AppColors.black, width: 2.5),
                  boxShadow: isSelected
                      ? const [BoxShadow(color: AppColors.black, offset: Offset(3, 3))]
                      : null,
                ),
                child: Text(
                  tab['label'] as String,
                  style: AppTypography.labelSm.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // 3. Overview Cards (2x2 Grid)
  Widget _buildOverviewGrid(StatsOverview overview, TimeRange range) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _overviewCard(
                title: 'AVERAGE INTAKE',
                value: _formatMl(overview.avgIntakeMl),
                sparklineValues: overview.avgIntakeSparkline,
                color: const Color(0xFF0047FF),
                onTap: () => StatsPopover.show(
                  context,
                  title: 'Average Intake',
                  subtitle: 'Daily average for selected period',
                  primaryValue: _formatMl(overview.avgIntakeMl),
                  detailText: overview.avgIntakeComparison,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _overviewCard(
                title: 'GOAL COMPLETION',
                value: '${overview.goalCompletionPct}%',
                sparklineValues: overview.goalCompletionSparkline,
                color: const Color(0xFF2E7D32),
                onTap: () => StatsPopover.show(
                  context,
                  title: 'Goal Completion',
                  subtitle: 'Percentage of days meeting daily goal',
                  primaryValue: '${overview.goalCompletionPct}%',
                  detailText: overview.goalCompletionComparison,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _overviewCard(
                title: 'CURRENT STREAK',
                value: '${overview.currentStreakDays} Days 🔥',
                sparklineValues: const [1, 1, 1, 1, 1, 1, 1],
                color: const Color(0xFFFFDE00),
                onTap: () => StatsPopover.show(
                  context,
                  title: 'Current Streak',
                  subtitle: 'Consecutive days meeting daily goal',
                  primaryValue: '${overview.currentStreakDays} Days',
                  detailText: 'Keep logging daily to build your streak!',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _overviewCard(
                title: 'LIFETIME TOTAL',
                value: _formatMl(overview.lifetimeTotalMl),
                sparklineValues: overview.avgIntakeSparkline,
                color: const Color(0xFFD81B60),
                onTap: () => StatsPopover.show(
                  context,
                  title: 'Lifetime Water Total',
                  subtitle: 'All-time total water logged since account creation',
                  primaryValue: _formatMl(overview.lifetimeTotalMl),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _overviewCard({
    required String title,
    required String value,
    required List<double> sparklineValues,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.black, width: 3),
          boxShadow: const [
            BoxShadow(color: AppColors.black, offset: Offset(3.5, 3.5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.labelSm.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Text(
                  value,
                  style: AppTypography.headlineLg.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            SparklineWidget(values: sparklineValues, color: color, height: 18),
          ],
        ),
      ),
    );
  }

  // 4. Intake Chart (Zero-filled buckets with Met/Missed legend)
  Widget _buildIntakeChartCard(List<IntakeBucket> buckets, TimeRange range) {
    final title = (range == TimeRange.year || range == TimeRange.lifetime)
        ? 'MONTHLY INTAKE'
        : 'DAILY INTAKE';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.black, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.headlineMd.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              // Legend
              Row(
                children: [
                  _legendDot(const Color(0xFF0047FF), 'Met'),
                  const SizedBox(width: 8),
                  _legendDot(const Color(0xFF99BBFF), 'Missed'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: buckets.length > 12 ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: buckets.length > 12 ? buckets.length * 36.0 : MediaQuery.of(context).size.width - 70,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (buckets.map((b) => b.consumedMl).fold(0, (max, v) => v > max ? v : max) * 1.2).clamp(2000, 200000).toDouble(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchCallback: (FlTouchEvent event, barTouchResponse) {
                        if (event is FlTapUpEvent && barTouchResponse?.spot != null) {
                          final idx = barTouchResponse!.spot!.touchedBarGroupIndex;
                          if (idx >= 0 && idx < buckets.length) {
                            final b = buckets[idx];
                            StatsPopover.show(
                              context,
                              title: 'Intake Detail',
                              subtitle: DateFormat('EEEE, MMM d, yyyy').format(b.date),
                              primaryValue: _formatMl(b.consumedMl),
                              secondaryValue: '${(b.completionPercentage * 100).round()}% of goal',
                              actionLabel: 'VIEW DAY IN HISTORY →',
                              onAction: () {
                                ref.read(selectedHistoryDateProvider.notifier).state = DateTime(b.date.year, b.date.month, b.date.day);
                                context.go('/history');
                              },
                            );
                          }
                        }
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (idx >= 0 && idx < buckets.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  buckets[idx].label,
                                  style: AppTypography.labelSm.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: buckets.asMap().entries.map((e) {
                      final i = e.key;
                      final b = e.value;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: b.consumedMl.toDouble().clamp(b.consumedMl > 0 ? 50.0 : 4.0, 200000.0),
                            color: b.isMet ? const Color(0xFF0047FF) : const Color(0xFF99BBFF),
                            width: buckets.length > 12 ? 14 : 18,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelSm.copyWith(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // 5. Goal Completion Trend Card
  Widget _buildGoalTrendCard(GoalTrendData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.black, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GOAL COMPLETION TREND',
            style: AppTypography.headlineMd.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                maxY: 100,
                minY: 0,
                lineTouchData: LineTouchData(
                  touchCallback: (FlTouchEvent event, touchResponse) {
                    if (event is FlTapUpEvent && touchResponse?.lineBarSpots != null) {
                      final spot = touchResponse!.lineBarSpots!.first;
                      final idx = spot.x.toInt();
                      if (idx >= 0 && idx < data.labels.length) {
                        StatsPopover.show(
                          context,
                          title: 'Goal Trend',
                          subtitle: data.labels[idx],
                          primaryValue: '${spot.y.round()}% Goal Met',
                        );
                      }
                    }
                  },
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: const Color(0xFFE0E0E0),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data.completionPcts.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value);
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF0047FF),
                    barWidth: 3.5,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          _computedInsightLine(data.insightLine),
        ],
      ),
    );
  }

  // 6. Drink Type Breakdown Card (Donut chart with matching drink colors)
  Widget _buildDrinkBreakdownCard(DrinkBreakdownData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.black, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DRINK TYPE BREAKDOWN',
            style: AppTypography.headlineMd.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 14),

          if (data.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No drink data recorded for this period.')),
            )
          else
            Row(
              children: [
                // Donut Pie Chart
                SizedBox(
                  width: 120,
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: data.items.map((item) {
                        return PieChartSectionData(
                          color: _parseColor(item.colorHex),
                          value: item.percentage,
                          title: '${item.percentage.round()}%',
                          radius: 30,
                          titleStyle: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Legend list
                Expanded(
                  child: Column(
                    children: data.items.map((item) {
                      final color = _parseColor(item.colorHex);
                      return GestureDetector(
                        onTap: () => StatsPopover.show(
                          context,
                          title: item.name,
                          subtitle: 'Period intake breakdown',
                          primaryValue: _formatMl(item.amountMl),
                          secondaryValue: '${item.percentage.toStringAsFixed(1)}%',
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  border: Border.all(color: AppColors.black, width: 1.5),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: AppTypography.labelSm.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                '${item.percentage.round()}%',
                                style: AppTypography.numberSm.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          _computedInsightLine(data.insightLine),
        ],
      ),
    );
  }

  // 7. Drinking Time Pattern Card
  Widget _buildHourlyPatternCard(HourlyPatternData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.black, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DRINKING TIME PATTERN',
            style: AppTypography.headlineMd.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (data.hourlyTotals.fold<int>(0, (m, v) => v > m ? v : m) * 1.2).clamp(500, 50000).toDouble(),
                barTouchData: BarTouchData(
                  touchCallback: (FlTouchEvent event, touchResponse) {
                    if (event is FlTapUpEvent && touchResponse?.spot != null) {
                      final h = touchResponse!.spot!.touchedBarGroupIndex;
                      final amount = data.hourlyTotals[h];
                      final label = DateFormat('h a').format(DateTime(2026, 1, 1, h));
                      StatsPopover.show(
                        context,
                        title: 'Hourly Intake',
                        subtitle: 'Time bucket: $label',
                        primaryValue: _formatMl(amount),
                      );
                    }
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 6,
                      getTitlesWidget: (val, meta) {
                        final h = val.toInt();
                        if (h % 6 == 0 && h < 24) {
                          return Text(
                            '$h:00',
                            style: AppTypography.labelSm.copyWith(fontSize: 9),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: data.hourlyTotals.asMap().entries.map((e) {
                  final h = e.key;
                  final amount = e.value;
                  return BarChartGroupData(
                    x: h,
                    barRods: [
                      BarChartRodData(
                        toY: amount.toDouble().clamp(amount > 0 ? 30.0 : 4.0, 50000.0),
                        color: const Color(0xFFFFDE00),
                        width: 8,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _computedInsightLine(data.insightLine),
        ],
      ),
    );
  }

  // 8. Heat Map Card (7-cell row for Week, GitHub Grid for Month/Year/Lifetime)
  Widget _buildHeatmapCard(List<HeatmapCellData> cells, TimeRange range) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.black, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HYDRATION HEAT MAP',
                style: AppTypography.headlineMd.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              Row(
                children: [
                  _legendDot(const Color(0xFF2E7D32), 'Met'),
                  const SizedBox(width: 6),
                  _legendDot(const Color(0xFFFFDE00), 'Partial'),
                  const SizedBox(width: 6),
                  _legendDot(const Color(0xFFFF5252), 'Missed'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          CalendarHeatmap(
            cells: cells,
            range: range,
            onCellTap: (cell) {
              StatsPopover.show(
                context,
                title: DateFormat('EEEE, MMM d').format(cell.date),
                subtitle: 'Daily Heat Map status',
                primaryValue: _formatMl(cell.consumedMl),
                secondaryValue: 'Goal: ${_formatMl(cell.goalMl)}',
                actionLabel: 'VIEW DAY IN HISTORY →',
                onAction: () {
                  ref.read(selectedHistoryDateProvider.notifier).state = DateTime(cell.date.year, cell.date.month, cell.date.day);
                  context.go('/history');
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // 9. Best Day / Lowest Day Cards
  Widget _buildBestLowestDayCards(PersonalRecordsData records) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (records.bestDayDate != null) {
                ref.read(selectedHistoryDateProvider.notifier).state = DateTime(records.bestDayDate!.year, records.bestDayDate!.month, records.bestDayDate!.day);
                context.go('/history');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDE00),
                border: Border.all(color: AppColors.black, width: 3),
                boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(3.5, 3.5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🏆 BEST DAY',
                    style: AppTypography.labelSm.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMl(records.bestDayMl),
                    style: AppTypography.headlineLg.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    records.bestDayDate != null
                        ? DateFormat('MMM d, yyyy').format(records.bestDayDate!)
                        : 'No logs',
                    style: AppTypography.labelSm.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (records.lowestDayDate != null) {
                ref.read(selectedHistoryDateProvider.notifier).state = DateTime(records.lowestDayDate!.year, records.lowestDayDate!.month, records.lowestDayDate!.day);
                context.go('/history');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF80AB),
                border: Border.all(color: AppColors.black, width: 3),
                boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(3.5, 3.5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📉 LOWEST DAY',
                    style: AppTypography.labelSm.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMl(records.lowestDayMl),
                    style: AppTypography.headlineLg.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    records.lowestDayDate != null
                        ? DateFormat('MMM d, yyyy').format(records.lowestDayDate!)
                        : 'No logs',
                    style: AppTypography.labelSm.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 10. Longest Streak Card
  Widget _buildLongestStreakCard(int longestStreak) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.black, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(4, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Color(0xFFFFDE00), size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'LONGEST STREAK: $longestStreak DAYS',
              style: AppTypography.headlineMd.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 11. Personal Records Card
  Widget _buildPersonalRecordsCard(PersonalRecordsData records) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.black, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERSONAL RECORDS',
            style: AppTypography.headlineMd.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          _recordRow(
            icon: Icons.water_drop,
            label: 'MOST WATER IN A DAY',
            value: _formatMl(records.maxWaterSingleDayMl),
            date: records.maxWaterDate != null
                ? DateFormat('MMM d, yyyy').format(records.maxWaterDate!)
                : '-',
            onTap: () {
              if (records.maxWaterDate != null) {
                ref.read(selectedHistoryDateProvider.notifier).state = DateTime(records.maxWaterDate!.year, records.maxWaterDate!.month, records.maxWaterDate!.day);
                context.go('/history');
              }
            },
          ),
          const Divider(color: AppColors.outlineVariant),
          _recordRow(
            icon: Icons.local_fire_department,
            label: 'LONGEST STREAK',
            value: '${records.longestStreakDays} Days',
            date: 'All Time Record',
            onTap: () {},
          ),
          const Divider(color: AppColors.outlineVariant),
          _recordRow(
            icon: Icons.local_bar,
            label: 'MOST DRINKS IN A DAY',
            value: '${records.maxDrinksSingleDayCount} Drinks',
            date: records.maxDrinksDate != null
                ? DateFormat('MMM d, yyyy').format(records.maxDrinksDate!)
                : '-',
            onTap: () {
              if (records.maxDrinksDate != null) {
                ref.read(selectedHistoryDateProvider.notifier).state = DateTime(records.maxDrinksDate!.year, records.maxDrinksDate!.month, records.maxDrinksDate!.day);
                context.go('/history');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _recordRow({
    required IconData icon,
    required String label,
    required String value,
    required String date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDE00),
                border: Border.all(color: AppColors.black, width: 1.5),
              ),
              child: Icon(icon, size: 18, color: AppColors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.labelSm.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF666666),
                    ),
                  ),
                  Text(
                    date,
                    style: AppTypography.bodyMd.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: AppTypography.headlineMd.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0047FF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 12. Period Comparison Card
  Widget _buildComparisonCard(PeriodComparisonData comp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.black, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comp.title,
            style: AppTypography.headlineMd.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT PERIOD',
                    style: AppTypography.labelSm.copyWith(fontSize: 10, color: const Color(0xFF666666)),
                  ),
                  Text(
                    _formatMl(comp.currentTotalMl),
                    style: AppTypography.headlineLg.copyWith(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: comp.isImprovement ? AppColors.success : AppColors.error,
                  border: Border.all(color: AppColors.black, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(
                      comp.isImprovement ? Icons.arrow_upward : Icons.arrow_downward,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${comp.pctChange}%',
                      style: AppTypography.labelSm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PRIOR PERIOD',
                    style: AppTypography.labelSm.copyWith(fontSize: 10, color: const Color(0xFF666666)),
                  ),
                  Text(
                    _formatMl(comp.previousTotalMl),
                    style: AppTypography.headlineLg.copyWith(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 13. Rule-based AI Insights Card
  Widget _buildAiInsightsCard(
    HourlyPatternData hourlyPattern,
    DrinkBreakdownData drinkBreakdown,
    StatsOverview overview,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        border: Border.all(color: AppColors.black, width: 3),
        boxShadow: const [BoxShadow(color: AppColors.black, offset: Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'AI HYDRATION INSIGHTS',
                style: AppTypography.headlineMd.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _bulletPoint(hourlyPattern.insightLine),
          const SizedBox(height: 6),
          _bulletPoint(drinkBreakdown.insightLine),
          const SizedBox(height: 6),
          _bulletPoint('Overall goal completion rate is ${overview.goalCompletionPct}% for this period.'),
        ],
      ),
    );
  }

  Widget _bulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _computedInsightLine(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        border: Border.all(color: AppColors.black, width: 1.5),
      ),
      child: Text(
        text,
        style: AppTypography.bodyMd.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0047FF),
        ),
      ),
    );
  }
}
