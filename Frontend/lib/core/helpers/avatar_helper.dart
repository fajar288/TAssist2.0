import '../api_config.dart';

class AvatarHelper {
  const AvatarHelper._();

  static String get baseUrl => ApiConfig.baseUrl;

  /// Avatar bawaan jika user belum memiliki foto.
  static const String defaultAvatar = 'assets/images/default_avatar.jpeg';

  static String getAvatarUrl({
    required String? avatar,
    String? fallback,
  }) {
    if (avatar == null || avatar.trim().isEmpty) {
      return fallback ?? defaultAvatar;
    }

    String value = avatar.trim();

    // 1. Jika sudah merupakan URL penuh, biarkan saja
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    // 2. Bersihkan embel-embel "storage" jika terlanjur dikirim oleh backend
    if (value.startsWith('/storage/')) {
      value = value.replaceFirst('/storage/', '');
    } else if (value.startsWith('storage/')) {
      value = value.replaceFirst('storage/', '');
    } else if (value.startsWith('/')) {
      value = value.substring(1);
    }

    // Saat ini value pasti dalam kondisi bersih murni (contoh: "avatars/xxx.jpg")
    
    // 3. Paksa arahkan ke endpoint anti-CORS Laravel
    value = 'api/v1/image/$value';

    // 4. Pastikan serverUrl tidak diakhiri slash ganda
    String serverUrl = ApiConfig.serverUrl;
    if (serverUrl.endsWith('/')) {
      serverUrl = serverUrl.substring(0, serverUrl.length - 1);
    }

    // 5. Rakit menjadi URL penuh
    // Hasil akhir: http://127.0.0.1:8000/api/v1/image/avatars/xxx.jpg
    return '$serverUrl/$value';
  }

  static bool hasAvatar(String? avatar) {
    return avatar != null && avatar.trim().isNotEmpty;
  }
}