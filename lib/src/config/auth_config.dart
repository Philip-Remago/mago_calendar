import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthConfig {
  static String microsoftClientId = _read('MICROSOFT_CLIENT_ID');
  static String microsoftClientSecret = _read('MICROSOFT_CLIENT_SECRET');

  static String googleWebClientId = _read('GOOGLE_WEB_CLIENT_ID');
  static String googleAndroidClientId = _read('GOOGLE_ANDROID_CLIENT_ID');
  static String googleWindowsClientId = _read('GOOGLE_WINDOWS_CLIENT_ID');
  static String googleWindowsClientSecret = _read(
    'GOOGLE_WINDOWS_CLIENT_SECRET',
  );

  static String googleClientIdForPlatform() {
    if (kIsWeb) {
      return googleWebClientId;
    }
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return googleWindowsClientId;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return googleAndroidClientId;
    }
    return googleWebClientId;
  }

  static String? googleClientSecretForPlatform() {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return googleWindowsClientSecret.isEmpty
          ? null
          : googleWindowsClientSecret;
    }
    return null;
  }

  static String microsoftRedirectUri() {
    if (kIsWeb) {
      return '${Uri.base.origin}/auth.html';
    }
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return 'http://localhost:43823/';
    }
    return 'com.calendar.connect:/oauth2redirect';
  }

  static String microsoftCallbackScheme() {
    if (kIsWeb) {
      return Uri.base.scheme;
    }
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return 'http';
    }
    return 'com.calendar.connect';
  }

  static String _read(String key) {
    const defines = <String, String>{
      'MICROSOFT_CLIENT_ID': String.fromEnvironment('MICROSOFT_CLIENT_ID'),
      'MICROSOFT_CLIENT_SECRET': String.fromEnvironment(
        'MICROSOFT_CLIENT_SECRET',
      ),
      'GOOGLE_WEB_CLIENT_ID': String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
      'GOOGLE_ANDROID_CLIENT_ID': String.fromEnvironment(
        'GOOGLE_ANDROID_CLIENT_ID',
      ),
      'GOOGLE_WINDOWS_CLIENT_ID': String.fromEnvironment(
        'GOOGLE_WINDOWS_CLIENT_ID',
      ),
      'GOOGLE_WINDOWS_CLIENT_SECRET': String.fromEnvironment(
        'GOOGLE_WINDOWS_CLIENT_SECRET',
      ),
    };

    final defined = defines[key];
    if (defined != null && defined.isNotEmpty) {
      return defined;
    }

    // 2. Fallback to dotenv (local development)
    try {
      final value = dotenv.env[key];
      if (value != null && value.isNotEmpty) {
        return value;
      }
    } catch (_) {
      // dotenv not initialized - return empty string
    }
    return '';
  }
}
