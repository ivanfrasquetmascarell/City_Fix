import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class Constants {
  // Cuando se usa el emulador de Android, localhost es 10.0.2.2
  // En caso de iOS o Web, es localhost normal (127.0.0.1 o localhost)
  static String get apiUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:3000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    } else {
      return 'http://127.0.0.1:3000';
    }
  }

  // Claves de SharedPreferences
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
}
