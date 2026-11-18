import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../providers/stats_provider.dart';

class CalendarHeatmap extends StatelessWidget {
  final List<HeatmapCellData> cells;
  final TimeRange range;
  final Function(HeatmapCellData cell)? onCellTap;

  const CalendarHeatmap({
    super.key,
    required this.cells,
    required this.range,
    this.onCellTap,
  });

  Color _getCellColor(HeatmapStatus status) {
    switch (status) {
      case HeatmapStatus.met:
        return const Color(0xFF2E7D32); // Green
      case HeatmapStatus.partial:
        return const Color(0xFFFFDE00); // Sunny Yellow
      case HeatmapStatus.missed:
        return const Color(0xFFFF5252); // Red / Pink
      case HeatmapStatus.empty:
        return const Color(0xFFE0E0E0); // Light Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) {
      return const SizedBox.shrink();
    }

    if (range == TimeRange.week) {
      // 7-cell row for Week
      final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(cells.length.clamp(0, 7), (i) {
          final cell = cells[i];
          final color = _getCellColor(cell.status);
          final dayLabel = i < weekDays.length ? weekDays[i] : '';

          return Expanded(
            child: GestureDetector(
              onTap: () => onCellTap?.call(cell),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: AppColors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(color: AppColors.black, offset: Offset(2, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      dayLabel,
                      style: AppTypography.labelSm.copyWith(
                        color: cell.status == HeatmapStatus.met
                            ? Colors.white
                            : AppColors.black,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d').format(cell.date),
                      style: AppTypography.bodyMd.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: cell.status == HeatmapStatus.met
                            ? Colors.white
                            : AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      );
    }

    // Grid layout for Month, Year, Lifetime
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: cells.map((cell) {
            final color = _getCellColor(cell.status);
            return GestureDetector(
              onTap: () => onCellTap?.call(cell),
              child: Tooltip(
                message:
                    '${DateFormat('MMM d').format(cell.date)}: ${cell.consumedMl} ml',
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(color: AppColors.black, width: 1.5),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
