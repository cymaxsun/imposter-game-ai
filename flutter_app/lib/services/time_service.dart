import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;

/// Service to fetch network time from a trusted NTP API.
/// Prevents users from bypassing daily limits by changing device time.
class TimeService {
  static final TimeService _instance = TimeService._internal();

  factory TimeService() {
    return _instance;
  }

  TimeService._internal();

  static const String _timeApiUrl =
      'https://worldtimeapi.org/api/timezone/America/New_York';
  static const Duration _cacheValidity = Duration(seconds: 60);

  DateTime? _cachedNetworkTime;
  DateTime? _cachedAtDeviceTime;

  /// Fetches the current time from a trusted network source.
  /// Returns null if the network request fails (offline, timeout, etc.).
  Future<DateTime?> getNetworkTime() async {
    // Return cached time if still valid
    if (_cachedNetworkTime != null && _cachedAtDeviceTime != null) {
      final elapsed = DateTime.now().difference(_cachedAtDeviceTime!);
      if (elapsed < _cacheValidity) {
        // Adjust cached time by elapsed duration
        return _cachedNetworkTime!.add(elapsed);
      }
    }

    try {
      final response = await http
          .get(Uri.parse(_timeApiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dateTimeString = data['datetime'] as String;
        // Parse ISO 8601 format: "2024-01-24T15:30:00.123456-05:00"
        final networkTime = DateTime.parse(dateTimeString);

        // Cache the result
        _cachedNetworkTime = networkTime;
        _cachedAtDeviceTime = DateTime.now();

        developer.log(
          'Network time fetched: $networkTime',
          name: 'time_service',
        );
        return networkTime;
      } else {
        developer.log(
          'Time API returned status ${response.statusCode}',
          name: 'time_service',
        );
        return null;
      }
    } catch (e) {
      developer.log('Failed to fetch network time: $e', name: 'time_service');
      return null;
    }
  }

  /// Convenience method to get network time as a TZDateTime in EST.
  Future<tz.TZDateTime?> getNetworkTimeEST() async {
    final networkTime = await getNetworkTime();
    if (networkTime == null) return null;
    return tz.TZDateTime.from(networkTime, tz.getLocation('America/New_York'));
  }

  /// Clears the cached network time (for testing).
  void clearCache() {
    _cachedNetworkTime = null;
    _cachedAtDeviceTime = null;
  }
}
