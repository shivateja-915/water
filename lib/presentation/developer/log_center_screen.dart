import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../notifications/notification_history.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_card.dart';

class LogCenterScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const LogCenterScreen({super.key, required this.onBack});

  @override
  ConsumerState<LogCenterScreen> createState() => _LogCenterScreenState();
}

class _LogCenterScreenState extends ConsumerState<LogCenterScreen> {
  final TextEditingController _filterController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(notificationHistoryProvider);
    final filteredHistory = history.where((item) {
      if (_filter.isEmpty) return true;
      final query = _filter.toLowerCase();
      return item.title.toLowerCase().contains(query) ||
          item.body.toLowerCase().contains(query) ||
          item.channelId.toLowerCase().contains(query);
    }).toList();

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
                      'LOG CENTER',
                      style: AppTypography.headlineLg
                          .copyWith(color: AppColors.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Filter
              NeuCard(
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _filterController,
                        style: AppTypography.bodyMd,
                        decoration: const InputDecoration(
                          hintText: 'Filter logs by keyword...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (val) => setState(() => _filter = val),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text('NOTIFICATION & SYSTEM LOGS (${filteredHistory.length})',
                  style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.xs),

              if (filteredHistory.isEmpty)
                const NeuCard(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No matching log entries found.'),
                    ),
                  ),
                )
              else
                ...filteredHistory.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NeuCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: AppTypography.bodyMd.copyWith(
                                        color: AppColors.onSurface,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                                Text(
                                  item.timestamp.toIso8601String().substring(11, 19),
                                  style: AppTypography.labelSm.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontSize: 10),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(item.body,
                                style: AppTypography.labelSm.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 11)),
                            const SizedBox(height: 4),
                            Text('Channel: ${item.channelId}',
                                style: AppTypography.labelSm.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    )),

              const SizedBox(height: AppSpacing.md),

              NeuButton(
                label: '📋 Copy All Logs to Clipboard',
                isFullWidth: true,
                onPressed: () {
                  final buffer = StringBuffer();
                  for (final item in history) {
                    buffer.writeln('[${item.timestamp}] ${item.title} - ${item.body} (Channel: ${item.channelId})');
                  }
                  Clipboard.setData(ClipboardData(text: buffer.toString()));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All logs copied to clipboard!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
