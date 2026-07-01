import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../api_config.dart';
import '../models/user.dart';
import '../models/dashboard.dart';
import '../models/harvest.dart';
import '../models/stock.dart';
import '../models/sale.dart';
import '../models/season.dart';
import '../models/cost.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  String? getAuthToken() {
    return _authToken;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Map<String, String> _getHeaders({bool includeAuth = true, bool forMultipart = false}) {
    final headers = {
      'Accept': 'application/json',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    };
    if (!forMultipart) {
      headers['Content-Type'] = 'application/json';
    }
    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Map<String, dynamic> _decodeApiResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data is Map<String, dynamic>) {
          return data;
        }
        throw Exception('Respons API tidak valid.');
      }

      if (data is Map<String, dynamic>) {
        throw Exception(data['message'] ?? 'Server error ${response.statusCode}');
      }
      throw Exception('Server error ${response.statusCode}');
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Respons JSON tidak valid: ${e.message}');
      }
      throw Exception(e.toString());
    }
  }

  // ==================== AUTH ====================

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/login'),
            headers: _getHeaders(includeAuth: false),
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['data']['token'] as String?;
        if (token != null) {
          setAuthToken(token);
        }
        return {
          'success': true,
          'user': User.fromJson(data['data']['user'] ?? {}),
          'token': token,
        };
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login gagal'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Translate raw Laravel validation messages to Indonesian
  String _translateValidationMessage(String raw) {
    if (raw.contains('validation.min.string') || raw.contains('min.string')) {
      return 'Password minimal 8 karakter';
    }
    if (raw.contains('validation.confirmed') || raw.contains('confirmed')) {
      return 'Konfirmasi password tidak cocok';
    }
    if (raw.contains('validation.unique') || raw.contains('unique')) {
      return 'Email sudah terdaftar, gunakan email lain';
    }
    if (raw.contains('validation.email') || raw.contains('email')) {
      return 'Format email tidak valid';
    }
    if (raw.contains('validation.required') || raw.contains('required')) {
      return 'Semua field harus diisi';
    }
    return raw;
  }

  Future<Map<String, dynamic>> register({
    required String farmName,
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/register'),
            headers: _getHeaders(includeAuth: false),
            body: jsonEncode({
              'farm_name': farmName,
              'name': name,
              'email': email,
              'phone': phone,
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      String message = data['message'] ?? 'Registrasi gagal';

      if (data['errors'] != null && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        final List<String> errorMessages = [];
        for (var key in errors.keys) {
          final value = errors[key];
          if (value is List && value.isNotEmpty) {
            errorMessages.add(_translateValidationMessage(value.first.toString()));
          }
        }
        if (errorMessages.isNotEmpty) {
          message = errorMessages.join(', ');
        }
      } else {
        message = _translateValidationMessage(message);
      }

      return {
        'success': response.statusCode == 201 && data['success'] == true,
        'message': message,
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }


  Future<void> logout() async {
    try {
      await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 10));
    } finally {
      clearAuthToken();
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/auth/me'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return User.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> sendPasswordResetLink(String email) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password'),
            headers: _getHeaders(includeAuth: false),
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Gagal mengirim link reset password',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/reset-password'),
            headers: _getHeaders(includeAuth: false),
            body: jsonEncode({
              'email': email,
              'token': token,
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Gagal reset password',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ==================== DASHBOARD ====================

  Future<DashboardData?> getDashboard() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/dashboard'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return DashboardData.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== SEASONS ====================

  Future<List<Season>> getSeasons({String? search, String? status}) async {
    try {
      final queryParams = <String, String>{};
      if (search != null) queryParams['search'] = search;
      if (status != null) queryParams['status'] = status;

      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/seasons',
            ).replace(queryParameters: queryParams),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((item) => Season.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error in getSeasons: $e');
      return [];
    }
  }

  Future<Season?> getSeason(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/seasons/$id'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Season.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createSeason({
    required String name,
    required String startDate,
    required String endDate,
    required String status,
    required double targetKg,
    String? notes,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/seasons'),
            headers: _getHeaders(),
            body: jsonEncode({
              'name': name,
              'start_date': startDate,
              'end_date': endDate,
              'status': status,
              'target_kg': targetKg,
              'notes': notes,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'season': Season.fromJson(data['data'] ?? {}),
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menambahkan musim tanam',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateSeason(
    int id, {
    required String name,
    required String startDate,
    required String endDate,
    required String status,
    required double targetKg,
    String? notes,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/seasons/$id'),
            headers: _getHeaders(),
            body: jsonEncode({
              'name': name,
              'start_date': startDate,
              'end_date': endDate,
              'status': status,
              'target_kg': targetKg,
              'notes': notes,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'season': Season.fromJson(data['data'] ?? {}),
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengubah musim tanam',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteSeason(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/seasons/$id'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menghapus musim tanam',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ==================== HARVESTS ====================

  Future<List<Harvest>> getHarvests({int? seasonId}) async {
    try {
      final queryParams = <String, String>{};
      if (seasonId != null) queryParams['season_id'] = seasonId.toString();

      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/harvests',
            ).replace(queryParameters: queryParams),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final listData = data['data'] is Map
              ? (data['data']['harvests'] as List?)
              : (data['data'] as List?);
          if (listData != null) {
            return listData
                .map((item) => Harvest.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Harvest?> getHarvest(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/harvests/$id'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Harvest.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createHarvest({
    required int seasonId,
    required String harvestDate,
    required int quantity,
    required double weightKg,
    String? notes,
    String? status,
    XFile? photoFile,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/harvests');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_getHeaders(forMultipart: true));
      request.fields['season_id'] = seasonId.toString();
      request.fields['harvest_date'] = harvestDate;
      request.fields['quantity'] = quantity.toString();
      request.fields['weight_kg'] = weightKg.toString();
      if (notes != null) {
        request.fields['notes'] = notes;
      }
      request.fields['status'] = status ?? 'recorded';

      if (photoFile != null) {
        final photoBytes = await photoFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            photoBytes,
            filename: photoFile.name,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {'success': true, 'data': Harvest.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menambah panen',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateHarvest(
    int id, {
    int? seasonId,
    String? harvestDate,
    int? quantity,
    double? weightKg,
    String? notes,
    String? status,
    XFile? photoFile,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/harvests/$id');
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_getHeaders(forMultipart: true));
      request.fields['_method'] = 'PUT';
      request.headers['X-HTTP-Method-Override'] = 'PUT';

      if (seasonId != null) request.fields['season_id'] = seasonId.toString();
      if (harvestDate != null) request.fields['harvest_date'] = harvestDate;
      if (quantity != null) request.fields['quantity'] = quantity.toString();
      if (weightKg != null) request.fields['weight_kg'] = weightKg.toString();
      if (notes != null) request.fields['notes'] = notes;
      if (status != null) request.fields['status'] = status;

      if (photoFile != null) {
        final photoBytes = await photoFile.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            photoBytes,
            filename: photoFile.name,
          ),
        );
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': Harvest.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengupdate panen',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteHarvest(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/harvests/$id'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menghapus panen',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ==================== STOCK ====================

  Future<StockData?> getStock() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/stock'), headers: _getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return StockData.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== SALES ====================

  Future<List<Sale>> getSales() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/sales'), headers: _getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final listData = data['data'] is Map
              ? (data['data']['sales'] as List?)
              : (data['data'] as List?);
          if (listData != null) {
            return listData
                .map((item) => Sale.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Sale?> getSale(int id) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/sales/$id'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Sale.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> createSale({
    required int quantity,
    required int pricePerUnit,
    required String saleDate,
    required String buyerName,
    String? buyerPhone,
    String? notes,
    String? status,
    String? paymentStatus,
    int? seasonId,
  }) async {
    try {
      final body = <String, dynamic>{
        'quantity': quantity,
        'price_per_unit': pricePerUnit,
        'sale_date': saleDate,
        'buyer_name': buyerName,
        'buyer_phone': buyerPhone,
        'notes': notes,
        'status': status ?? 'completed',
        'payment_status': paymentStatus ?? 'paid',
      };
      
      if (seasonId != null) {
        body['season_id'] = seasonId;
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/sales'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {'success': true, 'data': Sale.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menambah penjualan',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateSale(
    int id, {
    int? quantity,
    int? pricePerUnit,
    String? saleDate,
    String? buyerName,
    String? buyerPhone,
    String? notes,
    String? status,
    String? paymentStatus,
    int? seasonId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (quantity != null) body['quantity'] = quantity;
      if (pricePerUnit != null) body['price_per_unit'] = pricePerUnit;
      if (saleDate != null) body['sale_date'] = saleDate;
      if (buyerName != null) body['buyer_name'] = buyerName;
      body['buyer_phone'] = buyerPhone;
      body['notes'] = notes;
      if (status != null) body['status'] = status;
      if (paymentStatus != null) body['payment_status'] = paymentStatus;
      if (seasonId != null) body['season_id'] = seasonId;

      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/sales/$id'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': Sale.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengupdate penjualan',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteSale(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/sales/$id'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menghapus penjualan',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: '};
    }
  }

  // ==================== SETTINGS & PROFILE ====================

  Future<Map<String, dynamic>?> getSettings() async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/settings'),
          headers: _getHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    final data = _decodeApiResponse(response);
    if (data['success'] == true) {
      return data['data'] as Map<String, dynamic>;
    }

    throw Exception(data['message'] ?? 'Gagal mengambil pengaturan');
  }

  // ==================== NOTIFICATIONS ====================

  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/notifications'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final dataMap = data['data'] as Map<String, dynamic>;
          final items = (dataMap['items'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ?? [];
          final unreadCount = dataMap['unread_count'] as int? ??
              items.where((item) => item['is_read'] == false).length;
          return {
            'items': items,
            'unread_count': unreadCount,
          };
        }
      }
      return {'items': [], 'unread_count': 0};
    } catch (e) {
      return {'items': [], 'unread_count': 0};
    }
  }

  Future<bool> markNotificationsAsRead({int? notificationId}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/notifications/read');
      final response = await http
          .post(
            uri,
            headers: _getHeaders(),
            body: jsonEncode({
              'notification_id': ?notificationId,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? farmName,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/settings/profile'),
            headers: _getHeaders(),
            body: jsonEncode({
              'name': name,
              'email': email,
              'phone': phone,
              'farm_name': farmName,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Profil gagal diperbarui',
        'data': data['data'],
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/settings/password'),
            headers: _getHeaders(),
            body: jsonEncode({
              'current_password': currentPassword,
              'password': password,
              'password_confirmation': passwordConfirmation,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Password gagal diperbarui',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }


  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/settings/account'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Akun gagal dihapus',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateWarehouseThresholds({
    required int minStock,
    required int maxStock,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/settings/gudang'),
            headers: _getHeaders(),
            body: jsonEncode({'min_stock': minStock, 'max_stock': maxStock}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Ambang batas gudang gagal diperbarui',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateNotifications({
    required bool notifyLowStock,
    required bool notifyNewSale,
    required bool notifyCost,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/settings/notifications'),
            headers: _getHeaders(),
            body: jsonEncode({
              'notify_low_stock': notifyLowStock,
              'notify_new_sale': notifyNewSale,
              'notify_cost': notifyCost,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Konfigurasi notifikasi gagal diperbarui',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== FEEDBACK (USER) ====================

  Future<Map<String, dynamic>> sendFeedback(String message) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/feedback'),
            headers: _getHeaders(),
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success':
            response.statusCode >= 200 &&
            response.statusCode < 300 &&
            data['success'] == true,
        'message': data['message'] ?? 'Feedback gagal dikirim',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== SUPER ADMIN ====================

  Future<Map<String, dynamic>?> getSuperAdminDashboard() async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/super-admin/dashboard'),
          headers: _getHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    final data = _decodeApiResponse(response);
    if (data['success'] == true) {
      return data['data'] as Map<String, dynamic>;
    }

    throw Exception(data['message'] ?? 'Gagal mengambil data dashboard super admin');
  }

  Future<List<dynamic>> getSuperAdminUsers() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/users'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as List;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createSuperAdminUser(
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/users'),
            headers: _getHeaders(),
            body: jsonEncode(userData),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 201 && data['success'] == true,
        'message': data['message'] ?? 'Gagal membuat user',
        'data': data['data'],
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateSuperAdminUser(
    int id,
    Map<String, dynamic> userData,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/users/$id'),
            headers: _getHeaders(),
            body: jsonEncode(userData),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Gagal memperbarui user',
        'data': data['data'],
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteSuperAdminUser(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/users/$id'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Gagal menghapus user',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> impersonateUser(int id) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/users/$id/impersonate'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'token': data['data']['token'],
          'user': User.fromJson(data['data']['user']),
        };
      }
      return {
        'success': false,
        'message': data['message'] ?? 'Gagal masuk sebagai user tersebut',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> getLandingContent() async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/landing'),
          headers: _getHeaders(includeAuth: false),
        )
        .timeout(const Duration(seconds: 15));

    final data = _decodeApiResponse(response);
    if (data['success'] == true) {
      return data['data'] as Map<String, dynamic>;
    }

    throw Exception(data['message'] ?? 'Gagal mengambil konten landing page');
  }

  Future<Map<String, dynamic>> updateLandingContent(
    Map<String, String> landingData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/landing'),
            headers: _getHeaders(),
            body: jsonEncode(landingData),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Gagal memperbarui landing page',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<dynamic>> getDashboardMenus() async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/menus'),
          headers: _getHeaders(),
        )
        .timeout(const Duration(seconds: 15));

    final data = _decodeApiResponse(response);
    if (data['success'] == true && data['data'] != null) {
      return data['data'] as List;
    }

    throw Exception(data['message'] ?? 'Gagal mengambil daftar menu dashboard');
  }

  Future<Map<String, dynamic>> createDashboardMenu(
    Map<String, dynamic> menuData,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/menus'),
            headers: _getHeaders(),
            body: jsonEncode(menuData),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 201 && data['success'] == true,
        'message': data['message'] ?? 'Gagal membuat menu',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateDashboardMenu(
    int id,
    Map<String, dynamic> menuData,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/menus/$id'),
            headers: _getHeaders(),
            body: jsonEncode(menuData),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Gagal memperbarui menu',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteDashboardMenu(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/menus/$id'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Gagal menghapus menu',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<dynamic>> getFeedbacks() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/feedbacks'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as List;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> markFeedbackAsRead(int id) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/feedbacks/$id/read'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Gagal menandai feedback sudah dibaca',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteFeedback(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/super-admin/feedbacks/$id'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Gagal menghapus feedback',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ==================== REPORTS ====================

  Future<Map<String, dynamic>?> getProfitLossReport({int? seasonId}) async {
    try {
      final url = seasonId != null
          ? '${ApiConfig.baseUrl}/reports/profit-loss?season_id=$seasonId'
          : '${ApiConfig.baseUrl}/reports/profit-loss';
      final response = await http
          .get(Uri.parse(url), headers: _getHeaders())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getTargetVsActualReport() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/reports/target-vs-actual'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as List;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ==================== COSTS ====================

  Future<List<Cost>> getCosts({int? seasonId}) async {
    try {
      final queryParams = <String, String>{};
      if (seasonId != null) queryParams['season_id'] = seasonId.toString();

      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/costs',
            ).replace(queryParameters: queryParams),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final listData = data['data'] is Map
              ? (data['data']['costs'] as List?)
              : (data['data'] as List?);
          if (listData != null) {
            return listData
                .map((item) => Cost.fromJson(item as Map<String, dynamic>))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createCost({
    required String date,
    int? seasonId,
    required String category,
    required double amount,
    String? notes,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/costs'),
            headers: _getHeaders(),
            body: jsonEncode({
              'date': date,
              'season_id': seasonId,
              'category': category,
              'amount': amount,
              'notes': notes,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {'success': true, 'data': Cost.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menambah biaya',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateCost(
    int id, {
    String? date,
    int? seasonId,
    String? category,
    double? amount,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (date != null) body['date'] = date;
      body['season_id'] = seasonId;
      if (category != null) body['category'] = category;
      if (amount != null) body['amount'] = amount;
      body['notes'] = notes;

      final response = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}/costs/$id'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'data': Cost.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengupdate biaya',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> deleteCost(int id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/costs/$id'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal menghapus biaya',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // ==================== CHATBOT ====================
  Future<Map<String, dynamic>> sendChatMessage(String message) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/chat'),
            headers: _getHeaders(includeAuth: false),
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'reply': data['reply'] ?? 'Maaf, terjadi kesalahan.',
        };
      } else {
        return {
          'success': false,
          'reply': data['reply'] ?? 'Maaf, terjadi kesalahan.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'reply': 'Gagal terhubung ke server. Pastikan server Laravel aktif.',
      };
    }
  }

  Future<List<int>?> downloadProfitLossReportPdf({int? seasonId}) async {
    try {
      final url = seasonId != null
          ? '${ApiConfig.baseUrl}/reports/export/profit-loss/pdf?season_id=$seasonId'
          : '${ApiConfig.baseUrl}/reports/export/profit-loss/pdf';
      final response = await http
          .get(Uri.parse(url), headers: _getHeaders())
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('pdf') || contentType.contains('octet-stream')) {
          return response.bodyBytes;
        } else {
          // Server returned JSON error instead of PDF
          throw Exception('Server error: ${response.body}');
        }
      } else {
        // Try to parse JSON error message from server
        try {
          final data = jsonDecode(response.body);
          throw Exception('HTTP ${response.statusCode}: ${data['message'] ?? response.body}');
        } catch (parseErr) {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('downloadProfitLossReportPdf error: $e');
      rethrow;
    }
  }

  Future<List<int>?> downloadTargetVsActualReportPdf() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/reports/export/target-vs-actual/pdf'),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('pdf') || contentType.contains('octet-stream')) {
          return response.bodyBytes;
        } else {
          throw Exception('Server error: ${response.body}');
        }
      } else {
        try {
          final data = jsonDecode(response.body);
          throw Exception('HTTP ${response.statusCode}: ${data['message'] ?? response.body}');
        } catch (parseErr) {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('downloadTargetVsActualReportPdf error: $e');
      rethrow;
    }
  }
}
