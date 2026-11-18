import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../data/models/weather_data.dart';
import '../data/repositories/weather_repository.dart';
import 'app_settings_provider.dart';

final weatherRepositoryProvider =
    Provider<WeatherRepository>((ref) => WeatherRepository());

class WeatherResult {
  final WeatherData? data;
  final bool isDeviceLocationOff;

  const WeatherResult({this.data, this.isDeviceLocationOff = false});
}

final weatherProvider =
    StateNotifierProvider<WeatherNotifier, AsyncValue<WeatherResult>>(
        (ref) {
  final repo = ref.read(weatherRepositoryProvider);
  final locationEnabled = ref.watch(appSettingsProvider).locationEnabled;
  return WeatherNotifier(repo, locationEnabled);
});

class WeatherNotifier extends StateNotifier<AsyncValue<WeatherResult>> {
  final WeatherRepository _repo;
  final bool _locationEnabled;

  WeatherNotifier(this._repo, this._locationEnabled)
      : super(const AsyncValue.loading()) {
    loadWeather();
  }

  Future<bool> _checkDeviceLocationOff() async {
    if (!_locationEnabled) return true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return true;
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.denied || permission == LocationPermission.deniedForever;
    } catch (_) {
      return true;
    }
  }

  Future<void> loadWeather() async {
    state = const AsyncValue.loading();
    try {
      final isOff = await _checkDeviceLocationOff();
      final weather = await _repo.getWeather();
      state = AsyncValue.data(WeatherResult(data: weather, isDeviceLocationOff: isOff));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    try {
      final isOff = await _checkDeviceLocationOff();
      final weather = await _repo.getWeather();
      state = AsyncValue.data(WeatherResult(data: weather, isDeviceLocationOff: isOff));
    } catch (_) {
      // Keep current state on refresh failure
    }
  }
}

