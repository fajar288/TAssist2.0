// test/avatar_helper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tassist/core/api_config.dart';
import 'package:tassist/core/helpers/avatar_helper.dart';

void main() {
  group('AvatarHelper.getAvatarUrl', () {
    test('falls back to the bundled default avatar when no photo is set', () {
      expect(
        AvatarHelper.getAvatarUrl(avatar: null),
        AvatarHelper.defaultAvatar,
      );
      expect(
        AvatarHelper.getAvatarUrl(avatar: ''),
        AvatarHelper.defaultAvatar,
      );
      expect(
        AvatarHelper.getAvatarUrl(avatar: '   '),
        AvatarHelper.defaultAvatar,
      );
      expect(AvatarHelper.defaultAvatar, 'assets/images/default_avatar.jpeg');
    });

    test('honours an explicit fallback', () {
      expect(
        AvatarHelper.getAvatarUrl(
          avatar: null,
          fallback: 'assets/images/custom.png',
        ),
        'assets/images/custom.png',
      );
    });

    test('passes a full http(s) URL through untouched', () {
      const url = 'https://cdn.example.com/avatars/a.png';

      expect(AvatarHelper.getAvatarUrl(avatar: url), url);
      expect(
        AvatarHelper.getAvatarUrl(avatar: '  $url  '),
        url,
      );
    });

    test('strips a leading /storage/ prefix before building the URL', () {
      final result =
          AvatarHelper.getAvatarUrl(avatar: '/storage/avatars/a.png');

      expect(result, '${ApiConfig.serverUrl}/api/v1/avatar/avatars/a.png');
      expect(result, isNot(contains('storage/avatars')));
    });

    test('strips a leading storage/ prefix before building the URL', () {
      expect(
        AvatarHelper.getAvatarUrl(avatar: 'storage/avatars/a.png'),
        '${ApiConfig.serverUrl}/api/v1/avatar/avatars/a.png',
      );
    });

    test('builds an absolute URL for a non-empty relative path', () {
      final result = AvatarHelper.getAvatarUrl(avatar: 'avatars/a.png');

      expect(result, '${ApiConfig.serverUrl}/api/v1/avatar/avatars/a.png');
      expect(Uri.parse(result).isAbsolute, isTrue);
      expect(Uri.parse(result).host, Uri.parse(ApiConfig.serverUrl).host);
    });

    test('normalises a leading slash on the stored path', () {
      expect(
        AvatarHelper.getAvatarUrl(avatar: '/avatars/a.png'),
        '${ApiConfig.serverUrl}/api/v1/avatar/avatars/a.png',
      );
    });
  });

  group('AvatarHelper.hasAvatar', () {
    test('is false for null, empty and whitespace-only values', () {
      expect(AvatarHelper.hasAvatar(null), isFalse);
      expect(AvatarHelper.hasAvatar(''), isFalse);
      expect(AvatarHelper.hasAvatar('  '), isFalse);
    });

    test('is true for any non-blank value', () {
      expect(AvatarHelper.hasAvatar('avatars/a.png'), isTrue);
    });
  });
}
