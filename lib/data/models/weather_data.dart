class WeatherData {
  final double temperature;
  final double humidity;
  final int weatherCode;
  final String weatherDescription;
  final String? cityName;
  final DateTime fetchedAt;

  const WeatherData({
    required this.temperature,
    required this.humidity,
    required this.weatherCode,
    required this.weatherDescription,
    this.cityName,
    required this.fetchedAt,
  });

  factory WeatherData.fromOpenMeteo(Map<String, dynamic> json, {String? city}) {
    final current = json['current'] as Map<String, dynamic>? ??
        json['current_weather'] as Map<String, dynamic>? ??
        {};

    return WeatherData(
      temperature: (current['temperature_2m'] as num?)?.toDouble() ??
          (current['temperature'] as num?)?.toDouble() ??
          0.0,
      humidity:
          (current['relative_humidity_2m'] as num?)?.toDouble() ?? 50.0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ??
          (current['weathercode'] as num?)?.toInt() ??
          0,
      weatherDescription: _weatherCodeToDescription(
          (current['weather_code'] as num?)?.toInt() ??
              (current['weathercode'] as num?)?.toInt() ??
              0),
      cityName: city,
      fetchedAt: DateTime.now(),
    );
  }

  factory WeatherData.fromCache(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      weatherCode: json['weather_code'] as int,
      weatherDescription: json['weather_description'] as String,
      cityName: json['city_name'] as String?,
      fetchedAt: DateTime.parse(json['fetched_at'] as String),
    );
  }

  Map<String, dynamic> toCache() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'weather_code': weatherCode,
      'weather_description': weatherDescription,
      'city_name': cityName,
      'fetched_at': fetchedAt.toIso8601String(),
    };
  }

  bool get isStale {
    return DateTime.now().difference(fetchedAt).inHours >= 3;
  }

  /// Extra water recommendation based on temperature and humidity
  String get hydrationTip {
    if (temperature >= 35) {
      return '${temperature.round()}°C — Stay cool! Drink at least 750ml extra today.';
    } else if (temperature >= 30) {
      return '${temperature.round()}°C — It\'s hot! Drink extra water today.';
    } else if (humidity > 85) {
      return '${temperature.round()}°C — High humidity, stay hydrated!';
    } else if (temperature < 5) {
      return '${temperature.round()}°C — Cold day, but don\'t forget to hydrate!';
    }
    return '${temperature.round()}°C — $weatherDescription';
  }

  int get extraWaterMl {
    if (temperature >= 35) return 750;
    if (temperature >= 30) return 500;
    if (humidity > 85) return 250;
    return 0;
  }

  static String _weatherCodeToDescription(int code) {
    switch (code) {
      case 0:
        return 'Clear sky';
      case 1:
        return 'Mainly clear';
      case 2:
        return 'Partly cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 77:
        return 'Snow grains';
      case 80:
      case 81:
      case 82:
        return 'Rain showers';
      case 85:
      case 86:
        return 'Snow showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with hail';
      default:
        return 'Unknown';
    }
  }

  String get weatherIcon {
    if (weatherCode == 0) return '☀️';
    if (weatherCode <= 3) return '⛅';
    if (weatherCode <= 48) return '🌫️';
    if (weatherCode <= 55) return '🌦️';
    if (weatherCode <= 65) return '🌧️';
    if (weatherCode <= 77) return '❄️';
    if (weatherCode <= 82) return '🌧️';
    if (weatherCode <= 86) return '🌨️';
    return '⛈️';
  }
}
