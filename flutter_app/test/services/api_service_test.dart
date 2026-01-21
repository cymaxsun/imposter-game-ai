import 'dart:convert';
import 'package:checks/checks.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:imposter_finder/services/api_service.dart';
import 'package:mocktail/mocktail.dart';

class MockClient extends Mock implements http.Client {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('ApiService', () {
    late MockClient client;
    late MockSecureStorage storage;

    setUp(() {
      client = MockClient();
      storage = MockSecureStorage();
      ApiService.client = client;
      ApiService.storage = storage;

      // Register fallback values
      registerFallbackValue(Uri());
    });

    group('generateWordList', () {
      test('returns word list on success', () async {
        // Arrange
        when(
          () => storage.read(key: any(named: 'key')),
        ).thenAnswer((_) async => 'valid_token');
        when(
          () => client.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => http.Response(
            jsonEncode({
              'words': ['apple', 'banana'],
            }),
            200,
          ),
        );

        // Act
        final words = await ApiService.generateWordList('fruit');

        // Assert
        check(words).length.equals(2);
        check(words).contains('apple');
      });

      test('throws exception on API error', () async {
        // Arrange
        when(
          () => storage.read(key: any(named: 'key')),
        ).thenAnswer((_) async => 'valid_token');
        when(
          () => client.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => http.Response('Server Error', 500));

        // Act & Assert
        await check(ApiService.generateWordList('fruit')).throws<Exception>();
      });
    });
  });
}
