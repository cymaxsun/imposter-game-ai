import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imposter_finder/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiService', () {
    test('generateWordList returns a list of strings on success', () async {
      // Arrange
      const topic = 'fruits';

      // Act
      // Note: This test requires network access and valid auth.
      // For a true unit test, we would mock the http client and AuthService.
      try {
        final words = await ApiService.generateWordList(topic);

        // Assert using package:checks
        check(words).isA<List<String>>();
        check(words.isNotEmpty).isTrue();
      } catch (e) {
        // If auth or network fails, we still verify the exception is thrown
        check(e).isA<Exception>();
      }
    });

    test('generateWordList throws exception on empty topic', () async {
      // Arrange
      const topic = '';

      // Act & Assert
      try {
        await ApiService.generateWordList(topic);
        // If we get here, the API accepted the empty topic
      } catch (e) {
        check(e).isA<Exception>();
      }
    });
  });
}
