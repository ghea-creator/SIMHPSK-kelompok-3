import 'package:flutter/foundation.dart';
import 'api_config_platform_stub.dart'
    if (dart.library.io) 'api_config_platform_io.dart';

class ApiConfig {
  // Untuk web, ambil host yang sama dengan browser agar tidak hardcode ke 127.0.0.1
  static String get serverIp {
    if (kIsWeb) {
      final host = Uri.base.host;
      return host.isNotEmpty ? host : '127.0.0.1';
    }
    return platformServerIp;
  }

  static const String port = '8000';
  
  // Di sini kita kunci http:// nya biar gak hilang atau typo lagi
  static String get baseUrl => 'http://$serverIp:$port/api';

  // Endpoint helper bawaan proyekmu
  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get registerEndpoint => '$baseUrl/auth/register';
  static String get dashboardEndpoint => '$baseUrl/dashboard';
}