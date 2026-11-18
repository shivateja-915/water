import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SparklineWidget extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double height;

  const SparklineWidget({
    super.key,
    required this.values,
    this.color = AppColors.primary,
    this.height = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(height: height);
    }

    final maxVal = values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((v) {
          final ratio = maxVal > 0 ? (v / maxVal).clamp(0.1, 1.0) : 0.1;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              height: height * ratio,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
