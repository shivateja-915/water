import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

/// A beautiful undo overlay with a 5-second countdown timer
/// that auto-dismisses and supports undo action.
class UndoOverlay {
  static OverlayEntry? _currentEntry;
  static Timer? _currentTimer;

  /// Show the undo overlay with a countdown timer
  static void show(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    int durationSeconds = 3,
  }) {
    // Remove any existing overlay
    dismiss();

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _UndoOverlayWidget(
        message: message,
        durationSeconds: durationSeconds,
        onUndo: () {
          onUndo();
          dismiss();
        },
        onDismiss: () {
          dismiss();
        },
      ),
    );

    _currentEntry = entry;
    Overlay.of(context).insert(entry);
  }

  static void dismiss() {
    _currentTimer?.cancel();
    _currentTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _UndoOverlayWidget extends StatefulWidget {
  final String message;
  final int durationSeconds;
  final VoidCallback onUndo;
  final VoidCallback onDismiss;

  const _UndoOverlayWidget({
    required this.message,
    required this.durationSeconds,
    required this.onUndo,
    required this.onDismiss,
  });

  @override
  State<_UndoOverlayWidget> createState() => _UndoOverlayWidgetState();
}

class _UndoOverlayWidgetState extends State<_UndoOverlayWidget>
    with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;

    _animController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -80, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _animController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _animatedDismiss();
      }
    });
  }

  void _animatedDismiss() async {
    if (_isDismissing) return;
    _isDismissing = true;
    await _animController.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remainingSeconds / widget.durationSeconds;

    return Positioned(
      top: 55,
      left: AppSpacing.screenMargin,
      right: AppSpacing.screenMargin,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Dismissible(
            key: ValueKey(widget.message),
            direction: DismissDirection.up,
            onDismissed: (_) {
              widget.onDismiss();
            },
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null && details.primaryDelta! < -5) {
                  _animatedDismiss();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.inverseSurface,
                  border: Border.all(
                    color: AppColors.black,
                    width: AppSpacing.borderWidth,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.black,
                      offset: Offset(4, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.secondaryContainer,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.message,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.inverseOnSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onUndo,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.secondaryContainer,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'UNDO',
                                    style: AppTypography.labelSm.copyWith(
                                      color: AppColors.secondaryContainer,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          value: progress,
                                          strokeWidth: 2,
                                          color: AppColors.secondaryContainer,
                                          backgroundColor: AppColors.outline,
                                        ),
                                        Text(
                                          '$_remainingSeconds',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.secondaryContainer,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Progress bar at bottom
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 0.0),
                      duration: Duration(seconds: widget.durationSeconds),
                      builder: (context, value, _) {
                        return Container(
                          height: 3,
                          width: double.infinity,
                          color: AppColors.outline.withValues(alpha: 0.3),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: value,
                            child: Container(
                              color: AppColors.secondaryContainer,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
