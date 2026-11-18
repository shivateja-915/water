import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../providers/profile_provider.dart';

class AvatarSelectionScreen extends ConsumerStatefulWidget {
  const AvatarSelectionScreen({super.key});

  @override
  ConsumerState<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends ConsumerState<AvatarSelectionScreen> {
  late TextEditingController _seedController;

  final List<String> _swatchColors = [
    'FFDE00', // Sunny Yellow
    '0047FF', // Electric Blue
    'D81B60', // Bright Pink
    '2E7D32', // Vivid Green
    '6D4C41', // Deep Brown
    '9C27B0', // Purple
    'E0E0E0', // Light Grey
    'FFFFFF', // Pure White
  ];

  @override
  void initState() {
    super.initState();
    final currentDraft = ref.read(avatarDraftProvider);
    _seedController = TextEditingController(text: currentDraft.seed);
  }

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  String _generateRandomSeed() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random();
    return List.generate(8, (i) => chars[rnd.nextInt(chars.length)]).join();
  }

  Color _hexToColor(String hex) {
    String clean = hex.replaceAll('#', '');
    if (clean.length == 6) clean = 'FF$clean';
    return Color(int.tryParse(clean, radix: 16) ?? 0xFFFFDE00);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(avatarDraftProvider);
    final draftNotifier = ref.read(avatarDraftProvider.notifier);

    // Sync seed controller if updated via random button or initial load
    if (_seedController.text != draft.seed && !_seedController.selection.isValid) {
      _seedController.text = draft.seed;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
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
                      child: const Icon(Icons.arrow_back, color: AppColors.black),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'CHOOSE YOUR AVATAR',
                    style: AppTypography.headlineMd.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Live Preview Container Card with Animated Crossfade
                    Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.black, width: 3),
                          boxShadow: const [
                            BoxShadow(color: AppColors.black, offset: Offset(5, 5))
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(scale: animation, child: child),
                          ),
                          child: KeyedSubtree(
                            key: ValueKey(
                              '${draft.seed}_${draft.backgroundColor}_${draft.shapeColor}_${draft.flip}_${draft.rotate}_${draft.scale}',
                            ),
                            child: draft.buildWidget(size: 180),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Seed Section (Input + Random Button)
                    Text(
                      'AVATAR SEED',
                      style: AppTypography.headlineMd.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                              controller: _seedController,
                              onChanged: (val) => draftNotifier.updateSeed(val),
                              style: AppTypography.bodyLg.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.black,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                hintText: 'Enter seed string...',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            final newSeed = _generateRandomSeed();
                            _seedController.text = newSeed;
                            draftNotifier.updateSeed(newSeed);
                          },
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFDE00),
                              border: Border.all(color: AppColors.black, width: 3),
                              boxShadow: const [
                                BoxShadow(color: AppColors.black, offset: Offset(3, 3))
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.casino, color: AppColors.black, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  'RANDOM',
                                  style: AppTypography.labelSm.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.black,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Background Color Swatches
                    Text(
                      'BACKGROUND COLOR',
                      style: AppTypography.headlineMd.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _swatchColors.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final hex = _swatchColors[index];
                          final isSelected = draft.backgroundColor.toUpperCase() == hex.toUpperCase();

                          return GestureDetector(
                            onTap: () => draftNotifier.updateBackgroundColor(hex),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _hexToColor(hex),
                                border: Border.all(color: AppColors.black, width: 3),
                                boxShadow: isSelected
                                    ? const [BoxShadow(color: AppColors.black, offset: Offset(3, 3))]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: AppColors.black, size: 22)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Shape Color Swatches
                    Text(
                      'SHAPE / ACCENT COLOR',
                      style: AppTypography.headlineMd.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _swatchColors.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final hex = _swatchColors[index];
                          final isSelected = draft.shapeColor.toUpperCase() == hex.toUpperCase();

                          return GestureDetector(
                            onTap: () => draftNotifier.updateShapeColor(hex),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _hexToColor(hex),
                                border: Border.all(color: AppColors.black, width: 3),
                                boxShadow: isSelected
                                    ? const [BoxShadow(color: AppColors.black, offset: Offset(3, 3))]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: AppColors.black, size: 22)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Transform Section: Flip
                    Text(
                      'FLIP',
                      style: AppTypography.headlineMd.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['none', 'horizontal', 'vertical', 'both'].map((mode) {
                        final isSelected = draft.flip == mode;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => draftNotifier.updateFlip(mode),
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFFDE00) : Colors.white,
                                border: Border.all(color: AppColors.black, width: 3),
                              ),
                              child: Center(
                                child: Text(
                                  mode.toUpperCase(),
                                  style: AppTypography.labelSm.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Rotate Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ROTATE',
                          style: AppTypography.headlineMd.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.black,
                          ),
                        ),
                        Text(
                          '${draft.rotate}°',
                          style: AppTypography.bodyLg.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF0047FF),
                        inactiveTrackColor: const Color(0xFFE0E0E0),
                        thumbColor: const Color(0xFFFFDE00),
                        overlayColor: const Color(0xFFFFDE00).withValues(alpha: 0.3),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 3),
                      ),
                      child: Slider(
                        value: draft.rotate.toDouble(),
                        min: 0,
                        max: 360,
                        divisions: 36,
                        onChanged: (val) => draftNotifier.updateRotate(val.round()),
                      ),
                    ),

                    // Scale Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SCALE',
                          style: AppTypography.headlineMd.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.black,
                          ),
                        ),
                        Text(
                          '${draft.scale}%',
                          style: AppTypography.bodyLg.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.black,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF0047FF),
                        inactiveTrackColor: const Color(0xFFE0E0E0),
                        thumbColor: const Color(0xFFFFDE00),
                        overlayColor: const Color(0xFFFFDE00).withValues(alpha: 0.3),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 3),
                      ),
                      child: Slider(
                        value: draft.scale.toDouble(),
                        min: 50,
                        max: 200,
                        divisions: 30,
                        onChanged: (val) => draftNotifier.updateScale(val.round()),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Save Button (Fixed Footer)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              child: GestureDetector(
                onTap: () async {
                  await ref.read(profileProvider.notifier).saveAvatarOptions(draft);
                  if (context.mounted) {
                    context.pop();
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0047FF),
                    border: Border.all(color: AppColors.black, width: 3),
                    boxShadow: const [
                      BoxShadow(color: AppColors.black, offset: Offset(4, 4))
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'SAVE AVATAR',
                      style: AppTypography.headlineMd.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
