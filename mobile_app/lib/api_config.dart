class ApiConfig {
  // Kita bypass paksa biar langsung ngebaca IP Wi-Fi laptop kamu
  static String get serverIp => '127.0.0.1'; 

  static const String port = '';
  
  // Di sini kita kunci http:// nya biar gak hilang atau typo lagi
  static String get baseUrl => 'http://$serverIp/pertanian_kentang/public/api';

  // Endpoint helper bawaan proyekmu
  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get registerEndpoint => '$baseUrl/auth/register';
  static String get dashboardEndpoint => '$baseUrl/dashboard';
}