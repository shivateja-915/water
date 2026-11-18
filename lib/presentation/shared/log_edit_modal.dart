import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/hydration_log.dart';
import '../../providers/hydration_provider.dart';
import '../../providers/drink_type_provider.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_input.dart';
import '../widgets/neu_chip.dart';
import '../widgets/neu_modal.dart';
import 'undo_overlay.dart';

class LogEditModal {
  static Future<void> show(
      BuildContext context, WidgetRef ref, HydrationLog log) async {
    final amountController =
        TextEditingController(text: log.amountMl.toString());
    String? selectedTypeId = log.drinkTypeId;
    TimeOfDay selectedTime = TimeOfDay(
      hour: log.loggedAt.toLocal().hour,
      minute: log.loggedAt.toLocal().minute,
    );

    await NeuModal.show(
      context,
      title: 'Edit Log',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          final drinkTypes = ref.read(drinkTypesProvider).valueOrNull ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NeuInput(
                label: 'Amount (ml)',
                controller: amountController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.sm),

              Text(
                'DRINK TYPE',
                style: AppTypography.labelSm
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: drinkTypes.map((type) {
                  return NeuChip(
                    label: type.name,
                    isSelected: selectedTypeId == type.id,
                    onTap: () {
                      setModalState(() => selectedTypeId = type.id);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                'TIME',
                style: AppTypography.labelSm
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xs),
              GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setModalState(() => selectedTime = time);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppColors.black,
                        width: AppSpacing.borderWidth),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.black,
                        offset: Offset(2, 2),
                      ),
                    ],
                    color: AppColors.surfaceContainerLowest,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        style: AppTypography.numberSm
                            .copyWith(color: AppColors.onSurface),
                      ),
                      const Icon(Icons.access_time,
                          color: AppColors.outline, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              NeuButton(
                label: 'Save',
                isFullWidth: true,
                onPressed: () {
                  final amount =
                      int.tryParse(amountController.text) ?? log.amountMl;
                  final type = drinkTypes.firstWhere(
                    (t) => t.id == selectedTypeId,
                    orElse: () => drinkTypes.first,
                  );
                  final hydratedMl =
                      (amount * type.hydrationMultiplier).round();

                  final now = log.loggedAt;
                  final newLoggedAt = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  final updated = log.copyWith(
                    amountMl: amount,
                    hydratedMl: hydratedMl,
                    drinkTypeId: selectedTypeId,
                    loggedAt: newLoggedAt,
                  );

                  ref.read(todayLogsProvider.notifier).updateLog(updated);
                  Navigator.of(context).pop();
                },
              ),

              const SizedBox(height: AppSpacing.xs),

              NeuButton.error(
                label: 'Delete',
                isFullWidth: true,
                icon: Icons.delete_outline,
                onPressed: () {
                  ref
                      .read(todayLogsProvider.notifier)
                      .deleteLog(log.id);
                  Navigator.of(context).pop();

                  UndoOverlay.show(
                    context,
                    message: 'LOG DELETED',
                    durationSeconds: 3,
                    onUndo: () {
                      ref
                          .read(todayLogsProvider.notifier)
                          .addLog(
                            amountMl: log.amountMl,
                            drinkType: drinkTypes.firstWhere(
                              (t) => t.id == log.drinkTypeId,
                              orElse: () => drinkTypes.first,
                            ),
                            loggedAt: log.loggedAt,
                          );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
