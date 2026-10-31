import 'package:flutter/foundation.dart';

class LocalServerConfig {
  static const _configuredUrl = String.fromEnvironment('REAYA_SERVER_URL');
  static const token = String.fromEnvironment('REAYA_SERVER_TOKEN');

  static String get baseUrl {
    if (_configuredUrl.isNotEmpty) return _configuredUrl;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://127.0.0.1:8787',
      _ => 'http://127.0.0.1:8787',
    };
  }
}
