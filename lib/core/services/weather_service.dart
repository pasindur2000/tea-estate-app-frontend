import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

class WeatherService {
  Future<WeatherData?> fetchWeather(String location) async {
    debugPrint('[Weather] Fetching weather for location: "$location"');

    // Step 1: Geocode via Nominatim (OpenStreetMap) — handles Sri Lankan name
    // variants (e.g. Rathnapura / Ratnapura) better than Open-Meteo geocoding.
    // Appending "Sri Lanka" narrows results for ambiguous city names.
    final query = Uri.encodeComponent('$location Sri Lanka');
    final geoUri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
    );
    debugPrint('[Weather] Geocoding URL: $geoUri');

    http.Response geoRes;
    try {
      geoRes = await http
          .get(geoUri, headers: {'User-Agent': 'TeaEstateApp/1.0'})
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[Weather] Geocoding request failed: $e');
      return null;
    }

    debugPrint('[Weather] Geocoding status: ${geoRes.statusCode}');
    debugPrint('[Weather] Geocoding body: ${geoRes.body}');

    List<dynamic> geoList;
    try {
      geoList = jsonDecode(geoRes.body) as List<dynamic>;
    } catch (e) {
      debugPrint('[Weather] Failed to parse geocoding response: $e');
      return null;
    }

    if (geoList.isEmpty) {
      debugPrint('[Weather] No geocoding results found for "$location"');
      return null;
    }

    final lat = double.parse(geoList[0]['lat'] as String);
    final lon = double.parse(geoList[0]['lon'] as String);
    debugPrint('[Weather] Coordinates: lat=$lat, lon=$lon');

    // Step 2: Fetch weather
    final weatherUri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,apparent_temperature,wind_speed_10m,'
      'precipitation,rain,cloud_cover,weather_code'
      '&wind_speed_unit=kmh',
    );
    debugPrint('[Weather] Weather URL: $weatherUri');

    http.Response weatherRes;
    try {
      weatherRes =
          await http.get(weatherUri).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[Weather] Weather request failed: $e');
      return null;
    }

    debugPrint('[Weather] Weather status: ${weatherRes.statusCode}');
    debugPrint('[Weather] Weather body: ${weatherRes.body}');

    Map<String, dynamic> weatherJson;
    try {
      weatherJson = jsonDecode(weatherRes.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[Weather] Failed to parse weather response: $e');
      return null;
    }

    final current = weatherJson['current'] as Map<String, dynamic>?;
    if (current == null) {
      debugPrint('[Weather] No "current" key in weather response');
      return null;
    }

    try {
      final data = WeatherData(
        temperature: (current['temperature_2m'] as num).toDouble(),
        apparentTemperature:
            (current['apparent_temperature'] as num).toDouble(),
        windSpeed: (current['wind_speed_10m'] as num).toDouble(),
        precipitation: (current['precipitation'] as num).toDouble(),
        rain: (current['rain'] as num).toDouble(),
        cloudCover: (current['cloud_cover'] as num).toInt(),
        weatherCode: current['weather_code'] as int,
      );
      debugPrint('[Weather] Success — ${data.temperature}°C, ${data.conditionLabel}, wind ${data.windSpeed} km/h, rain ${data.rain} mm');
      return data;
    } catch (e) {
      debugPrint('[Weather] Failed to build WeatherData: $e');
      debugPrint('[Weather] current keys: ${current.keys.toList()}');
      debugPrint('[Weather] current values: $current');
      return null;
    }
  }
}
