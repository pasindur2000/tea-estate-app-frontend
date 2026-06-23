class WeatherData {
  final double temperature;
  final double apparentTemperature;
  final double windSpeed; // km/h
  final double precipitation; // mm
  final double rain; // mm
  final int cloudCover; // %
  final int weatherCode; // WMO code

  const WeatherData({
    required this.temperature,
    required this.apparentTemperature,
    required this.windSpeed,
    required this.precipitation,
    required this.rain,
    required this.cloudCover,
    required this.weatherCode,
  });

  String get conditionLabel {
    if (weatherCode == 0) return 'Clear Sky';
    if (weatherCode == 1) return 'Mainly Clear';
    if (weatherCode == 2) return 'Partly Cloudy';
    if (weatherCode == 3) return 'Overcast';
    if (weatherCode <= 48) return 'Foggy';
    if (weatherCode <= 55) return 'Drizzle';
    if (weatherCode <= 65) return 'Rainy';
    if (weatherCode <= 75) return 'Snowy';
    if (weatherCode <= 82) return 'Rain Showers';
    if (weatherCode <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  bool get isClear => weatherCode == 0 || weatherCode == 1;
  bool get isCloudy => weatherCode == 2 || weatherCode == 3;
  bool get isFoggy => weatherCode >= 45 && weatherCode <= 48;
  bool get isRaining =>
      (weatherCode >= 51 && weatherCode <= 82) || weatherCode >= 95;
  bool get isThunderstorm => weatherCode >= 95;
}
