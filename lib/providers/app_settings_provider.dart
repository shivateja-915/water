import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class AppSettingsState {
  final bool notificationsEnabled;
  final bool locationEnabled;

  const AppSettingsState({
    required this.notificationsEnabled,
    required this.locationEnabled,
  });

  AppSettingsState copyWith({
    bool? notificationsEnabled,
    bool? locationEnabled,
  }) {
    return AppSettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationEnabled: locationEnabled ?? this.locationEnabled,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettingsState> with WidgetsBindingObserver {
  static const _notificationsKey = 'app_settings_notifications_enabled';
  StreamSubscription? _serviceStatusSubscription;

  AppSettingsNotifier()
      : super(const AppSettingsState(
          notificationsEnabled: true,
          locationEnabled: false,
        )) {
    _loadSettings();
    _initLocationSync();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncLocationState();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getBool(_notificationsKey) ?? true;
      state = state.copyWith(notificationsEnabled: notifications);
    } catch (_) {}
  }

  Future<void> _initLocationSync() async {
    await syncLocationState();
    if (!kIsWeb) {
      _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen((status) {
        syncLocationState();
      });
    }
  }

  Future<void> syncLocationState() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (state.locationEnabled != false) {
          state = state.copyWith(locationEnabled: false);
        }
        return;
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      bool hasAccess = permission == LocationPermission.whileInUse || permission == LocationPermission.always;
      
      if (state.locationEnabled != hasAccess) {
        state = state.copyWith(locationEnabled: hasAccess);
      }
    } catch (_) {
      state = state.copyWith(locationEnabled: false);
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsKey, enabled);
    } catch (_) {}
  }

  // Backwards compatibility if needed, though mostly handled by syncLocationState
  Future<void> setLocationEnabled(bool enabled) async {
    state = state.copyWith(locationEnabled: enabled);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serviceStatusSubscription?.cancel();
    super.dispose();
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  return AppSettingsNotifier();
});
