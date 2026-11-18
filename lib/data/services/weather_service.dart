import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _geocodeUrl = 'https://nominatim.openstreetmap.org/reverse';

  Future<WeatherData> fetchWeather(double lat, double lon) async {
    // Fetch weather data
    final url = Uri.parse(
      '$_baseUrl?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,weather_code',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch weather: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // Fetch city name via reverse geocoding
    String? cityName;
    try {
      cityName = await _reverseGeocode(lat, lon);
    } catch (_) {
      // City name is optional, don't fail if geocoding fails
    }

    return WeatherData.fromOpenMeteo(json, city: cityName);
  }

  Future<String?> _reverseGeocode(double lat, double lon) async {
    final url = Uri.parse(
      '$_geocodeUrl?format=json&lat=$lat&lon=$lon&zoom=10',
    );

    final response = await http.get(url, headers: {
      'User-Agent': 'Siply/1.0',
    });

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final address = json['address'] as Map<String, dynamic>?;
      if (address != null) {
        return address['city'] as String? ??
            address['town'] as String? ??
            address['village'] as String? ??
            address['county'] as String?;
      }
    }
    return null;
  }
}
