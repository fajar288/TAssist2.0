// test/api_config_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tassist/core/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('baseUrl is the server URL plus the v1 API prefix', () {
      expect(ApiConfig.baseUrl, '${ApiConfig.serverUrl}/api/v1');
    });

    test('storageUrl is the server URL plus /storage', () {
      expect(ApiConfig.storageUrl, '${ApiConfig.serverUrl}/storage');
    });

    test('serverUrl is an absolute http(s) URL without a trailing slash', () {
      final uri = Uri.parse(ApiConfig.serverUrl);

      expect(uri.hasScheme, isTrue);
      expect(uri.scheme, anyOf('http', 'https'));
      expect(uri.host, isNotEmpty);
      expect(ApiConfig.serverUrl, isNot(endsWith('/')));
    });

    test('every derived URL parses and keeps the server origin', () {
      final server = Uri.parse(ApiConfig.serverUrl);
      final base = Uri.parse(ApiConfig.baseUrl);
      final storage = Uri.parse(ApiConfig.storageUrl);

      expect(base.origin, server.origin);
      expect(storage.origin, server.origin);
      expect(base.path, '/api/v1');
      expect(storage.path, '/storage');
    });

    test('the Google OAuth client ids are configured', () {
      expect(ApiConfig.googleClientId, isNotEmpty);
      expect(ApiConfig.googleServerClientId, ApiConfig.googleClientId);
      expect(ApiConfig.googleClientId, endsWith('.apps.googleusercontent.com'));
    });
  });
}
