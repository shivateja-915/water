import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_data.dart';
import '../services/weather_service.dart';

class WeatherRepository {
  final WeatherService _weatherService = WeatherService();
  static const String _cacheKey = 'weather_cache';

  Future<WeatherData?> getWeather() async {
    // Try cache first
    final cached = await _getCachedWeather();
    if (cached != null && !cached.isStale) {
      return cached;
    }

    // Try to fetch fresh data
    try {
      final position = await _getCurrentPosition();
      if (position == null) return cached; // Return stale cache if no GPS

      final weather = await _weatherService.fetchWeather(
        position.latitude,
        position.longitude,
      );
      await _cacheWeather(weather);
      return weather;
    } catch (e) {
      // Return stale cached data on error
      return cached;
    }
  }

  Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  Future<WeatherData?> _getCachedWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached == null) return null;

    try {
      final json = jsonDecode(cached) as Map<String, dynamic>;
      return WeatherData.fromCache(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheWeather(WeatherData weather) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(weather.toCache()));
  }

  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
}
