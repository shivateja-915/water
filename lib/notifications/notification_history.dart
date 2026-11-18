import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_constants.dart';
import 'notification_models.dart';

class NotificationHistoryNotifier
    extends StateNotifier<List<NotificationLogItem>> {
  NotificationHistoryNotifier() : super([]) {
    loadHistory();
  }

  /// Loads stored history from SharedPreferences
  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(NotificationConstants.prefsHistoryKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawJson);
        final list = decoded
            .map((item) =>
                NotificationLogItem.fromJson(item as Map<String, dynamic>))
            .toList();
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        state = list;
      }
    } catch (e) {
      debugPrint('${NotificationConstants.logTag} Failed to load notification history: $e');
    }
  }

  /// Saves current state list to SharedPreferences
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((item) => item.toJson()).toList();
      await prefs.setString(
          NotificationConstants.prefsHistoryKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('${NotificationConstants.logTag} Failed to save notification history: $e');
    }
  }

  /// Static helper to log a notification directly to SharedPreferences from anywhere (including static/background contexts)
  static Future<void> logToPrefs({
    required String title,
    required String body,
    required NotificationType type,
    required String channelId,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(NotificationConstants.prefsHistoryKey);
      List<NotificationLogItem> list = [];
      if (rawJson != null && rawJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawJson);
        list = decoded
            .map((item) =>
                NotificationLogItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      final newItem = NotificationLogItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        channelId: channelId,
        payload: payload,
        timestamp: DateTime.now(),
        isRead: false,
      );
      list = [newItem, ...list];
      final jsonList = list.map((item) => item.toJson()).toList();
      await prefs.setString(
          NotificationConstants.prefsHistoryKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('${NotificationConstants.logTag} Failed to static log to prefs: $e');
    }
  }

  /// Static helper to load history items directly from SharedPreferences
  static Future<List<NotificationLogItem>> loadHistoryFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(NotificationConstants.prefsHistoryKey);
      if (rawJson != null && rawJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawJson);
        return decoded
            .map((item) =>
                NotificationLogItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }


  /// Adds a new notification log item to history
  Future<void> addNotification({
    required String title,
    required String body,
    required NotificationType type,
    required String channelId,
    Map<String, dynamic>? payload,
  }) async {
    final newItem = NotificationLogItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      channelId: channelId,
      payload: payload,
      timestamp: DateTime.now(),
      isRead: false,
    );

    state = [newItem, ...state];
    await _saveState();
  }

  /// Marks a specific item as read
  Future<void> markAsRead(String id) async {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();
    await _saveState();
  }

  /// Marks a specific item as tapped
  Future<void> markAsTapped(String id) async {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true, isTapped: true);
      }
      return item;
    }).toList();
    await _saveState();
  }

  /// Marks all items as read
  Future<void> markAllAsRead() async {
    state = state.map((item) => item.copyWith(isRead: true)).toList();
    await _saveState();
  }

  /// Removes an item by ID
  Future<void> deleteItem(String id) async {
    state = state.where((item) => item.id != id).toList();
    await _saveState();
  }

  /// Clears all notification history
  Future<void> clearAll() async {
    state = [];
    await _saveState();
  }

  /// Unread count helper
  int get unreadCount => state.where((item) => !item.isRead).length;
}

final notificationHistoryProvider = StateNotifierProvider<
    NotificationHistoryNotifier, List<NotificationLogItem>>((ref) {
  return NotificationHistoryNotifier();
});
