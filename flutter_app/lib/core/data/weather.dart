import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:noop/core/state/prefs.dart';

/// A geocoded place the user can pin as their weather location.
class WeatherLocation {
  final String name; // human label, e.g. "Berlin, Germany"
  final double lat;
  final double lon;

  const WeatherLocation({required this.name, required this.lat, required this.lon});
}

/// The user's chosen weather location, seeded from persisted [Prefs]. Null means
/// automatic (coarse IP) mode. The settings search screen flips this state.
final weatherLocationProvider = StateProvider<WeatherLocation?>((ref) {
  final p = Prefs.instance;
  if (p.weatherLat == null || p.weatherLon == null) return null;
  return WeatherLocation(
    name: p.weatherPlace ?? '',
    lat: p.weatherLat!,
    lon: p.weatherLon!,
  );
});

/// A single current-conditions reading, fetched live and cached for the session.
class Weather {
  final double tempC;
  final int code; // WMO weather code
  final String place; // city / locality name

  const Weather({required this.tempC, required this.code, required this.place});

  /// Short human label for the WMO [code].
  String get label {
    final c = code;
    if (c == 0) return 'Clear';
    if (c <= 2) return 'Partly cloudy';
    if (c == 3) return 'Cloudy';
    if (c <= 48) return 'Fog';
    if (c <= 57) return 'Drizzle';
    if (c <= 67) return 'Rain';
    if (c <= 77) return 'Snow';
    if (c <= 82) return 'Showers';
    if (c <= 86) return 'Snow';
    return 'Storm';
  }
}

/// Live current weather with zero setup: derive an approximate location from the
/// device's public IP (no location permission), then read current conditions
/// from Open-Meteo (free, no API key). Both calls are HTTPS. Any failure returns
/// null so the header simply omits the weather chip — it never blocks the UI or
/// throws. Fetched once and cached for the app session by Riverpod.
final weatherProvider = FutureProvider<Weather?>((ref) async {
  try {
    final loc = ref.watch(weatherLocationProvider);
    if (loc != null) return await _fetchWeatherAt(loc.lat, loc.lon, loc.name);
    return await _fetchWeather();
  } catch (_) {
    return null;
  }
});

Future<Weather?> _fetchWeather() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
  try {
    // 1) Public IP → coarse location (city + lat/lon). Keyless, no permission.
    final loc = await _getJson(client, Uri.parse('https://ipapi.co/json/'));
    final lat = (loc?['latitude'] as num?)?.toDouble();
    final lon = (loc?['longitude'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;
    final place = (loc?['city'] as String?)?.trim() ?? '';

    // 2) Current conditions from Open-Meteo for that point.
    final wx = await _getJson(
      client,
      Uri.parse('https://api.open-meteo.com/v1/forecast'
          '?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code'),
    );
    final current = wx?['current'] as Map<String, dynamic>?;
    final temp = (current?['temperature_2m'] as num?)?.toDouble();
    final code = (current?['weather_code'] as num?)?.toInt();
    if (temp == null || code == null) return null;

    return Weather(tempC: temp, code: code, place: place);
  } finally {
    client.close(force: true);
  }
}

/// Current conditions for an exact, user-chosen point (skips the IP lookup).
Future<Weather?> _fetchWeatherAt(double lat, double lon, String place) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
  try {
    final wx = await _getJson(
      client,
      Uri.parse('https://api.open-meteo.com/v1/forecast'
          '?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code'),
    );
    final current = wx?['current'] as Map<String, dynamic>?;
    final temp = (current?['temperature_2m'] as num?)?.toDouble();
    final code = (current?['weather_code'] as num?)?.toInt();
    if (temp == null || code == null) return null;

    return Weather(tempC: temp, code: code, place: place);
  } finally {
    client.close(force: true);
  }
}

/// Geocode a free-text city query via Open-Meteo's keyless geocoding API.
/// Returns up to 10 candidate places; empty on blank query or any error.
Future<List<WeatherLocation>> searchLocations(String query) async {
  final q = query.trim();
  if (q.isEmpty) return [];
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
  try {
    final data = await _getJson(
      client,
      Uri.parse('https://geocoding-api.open-meteo.com/v1/search'
          '?name=${Uri.encodeQueryComponent(q)}&count=10&language=en&format=json'),
    );
    final results = data?['results'] as List<dynamic>? ?? [];
    final out = <WeatherLocation>[];
    for (final r in results) {
      if (r is! Map<String, dynamic>) continue;
      final lat = (r['latitude'] as num?)?.toDouble();
      final lon = (r['longitude'] as num?)?.toDouble();
      if (lat == null || lon == null) continue;
      final parts = [r['name'], r['admin1'], r['country']]
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      out.add(WeatherLocation(name: parts.join(', '), lat: lat, lon: lon));
    }
    return out;
  } catch (_) {
    return [];
  } finally {
    client.close(force: true);
  }
}

Future<Map<String, dynamic>?> _getJson(HttpClient client, Uri url) async {
  final req = await client.getUrl(url);
  final res = await req.close();
  if (res.statusCode != 200) return null;
  final body = await res.transform(utf8.decoder).join();
  final decoded = jsonDecode(body);
  return decoded is Map<String, dynamic> ? decoded : null;
}
