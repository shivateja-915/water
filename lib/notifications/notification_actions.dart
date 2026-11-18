import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/models/hydration_log.dart';
import '../data/services/supabase_service.dart';

import 'notification_constants.dart';
import 'notification_scheduler.dart';
import 'notification_service.dart';

class NotificationActions {
  NotificationActions._();

  /// Main action dispatcher called when user taps an action button on a notification.
  static Future<void> handleAction(String actionId, String? payloadStr) async {
    debugPrint(
        '${NotificationConstants.logTag} ⚡ Handling Notification Action: $actionId (Payload: $payloadStr)');


    switch (actionId) {
      case NotificationConstants.actionDrinkNow:
      case NotificationConstants.actionDrink250ml:
        await _handleDrinkAction(250);
        break;

      case NotificationConstants.actionDrink500ml:
        await _handleDrinkAction(500);
        break;

      case NotificationConstants.actionSnooze5m:
        await _handleSnoozeAction(5);
        break;

      case NotificationConstants.actionSnooze15m:
        await _handleSnoozeAction(15);
        break;

      case NotificationConstants.actionSnooze30m:
        await _handleSnoozeAction(30);
        break;

      case NotificationConstants.actionDismiss:
        debugPrint('${NotificationConstants.logTag} Notification dismissed by user action.');
        break;

      case NotificationConstants.actionOpenStats:
      case NotificationConstants.actionOpenSettings:
        // Handled via rootNavigatorKey navigation in NotificationManager
        break;

      default:
        debugPrint('${NotificationConstants.logTag} Unknown action ID: $actionId');
    }
  }

  /// Handles "Drink Now" / "Drink 250ml" / "Drink 500ml" quick action from notification shade
  static Future<void> _handleDrinkAction(int amountMl) async {
    if (SupabaseService.isInitialized) {
      try {
        final client = SupabaseService.client;
        final user = client.auth.currentUser;

        if (user != null) {
          final log = HydrationLog(
            id: const Uuid().v4(),
            userId: user.id,
            amountMl: amountMl,
            hydratedMl: amountMl,
            loggedAt: DateTime.now(),
          );

          await client.from('hydration_logs').insert(log.toJson());
          debugPrint(
              '${NotificationConstants.logTag} 💧 Quick drink of ${amountMl}ml logged to Supabase for user ${user.id}');
        }
      } catch (e) {
        debugPrint('${NotificationConstants.logTag} Failed to log quick drink: $e');
      }
    }


  }

  /// Handles Snooze action (5, 15, or 30 mins) without touching existing schedule
  static Future<void> _handleSnoozeAction(int minutes) async {
    try {
      final snoozeTarget = NotificationScheduler.computeSnoozeTarget(minutes);
      await NotificationService.scheduleSnoozeNotification(
        targetDateTime: snoozeTarget,
        minutes: minutes,
      );
      debugPrint(
          '${NotificationConstants.logTag} ⏰ Snooze scheduled for $minutes minutes at ${snoozeTarget.toLocal()}');
    } catch (e) {
      debugPrint('${NotificationConstants.logTag} Failed to schedule snooze notification: $e');
    }
  }
}
