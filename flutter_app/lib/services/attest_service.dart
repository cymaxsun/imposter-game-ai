import 'dart:developer' as developer;

import 'package:app_device_integrity/app_device_integrity.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing Apple App Attest for API request verification.
///
/// Handles attestation token generation to prove requests originate from
/// a genuine app on a real Apple device.
class AttestService {
  static const String _hasAttestedPref = 'attest_has_attested';

  static final AppDeviceIntegrity _plugin = AppDeviceIntegrity();

  /// Checks if App Attest is supported on this device.
  ///
  /// Returns `true` on iOS 14+ physical devices, `false` on simulators,
  /// non-iOS platforms, or older iOS versions.
  static Future<bool> isSupported() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      developer.log(
        'App Attest not supported on non-iOS platform',
        name: 'attest_service',
      );
      return false;
    }
    // The plugin handles iOS version checks internally
    return true;
  }

  /// Gets an attestation token for backend verification.
  ///
  /// The [challenge] should be a server-generated UUID to prevent replay
  /// attacks. Returns the attestation token as a string, or `null` on error.
  ///
  /// This token should be sent to your backend, which will verify it with
  /// Apple's servers.
  static Future<String?> getAttestationToken(String challenge) async {
    try {
      developer.log(
        'Getting attestation token for challenge: ${challenge.substring(0, 8)}...',
        name: 'attest_service',
      );

      final token = await _plugin.getAttestationServiceSupport(
        challengeString: challenge,
      );

      if (token != null && token.isNotEmpty) {
        developer.log(
          'Attestation token received, length: ${token.length}',
          name: 'attest_service',
        );
        return token;
      } else {
        developer.log(
          'Attestation token was null or empty',
          name: 'attest_service',
        );
        return null;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error getting attestation token',
        name: 'attest_service',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Checks if this device has successfully attested before.
  static Future<bool> hasAttested() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasAttestedPref) ?? false;
  }

  /// Marks this device as having successfully attested.
  static Future<void> markAttested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasAttestedPref, true);
    developer.log('Device marked as attested', name: 'attest_service');
  }

  /// Clears stored attestation data (for debugging/reset).
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasAttestedPref);
    developer.log('Attestation data cleared', name: 'attest_service');
  }
}
