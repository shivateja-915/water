import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/models/hydration_log.dart';
import 'hydration_provider.dart';
import 'profile_provider.dart';
import 'drink_type_provider.dart';

enum TimeRange { today, week, month, year, lifetime }

class StatsTimeRangeState {
  final TimeRange range;
  final DateTime anchorDate;

  StatsTimeRangeState({
    required this.range,
    required this.anchorDate,
  });

  StatsTimeRangeState copyWith({
    TimeRange? range,
    DateTime? anchorDate,
  }) {
    return StatsTimeRangeState(
      range: range ?? this.range,
      anchorDate: anchorDate ?? this.anchorDate,
    );
  }
}

final statsTimeRangeProvider =
    StateNotifierProvider<StatsTimeRangeNotifier, StatsTimeRangeState>((ref) {
  return StatsTimeRangeNotifier();
});

class StatsTimeRangeNotifier extends StateNotifier<StatsTimeRangeState> {
  StatsTimeRangeNotifier()
      : super(StatsTimeRangeState(
          range: TimeRange.week,
          anchorDate: DateTime.now(),
        ));

  void setRange(TimeRange range) {
    state = state.copyWith(range: range);
  }

  void setAnchorDate(DateTime date) {
    state = state.copyWith(anchorDate: date);
  }
}

/// Helper model for an intake chart bucket
class IntakeBucket {
  final String label;
  final DateTime date;
  final int consumedMl;
  final int goalMl;
  final bool isMet;

  IntakeBucket({
    required this.label,
    required this.date,
    required this.consumedMl,
    required this.goalMl,
    required this.isMet,
  });

  double get completionPercentage =>
      goalMl > 0 ? (consumedMl / goalMl).clamp(0.0, 1.0) : 0.0;
}

/// Provider for raw logs for all time (used for lifetime stats)
final allLogsProvider = FutureProvider<List<HydrationLog>>((ref) async {
  ref.watch(todayLogsProvider);
  final repo = ref.read(hydrationLogRepositoryProvider);
  final profile = ref.watch(profileProvider).valueOrNull;
  final userId = profile?.id;
  if (userId == null) return [];
  // Get all logs from 2020 to far future
  final start = DateTime(2020, 1, 1);
  final end = DateTime.now().add(const Duration(days: 1));
  return repo.getLogsForDateRange(userId, start, end);
});

/// Provider for logs in the currently selected time range
final periodLogsProvider = Provider<List<HydrationLog>>((ref) {
  final timeRangeState = ref.watch(statsTimeRangeProvider);
  final allLogsAsync = ref.watch(allLogsProvider);
  final logs = allLogsAsync.valueOrNull ?? [];
  final anchor = timeRangeState.anchorDate;

  DateTime start;
  DateTime end;

  switch (timeRangeState.range) {
    case TimeRange.today:
      start = DateTime(anchor.year, anchor.month, anchor.day);
      end = DateTime(anchor.year, anchor.month, anchor.day, 23, 59, 59);
      break;
    case TimeRange.week:
      // Monday to Sunday of anchor week
      final weekday = anchor.weekday; // 1 = Mon, 7 = Sun
      start = DateTime(anchor.year, anchor.month, anchor.day)
          .subtract(Duration(days: weekday - 1));
      end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      break;
    case TimeRange.month:
      start = DateTime(anchor.year, anchor.month, 1);
      final nextMonth = DateTime(anchor.year, anchor.month + 1, 1);
      end = nextMonth.subtract(const Duration(seconds: 1));
      break;
    case TimeRange.year:
      start = DateTime(anchor.year, 1, 1);
      end = DateTime(anchor.year, 12, 31, 23, 59, 59);
      break;
    case TimeRange.lifetime:
      start = DateTime(2020, 1, 1);
      end = DateTime.now().add(const Duration(days: 1));
      break;
  }

  return logs.where((log) {
    final t = log.loggedAt.toLocal();
    return t.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
        t.isBefore(end.add(const Duration(milliseconds: 1)));
  }).toList();
});

/// Overview statistics model
class StatsOverview {
  final int avgIntakeMl;
  final int goalCompletionPct;
  final int currentStreakDays;
  final int lifetimeTotalMl;
  final List<double> avgIntakeSparkline;
  final List<double> goalCompletionSparkline;
  final String avgIntakeComparison;
  final String goalCompletionComparison;

  StatsOverview({
    required this.avgIntakeMl,
    required this.goalCompletionPct,
    required this.currentStreakDays,
    required this.lifetimeTotalMl,
    required this.avgIntakeSparkline,
    required this.goalCompletionSparkline,
    required this.avgIntakeComparison,
    required this.goalCompletionComparison,
  });
}

final statsOverviewProvider = Provider<StatsOverview>((ref) {
  final timeRangeState = ref.watch(statsTimeRangeProvider);
  final periodLogs = ref.watch(periodLogsProvider);
  final allLogs = ref.watch(allLogsProvider).valueOrNull ?? [];
  final profile = ref.watch(profileProvider).valueOrNull;
  final goal = profile?.dailyGoalMl ?? 2500;

  // Lifetime total
  final lifetimeTotalMl = allLogs.fold<int>(0, (sum, log) => sum + log.amountMl);

  // Group period logs by date
  final dailyTotals = <String, int>{};
  final dailyHydrated = <String, int>{};

  for (final log in periodLogs) {
    final dayKey = DateFormat('yyyy-MM-dd').format(log.loggedAt.toLocal());
    dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + log.amountMl;
    dailyHydrated[dayKey] = (dailyHydrated[dayKey] ?? 0) + log.hydratedMl;
  }

  final periodTotalMl = periodLogs.fold<int>(0, (sum, log) => sum + log.amountMl);

  int daysInPeriod = 1;
  switch (timeRangeState.range) {
    case TimeRange.today:
      daysInPeriod = 1;
      break;
    case TimeRange.week:
      daysInPeriod = 7;
      break;
    case TimeRange.month:
      final anchor = timeRangeState.anchorDate;
      daysInPeriod = DateTime(anchor.year, anchor.month + 1, 0).day;
      break;
    case TimeRange.year:
      daysInPeriod = 365;
      break;
    case TimeRange.lifetime:
      daysInPeriod = dailyTotals.isNotEmpty ? dailyTotals.length : 1;
      break;
  }

  final avgIntakeMl = periodTotalMl ~/ daysInPeriod;

  int completedDays = dailyHydrated.values.where((v) => v >= goal).length;
  final goalCompletionPct = daysInPeriod > 0
      ? ((completedDays / daysInPeriod) * 100).round().clamp(0, 100)
      : 0;

  // Streak calculation
  final currentStreakDays = profile?.streakCurrent ?? 0;

  // Sparklines: last 7 days of data
  final now = DateTime.now();
  final last7Days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
  final avgIntakeSparkline = <double>[];
  final goalCompletionSparkline = <double>[];

  for (final date in last7Days) {
    final dayKey = DateFormat('yyyy-MM-dd').format(date);
    final dayLogs = allLogs.where((l) =>
        DateFormat('yyyy-MM-dd').format(l.loggedAt.toLocal()) == dayKey);
    final dayTotal = dayLogs.fold<int>(0, (sum, l) => sum + l.amountMl);
    final dayHydrated = dayLogs.fold<int>(0, (sum, l) => sum + l.hydratedMl);

    avgIntakeSparkline.add(dayTotal.toDouble());
    goalCompletionSparkline.add(goal > 0 ? (dayHydrated / goal).clamp(0.0, 1.0) : 0.0);
  }

  final diffVsGoal = goal > 0 ? (((avgIntakeMl - goal) / goal) * 100).round() : 0;
  final avgIntakeComparison = diffVsGoal >= 0
      ? '$diffVsGoal% above your ${_formatMl(goal)} goal'
      : '${diffVsGoal.abs()}% below your ${_formatMl(goal)} goal';

  final goalCompletionComparison = '$completedDays of $daysInPeriod days met goal';

  return StatsOverview(
    avgIntakeMl: avgIntakeMl,
    goalCompletionPct: goalCompletionPct,
    currentStreakDays: currentStreakDays,
    lifetimeTotalMl: lifetimeTotalMl,
    avgIntakeSparkline: avgIntakeSparkline,
    goalCompletionSparkline: goalCompletionSparkline,
    avgIntakeComparison: avgIntakeComparison,
    goalCompletionComparison: goalCompletionComparison,
  );
});

String _formatMl(int ml) {
  if (ml >= 1000) return '${(ml / 1000).toStringAsFixed(1)}L';
  return '${ml}ml';
}

/// Zero-filled intake buckets provider
final statsIntakeBucketsProvider = Provider<List<IntakeBucket>>((ref) {
  final timeRangeState = ref.watch(statsTimeRangeProvider);
  final periodLogs = ref.watch(periodLogsProvider);
  final profile = ref.watch(profileProvider).valueOrNull;
  final goal = profile?.dailyGoalMl ?? 2500;
  final anchor = timeRangeState.anchorDate;

  final buckets = <IntakeBucket>[];

  switch (timeRangeState.range) {
    case TimeRange.today:
      // Hidden section for Today
      break;
    case TimeRange.week:
      // Fixed 7 days: Mon to Sun
      final weekday = anchor.weekday;
      final mon = DateTime(anchor.year, anchor.month, anchor.day)
          .subtract(Duration(days: weekday - 1));

      for (int i = 0; i < 7; i++) {
        final date = mon.add(Duration(days: i));
        final dayKey = DateFormat('yyyy-MM-dd').format(date);
        final dayLogs = periodLogs.where(
            (l) => DateFormat('yyyy-MM-dd').format(l.loggedAt.toLocal()) == dayKey);
        final total = dayLogs.fold<int>(0, (s, l) => s + l.amountMl);
        final hydrated = dayLogs.fold<int>(0, (s, l) => s + l.hydratedMl);
        final label = DateFormat('EEE').format(date).toUpperCase();

        buckets.add(IntakeBucket(
          label: label,
          date: date,
          consumedMl: total,
          goalMl: goal,
          isMet: hydrated >= goal,
        ));
      }
      break;

    case TimeRange.month:
      final daysInMonth = DateTime(anchor.year, anchor.month + 1, 0).day;
      for (int d = 1; d <= daysInMonth; d++) {
        final date = DateTime(anchor.year, anchor.month, d);
        final dayKey = DateFormat('yyyy-MM-dd').format(date);
        final dayLogs = periodLogs.where(
            (l) => DateFormat('yyyy-MM-dd').format(l.loggedAt.toLocal()) == dayKey);
        final total = dayLogs.fold<int>(0, (s, l) => s + l.amountMl);
        final hydrated = dayLogs.fold<int>(0, (s, l) => s + l.hydratedMl);
        final label = d.toString();

        buckets.add(IntakeBucket(
          label: label,
          date: date,
          consumedMl: total,
          goalMl: goal,
          isMet: hydrated >= goal,
        ));
      }
      break;

    case TimeRange.year:
      for (int m = 1; m <= 12; m++) {
        final monthDate = DateTime(anchor.year, m, 1);
        final monthLogs = periodLogs.where((l) =>
            l.loggedAt.toLocal().year == anchor.year &&
            l.loggedAt.toLocal().month == m);
        final total = monthLogs.fold<int>(0, (s, l) => s + l.amountMl);
        final hydrated = monthLogs.fold<int>(0, (s, l) => s + l.hydratedMl);
        final monthGoal = goal * DateTime(anchor.year, m + 1, 0).day;
        final label = DateFormat('MMM').format(monthDate).toUpperCase();

        buckets.add(IntakeBucket(
          label: label,
          date: monthDate,
          consumedMl: total,
          goalMl: monthGoal,
          isMet: hydrated >= monthGoal,
        ));
      }
      break;

    case TimeRange.lifetime:
      final allLogs = ref.watch(allLogsProvider).valueOrNull ?? [];
      final firstLogDate = allLogs.isNotEmpty
          ? allLogs.map((l) => l.loggedAt.toLocal()).reduce((a, b) => a.isBefore(b) ? a : b)
          : DateTime.now();
      final startYearMonth = DateTime(firstLogDate.year, firstLogDate.month);
      final currentYearMonth = DateTime(DateTime.now().year, DateTime.now().month);

      DateTime curr = startYearMonth;
      while (!curr.isAfter(currentYearMonth)) {
        final monthLogs = allLogs.where((l) =>
            l.loggedAt.toLocal().year == curr.year &&
            l.loggedAt.toLocal().month == curr.month);
        final total = monthLogs.fold<int>(0, (s, l) => s + l.amountMl);
        final hydrated = monthLogs.fold<int>(0, (s, l) => s + l.hydratedMl);
        final daysInM = DateTime(curr.year, curr.month + 1, 0).day;
        final monthGoal = goal * daysInM;
        final label = DateFormat('MMM yy').format(curr).toUpperCase();

        buckets.add(IntakeBucket(
          label: label,
          date: curr,
          consumedMl: total,
          goalMl: monthGoal,
          isMet: hydrated >= monthGoal,
        ));

        curr = DateTime(curr.year, curr.month + 1, 1);
      }
      break;
  }

  return buckets;
});

/// Goal Completion Trend Provider
class GoalTrendData {
  final List<double> completionPcts; // 0 to 100
  final List<String> labels;
  final String insightLine;

  GoalTrendData({
    required this.completionPcts,
    required this.labels,
    required this.insightLine,
  });
}

final statsGoalTrendProvider = Provider<GoalTrendData>((ref) {
  final buckets = ref.watch(statsIntakeBucketsProvider);
  final pcts = <double>[];
  final labels = <String>[];

  for (final b in buckets) {
    pcts.add((b.completionPercentage * 100).roundToDouble());
    labels.add(b.label);
  }

  String insightLine = 'Maintaining steady hydration performance.';
  if (pcts.length >= 2) {
    final mid = pcts.length ~/ 2;
    final firstHalfAvg = pcts.sublist(0, mid).fold<double>(0, (s, v) => s + v) / (mid > 0 ? mid : 1);
    final secondHalfAvg = pcts.sublist(mid).fold<double>(0, (s, v) => s + v) / (pcts.length - mid);
    final diff = (secondHalfAvg - firstHalfAvg).round();

    if (diff > 0) {
      insightLine = 'Trending up +$diff% vs previous period';
    } else if (diff < 0) {
      insightLine = 'Trending down ${diff.abs()}% vs previous period';
    } else {
      insightLine = 'Holding steady compared to previous period';
    }
  }

  return GoalTrendData(
    completionPcts: pcts,
    labels: labels,
    insightLine: insightLine,
  );
});

/// Drink Type Breakdown Provider
class DrinkBreakdownItem {
  final String id;
  final String name;
  final int amountMl;
  final double percentage;
  final String colorHex;
  final String icon;

  DrinkBreakdownItem({
    required this.id,
    required this.name,
    required this.amountMl,
    required this.percentage,
    required this.colorHex,
    required this.icon,
  });
}

class DrinkBreakdownData {
  final List<DrinkBreakdownItem> items;
  final String insightLine;

  DrinkBreakdownData({
    required this.items,
    required this.insightLine,
  });
}

final statsDrinkBreakdownProvider = Provider<DrinkBreakdownData>((ref) {
  final periodLogs = ref.watch(periodLogsProvider);
  final drinkTypesAsync = ref.watch(drinkTypesProvider);
  final drinkTypes = drinkTypesAsync.valueOrNull ?? [];

  final totalMl = periodLogs.fold<int>(0, (s, l) => s + l.amountMl);
  final categoryTotals = <String, int>{};

  for (final log in periodLogs) {
    final name = (log.drinkTypeName ?? 'WATER').toUpperCase();
    categoryTotals[name] = (categoryTotals[name] ?? 0) + log.amountMl;
  }

  final items = <DrinkBreakdownItem>[];
  String dominantName = 'Water';
  double maxPct = 0.0;

  categoryTotals.forEach((name, amount) {
    final pct = totalMl > 0 ? (amount / totalMl) * 100 : 0.0;
    final typeMatch = drinkTypes.where((t) => t.name.toUpperCase() == name).firstOrNull;
    final colorHex = typeMatch?.color ?? _getFallbackColorHex(name);
    final icon = typeMatch?.icon ?? 'water_drop';

    items.add(DrinkBreakdownItem(
      id: typeMatch?.id ?? name.toLowerCase(),
      name: name,
      amountMl: amount,
      percentage: pct,
      colorHex: colorHex,
      icon: icon,
    ));

    if (pct > maxPct) {
      maxPct = pct;
      dominantName = name;
    }
  });

  items.sort((a, b) => b.amountMl.compareTo(a.amountMl));

  final insight = totalMl > 0
      ? '$dominantName made up ${maxPct.round()}% of your intake this period.'
      : 'No intake logged yet for this period.';

  return DrinkBreakdownData(items: items, insightLine: insight);
});

String _getFallbackColorHex(String name) {
  switch (name.toUpperCase()) {
    case 'WATER':
      return '#1976D2';
    case 'COFFEE':
      return '#6D4C41';
    case 'TEA':
      return '#2E7D32';
    case 'JUICE':
      return '#F5C518';
    case 'OTHER':
      return '#D81B60';
    default:
      return '#FFDE00';
  }
}

/// Hourly Drinking Time Pattern Provider
class HourlyPatternData {
  final List<int> hourlyTotals; // 24 buckets (0-23)
  final String peakHourLabel;
  final String insightLine;

  HourlyPatternData({
    required this.hourlyTotals,
    required this.peakHourLabel,
    required this.insightLine,
  });
}

final statsHourlyPatternProvider = Provider<HourlyPatternData>((ref) {
  final periodLogs = ref.watch(periodLogsProvider);
  final hourlyTotals = List<int>.filled(24, 0);

  for (final log in periodLogs) {
    final hour = log.loggedAt.toLocal().hour;
    if (hour >= 0 && hour < 24) {
      hourlyTotals[hour] += log.amountMl;
    }
  }

  int peakHour = 9;
  int maxVolume = 0;
  for (int h = 0; h < 24; h++) {
    if (hourlyTotals[h] > maxVolume) {
      maxVolume = hourlyTotals[h];
      peakHour = h;
    }
  }

  final peakStart = DateFormat('h a').format(DateTime(2026, 1, 1, peakHour));
  final peakEnd = DateFormat('h a').format(DateTime(2026, 1, 1, (peakHour + 1) % 24));
  final peakLabel = '$peakStart - $peakEnd';

  final timePeriodStr = peakHour < 12
      ? 'in the morning'
      : (peakHour < 17 ? 'in the afternoon' : 'in the evening');

  final insight = maxVolume > 0
      ? 'Peak hours: $peakLabel ($timePeriodStr)'
      : 'Log your drinks to see your hourly pattern!';

  return HourlyPatternData(
    hourlyTotals: hourlyTotals,
    peakHourLabel: peakLabel,
    insightLine: insight,
  );
});

/// Heatmap Status
enum HeatmapStatus { met, partial, missed, empty }

class HeatmapCellData {
  final DateTime date;
  final int consumedMl;
  final int goalMl;
  final HeatmapStatus status;

  HeatmapCellData({
    required this.date,
    required this.consumedMl,
    required this.goalMl,
    required this.status,
  });
}

final statsHeatmapProvider = Provider<List<HeatmapCellData>>((ref) {
  final timeRangeState = ref.watch(statsTimeRangeProvider);
  final allLogs = ref.watch(allLogsProvider).valueOrNull ?? [];
  final profile = ref.watch(profileProvider).valueOrNull;
  final goal = profile?.dailyGoalMl ?? 2500;
  final anchor = timeRangeState.anchorDate;

  final cells = <HeatmapCellData>[];
  DateTime start;
  int count;

  switch (timeRangeState.range) {
    case TimeRange.today:
      return [];
    case TimeRange.week:
      final weekday = anchor.weekday;
      start = DateTime(anchor.year, anchor.month, anchor.day)
          .subtract(Duration(days: weekday - 1));
      count = 7;
      break;
    case TimeRange.month:
      start = DateTime(anchor.year, anchor.month, 1);
      count = DateTime(anchor.year, anchor.month + 1, 0).day;
      break;
    case TimeRange.year:
      start = DateTime(anchor.year, 1, 1);
      count = 365;
      break;
    case TimeRange.lifetime:
      final now = DateTime.now();
      start = DateTime(now.year, now.month - 2, 1);
      count = 90;
      break;
  }

  for (int i = 0; i < count; i++) {
    final date = start.add(Duration(days: i));
    final dayKey = DateFormat('yyyy-MM-dd').format(date);
    final dayLogs = allLogs.where(
        (l) => DateFormat('yyyy-MM-dd').format(l.loggedAt.toLocal()) == dayKey);
    final hydrated = dayLogs.fold<int>(0, (s, l) => s + l.hydratedMl);
    final consumed = dayLogs.fold<int>(0, (s, l) => s + l.amountMl);

    HeatmapStatus status;
    if (hydrated >= goal) {
      status = HeatmapStatus.met;
    } else if (hydrated > 0) {
      status = HeatmapStatus.partial;
    } else if (date.isBefore(DateTime.now())) {
      status = HeatmapStatus.missed;
    } else {
      status = HeatmapStatus.empty;
    }

    cells.add(HeatmapCellData(
      date: date,
      consumedMl: consumed,
      goalMl: goal,
      status: status,
    ));
  }

  return cells;
});

/// Personal Records Model
class PersonalRecordsData {
  final int maxWaterSingleDayMl;
  final DateTime? maxWaterDate;
  final int longestStreakDays;
  final int maxDrinksSingleDayCount;
  final DateTime? maxDrinksDate;
  final int bestDayMl;
  final DateTime? bestDayDate;
  final int lowestDayMl;
  final DateTime? lowestDayDate;

  PersonalRecordsData({
    required this.maxWaterSingleDayMl,
    this.maxWaterDate,
    required this.longestStreakDays,
    required this.maxDrinksSingleDayCount,
    this.maxDrinksDate,
    required this.bestDayMl,
    this.bestDayDate,
    required this.lowestDayMl,
    this.lowestDayDate,
  });
}

final statsRecordsProvider = Provider<PersonalRecordsData>((ref) {
  final allLogs = ref.watch(allLogsProvider).valueOrNull ?? [];
  final periodLogs = ref.watch(periodLogsProvider);
  final profile = ref.watch(profileProvider).valueOrNull;

  final dailyTotals = <String, int>{};
  final dailyCounts = <String, int>{};
  final dailyDates = <String, DateTime>{};

  for (final log in allLogs) {
    final dayKey = DateFormat('yyyy-MM-dd').format(log.loggedAt.toLocal());
    dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + log.amountMl;
    dailyCounts[dayKey] = (dailyCounts[dayKey] ?? 0) + 1;
    dailyDates[dayKey] = DateTime(log.loggedAt.toLocal().year,
        log.loggedAt.toLocal().month, log.loggedAt.toLocal().day);
  }

  int maxWater = 0;
  DateTime? maxWaterDate;
  dailyTotals.forEach((key, total) {
    if (total > maxWater) {
      maxWater = total;
      maxWaterDate = dailyDates[key];
    }
  });

  int maxDrinks = 0;
  DateTime? maxDrinksDate;
  dailyCounts.forEach((key, count) {
    if (count > maxDrinks) {
      maxDrinks = count;
      maxDrinksDate = dailyDates[key];
    }
  });

  // Period-scoped Best & Lowest Day
  final periodDailyTotals = <String, int>{};
  final periodDailyDates = <String, DateTime>{};

  for (final log in periodLogs) {
    final dayKey = DateFormat('yyyy-MM-dd').format(log.loggedAt.toLocal());
    periodDailyTotals[dayKey] = (periodDailyTotals[dayKey] ?? 0) + log.amountMl;
    periodDailyDates[dayKey] = DateTime(log.loggedAt.toLocal().year,
        log.loggedAt.toLocal().month, log.loggedAt.toLocal().day);
  }

  int bestMl = 0;
  DateTime? bestDate;
  int lowestMl = periodDailyTotals.isNotEmpty ? 999999 : 0;
  DateTime? lowestDate;

  periodDailyTotals.forEach((key, total) {
    if (total > bestMl) {
      bestMl = total;
      bestDate = periodDailyDates[key];
    }
    if (total < lowestMl && total > 0) {
      lowestMl = total;
      lowestDate = periodDailyDates[key];
    }
  });

  if (lowestMl == 999999) lowestMl = 0;

  return PersonalRecordsData(
    maxWaterSingleDayMl: maxWater,
    maxWaterDate: maxWaterDate,
    longestStreakDays: profile?.streakLongest ?? 0,
    maxDrinksSingleDayCount: maxDrinks,
    maxDrinksDate: maxDrinksDate,
    bestDayMl: bestMl,
    bestDayDate: bestDate,
    lowestDayMl: lowestMl,
    lowestDayDate: lowestDate,
  );
});

/// Period Comparison Model
class PeriodComparisonData {
  final String title;
  final int currentTotalMl;
  final int previousTotalMl;
  final int pctChange;
  final bool isImprovement;

  PeriodComparisonData({
    required this.title,
    required this.currentTotalMl,
    required this.previousTotalMl,
    required this.pctChange,
    required this.isImprovement,
  });
}

final statsComparisonProvider = Provider<PeriodComparisonData>((ref) {
  final timeRangeState = ref.watch(statsTimeRangeProvider);
  final allLogs = ref.watch(allLogsProvider).valueOrNull ?? [];
  final anchor = timeRangeState.anchorDate;

  DateTime currStart;
  DateTime currEnd;
  DateTime prevStart;
  DateTime prevEnd;
  String title;

  switch (timeRangeState.range) {
    case TimeRange.week:
      final weekday = anchor.weekday;
      currStart = DateTime(anchor.year, anchor.month, anchor.day)
          .subtract(Duration(days: weekday - 1));
      currEnd = currStart.add(const Duration(days: 6, hours: 23, minutes: 59));
      prevStart = currStart.subtract(const Duration(days: 7));
      prevEnd = currStart.subtract(const Duration(seconds: 1));
      title = 'THIS WEEK VS LAST WEEK';
      break;

    case TimeRange.month:
      currStart = DateTime(anchor.year, anchor.month, 1);
      currEnd = DateTime(anchor.year, anchor.month + 1, 0, 23, 59, 59);
      prevStart = DateTime(anchor.year, anchor.month - 1, 1);
      prevEnd = currStart.subtract(const Duration(seconds: 1));
      title = 'THIS MONTH VS LAST MONTH';
      break;

    case TimeRange.year:
      currStart = DateTime(anchor.year, 1, 1);
      currEnd = DateTime(anchor.year, 12, 31, 23, 59, 59);
      prevStart = DateTime(anchor.year - 1, 1, 1);
      prevEnd = DateTime(anchor.year - 1, 12, 31, 23, 59, 59);
      title = 'THIS YEAR VS LAST YEAR';
      break;

    default:
      currStart = DateTime.now();
      currEnd = DateTime.now();
      prevStart = DateTime.now();
      prevEnd = DateTime.now();
      title = 'PERIOD COMPARISON';
      break;
  }

  final currLogs = allLogs.where((l) {
    final t = l.loggedAt.toLocal();
    return t.isAfter(currStart.subtract(const Duration(milliseconds: 1))) &&
        t.isBefore(currEnd.add(const Duration(milliseconds: 1)));
  });

  final prevLogs = allLogs.where((l) {
    final t = l.loggedAt.toLocal();
    return t.isAfter(prevStart.subtract(const Duration(milliseconds: 1))) &&
        t.isBefore(prevEnd.add(const Duration(milliseconds: 1)));
  });

  final currTotal = currLogs.fold<int>(0, (s, l) => s + l.amountMl);
  final prevTotal = prevLogs.fold<int>(0, (s, l) => s + l.amountMl);

  int pctChange = 0;
  if (prevTotal > 0) {
    pctChange = (((currTotal - prevTotal) / prevTotal) * 100).round();
  } else if (currTotal > 0) {
    pctChange = 100;
  }

  return PeriodComparisonData(
    title: title,
    currentTotalMl: currTotal,
    previousTotalMl: prevTotal,
    pctChange: pctChange.abs(),
    isImprovement: pctChange >= 0,
  );
});

/// Streak Freezes Provider
class StreakFreezeState {
  final int availableFreezes;
  final int maxFreezes;

  StreakFreezeState({
    required this.availableFreezes,
    required this.maxFreezes,
  });
}

class StreakFreezeNotifier extends StateNotifier<StreakFreezeState> {
  StreakFreezeNotifier()
      : super(StreakFreezeState(availableFreezes: 2, maxFreezes: 2));

  Future<void> useFreeze() async {
    if (state.availableFreezes > 0) {
      state = StreakFreezeState(
        availableFreezes: state.availableFreezes - 1,
        maxFreezes: state.maxFreezes,
      );
    }
  }
}

final streakFreezeProvider =
    StateNotifierProvider<StreakFreezeNotifier, StreakFreezeState>((ref) {
  return StreakFreezeNotifier();
});
