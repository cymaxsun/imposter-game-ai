import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'attest_service.dart';
import 'subscription_service.dart';
import 'usage_service.dart';

/// Service for communicating with the word generation API.
///
/// Handles requests to the AWS Lambda backend.
/// Implements Session Binding:
/// 1. Handshake: Exchanges App Attest token for a Session JWT.
/// 2. Data Requests: Uses stored Session JWT.
/// 3. Auto-Renewal: Automatically retries handshake on 401 Unauthorized.
class ApiService {
  static const String _baseUrl =
      'https://jp1lu8qkcf.execute-api.us-east-1.amazonaws.com/Prod/api';
  static const String _generateWordsEndpoint = '$_baseUrl/generate-words';
  static const String _challengeEndpoint = '$_baseUrl/challenge';
  static const String _verifyDeviceEndpoint = '$_baseUrl/auth/verify-device';

  static http.Client _client = http.Client();
  static FlutterSecureStorage _storage = const FlutterSecureStorage();

  @visibleForTesting
  static set client(http.Client client) => _client = client;

  @visibleForTesting
  static set storage(FlutterSecureStorage storage) => _storage = storage;
  static const _sessionTokenKey = 'session_token';

  /// In-memory cache for the session token to reduce storage reads.
  static String? _currentSessionToken;

  /// Uses the device-generated attestation token to perform a secure handshake.
  /// The server will verify the token and return a session token.

  /// Generates a list of words for the given [topic].
  ///
  /// Uses a valid session token. If the token is invalid (401),
  /// triggers a handshake to get a new one and retries.
  static Future<List<String>> generateWordList(String topic) async {
    final usage = UsageService();
    final subscription = SubscriptionService();

    if (!usage.canMakeRequest && !subscription.isPremium) {
      // In a real app we might throw a specific exception to show Paywall
      print('Daily usage limit reached. Please upgrade to Premium.');
      throw Exception('Daily usage limit reached. Please upgrade to Premium.');
    }

    return _authenticatedRequest<List<String>>(
      (token) async {
        final uri = Uri.parse(_generateWordsEndpoint);
        final body = jsonEncode({'topic': topic});
        final bodyBytes = utf8.encode(body);

        final response = await _client.post(
          uri,
          headers: {
            'content-type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: bodyBytes,
        );

        return response;
      },
      (response) {
        final data = jsonDecode(response.body);
        if (data['words'] != null && data['words'] is List) {
          return List<String>.from(data['words']);
        }
        throw Exception('Invalid response format');
      },
    );
  }

  /// Helper for making authenticated requests with auto-retry logic.
  ///
  /// [requestBuilder] is a function that takes a token and returns a ``Future<Response>``.
  /// [responseParser] is a function that takes a Response and returns the detailed result T.
  static Future<T> _authenticatedRequest<T>(
    Future<http.Response> Function(String token) requestBuilder,
    T Function(http.Response response) responseParser,
  ) async {
    try {
      // 1. Get Token (Memory -> Storage -> Handshake)
      String token = await _getSessionToken();

      // 2. Make Request
      print('[api_service] Making authenticated request...');
      var response = await requestBuilder(token);

      // 3. Handle 401 (Auto-Renewal)
      if (response.statusCode == 401) {
        print('[api_service] Token expired/invalid (401). Renewing session...');
        await _clearSession();
        token = await _performSecureHandshake(); // Force new handshake
        response = await requestBuilder(token); // Retry
      }

      // 4. Handle Success
      if (response.statusCode == 200) {
        // Increment usage count on success
        if (!SubscriptionService().isPremium) {
          UsageService().incrementRequestCount();
        }
        return responseParser(response);
      }

      // 5. Handle Other Errors
      final body = response.body;
      print('[api_service] Request failed: ${response.statusCode} - $body');
      throw Exception('Request failed: ${response.statusCode} - $body');
    } catch (e, stack) {
      print('[api_service] Error in authenticated request: $e\n$stack');
      rethrow;
    }
  }

  /// Retrieves the current session token.
  ///
  /// Checks memory cache, then secure storage.
  /// If missing, performs a full secure handshake to get a new one.
  static Future<String> _getSessionToken() async {
    if (_currentSessionToken != null) return _currentSessionToken!;

    final storedToken = await _storage.read(key: _sessionTokenKey);
    // final storedToken = null; // Forced null for debug
    if (storedToken != null) {
      _currentSessionToken = storedToken;
      return storedToken;
    }

    return await _performSecureHandshake();
  }

  /// Clears the session token from memory and storage.
  static Future<void> _clearSession() async {
    _currentSessionToken = null;
    await _storage.delete(key: _sessionTokenKey);
  }

  /// Performs the heavy "Handshake" operation.
  ///
  /// 1. Get Challenge from Server.
  /// 2. Sign Challenge with App Attest (DeviceCheck).
  /// 3. Exchange Attestation for Session JWT.
  /// 4. Store JWT securely.
  static Future<String> _performSecureHandshake() async {
    print('[api_service] Starting Secure Handshake...');

    if (!await AttestService.isSupported()) {
      throw Exception('Device integrity checks not supported on this device.');
    }

    // A. Fetches a challenge nonce from the server for attestation.
    final challenge = await _getChallenge();
    if (challenge == null) {
      throw Exception('Failed to get security challenge from server');
    }

    // B. Use DeviceCheck (App Attest) to sign that nonce.
    final attestToken = await AttestService.getAttestationToken(challenge);
    if (attestToken == null) {
      throw Exception('Failed to generate device attestation token');
    }

    // C. Send the signed attestation object to verify-device.
    final uri = Uri.parse(_verifyDeviceEndpoint);
    final response = await _client.post(
      uri,
      headers: {
        'content-type': 'application/json',
        'X-App-Attest': attestToken, // Sending as header per previous design
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Handshake failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final token = data['token'] as String?;

    if (token == null) {
      throw Exception('Server did not return a session token');
    }

    // D. Store this token securely.
    await _storage.write(key: _sessionTokenKey, value: token);
    _currentSessionToken = token;

    print('[api_service] Handshake successful. Session established.');
    return token;
  }

  static Future<String?> _getChallenge() async {
    try {
      final response = await _client.get(Uri.parse(_challengeEndpoint));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['challenge'] as String?;
      }
      return null;
    } catch (e) {
      print('[api_service] Error fetching challenge: $e');
      return null;
    }
  }
}
