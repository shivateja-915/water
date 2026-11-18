import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/hydration_provider.dart';
import '../../providers/drink_type_provider.dart';
import '../widgets/neu_button.dart';
import '../widgets/neu_input.dart';
import '../widgets/neu_chip.dart';
import '../widgets/neu_modal.dart';
import 'undo_overlay.dart';

class CustomLogModal {
  static Future<void> show(BuildContext context, WidgetRef ref) async {
    final amountController = TextEditingController();
    String? selectedTypeId;

    await NeuModal.show(
      context,
      title: 'Custom Log',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          final drinkTypes = ref.read(drinkTypesProvider).valueOrNull ?? [];
          final selected = ref.read(selectedDrinkTypeProvider);
          selectedTypeId ??= selected?.id ?? drinkTypes.firstOrNull?.id;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NeuInput(
                label: 'Amount (ml)',
                hint: 'Enter amount',
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

              const SizedBox(height: AppSpacing.md),

              NeuButton(
                label: 'Log It',
                isFullWidth: true,
                icon: Icons.add,
                onPressed: () {
                  final amount = int.tryParse(amountController.text);
                  if (amount == null || amount <= 0) return;

                  final type = drinkTypes.firstWhere(
                    (t) => t.id == selectedTypeId,
                    orElse: () => drinkTypes.first,
                  );

                  ref.read(todayLogsProvider.notifier).addLog(
                        amountMl: amount,
                        drinkType: type,
                      );

                  Navigator.of(context).pop();

                  // Use UndoOverlay with 3-second countdown
                  UndoOverlay.show(
                    context,
                    message: 'ADDED ${amount}ML ${type.name.toUpperCase()}',
                    durationSeconds: 3,
                    onUndo: () {
                      final logs =
                          ref.read(todayLogsProvider).valueOrNull;
                      if (logs != null && logs.isNotEmpty) {
                        ref
                            .read(todayLogsProvider.notifier)
                            .deleteLog(logs.first.id);
                      }
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
