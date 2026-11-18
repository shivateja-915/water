import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/reminder_config.dart';
import 'notification_repository.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';

/// In-app banner notification channel.
///
/// Runs a periodic timer that checks if the current minute matches
/// any computed reminder time. When matched, shows a Material banner.
///
/// This is the ONLY notification channel that works on Web.
/// On Android, it provides a backup in-app notification alongside
/// the OS notification.
class ForegroundReminderTicker {
  ForegroundReminderTicker._();

  static Timer? _timer;
  static GlobalKey<NavigatorState>? _navigatorKey;
  static ReminderConfig Function()? _getConfig;
  static final Set<String> _firedThisMinute = {};

  static bool get isRunning => _timer != null && _timer!.isActive;

  /// Start the ticker.
  static void start({
    required GlobalKey<NavigatorState> navigatorKey,
    required ReminderConfig Function() getCurrentConfig,
  }) {
    _navigatorKey = navigatorKey;
    _getConfig = getCurrentConfig;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
    debugPrint('ForegroundReminderTicker: started (checking every 30s)');
  }

  /// Stop the ticker.
  static void stop() {
    _timer?.cancel();
    _timer = null;
    debugPrint('ForegroundReminderTicker: stopped');
  }

  static void _tick() {
    final config = _getConfig?.call();
    if (config == null || !config.enabled) return;

    final now = TimeOfDay.now();
    final nowKey = '${now.hour}:${now.minute}';

    // Already fired for this minute? Skip.
    if (_firedThisMinute.contains(nowKey)) return;

    // Clean old entries — keep only the current minute
    _firedThisMinute.removeWhere((k) => k != nowKey);

    final times = NotificationRepository.computeTimes(config);
    for (final t in times) {
      if (t.hour == now.hour && t.minute == now.minute) {
        _firedThisMinute.add(nowKey);
        showBannerNow(
          title: '💧 Time to Hydrate!',
          body: 'Stay hydrated and keep your body refreshed.',
        );
        debugPrint('ForegroundReminderTicker: banner shown at $nowKey');
        break;
      }
    }
  }

  /// Show a banner notification NOW. Can be called externally for tests.
  static void showBannerNow({
    required String title,
    required String body,
  }) {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      debugPrint('ForegroundReminderTicker: no context available for banner');
      return;
    }

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _BannerWidget(
        title: title,
        body: body,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);

    // Auto-dismiss after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      try {
        entry.remove();
      } catch (_) {}
    });
  }
}

class _BannerWidget extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onDismiss;

  const _BannerWidget({
    required this.title,
    required this.body,
    required this.onDismiss,
  });

  @override
  State<_BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<_BannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: widget.onDismiss,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                border: Border.all(color: AppColors.black, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.black,
                    offset: Offset(4, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('💧', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.body,
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: AppColors.black, width: 2),
                      ),
                      child: const Icon(Icons.close,
                          size: 16, color: AppColors.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
