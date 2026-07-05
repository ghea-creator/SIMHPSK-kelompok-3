# Panduan Implementasi Sinkronisasi Data Laravel 11 ↔ Flutter

## 📋 Daftar Isi
1. [Overview Arsitektur](#overview-arsitektur)
2. [Setup Laravel API](#setup-laravel-api)
3. [Setup Flutter Client](#setup-flutter-client)
4. [Flow Login & Register](#flow-login--register)
5. [Troubleshooting](#troubleshooting)

---

## Overview Arsitektur

### Alur Komunikasi
```
Flutter Mobile App 
    ↓ (HTTP POST Request)
Laravel API Gateway (Port 8000)
    ↓ (Validation & Token Generation)
MySQL Database
    ↓ (Sanctum Token + User Data)
Flutter Mobile App (Simpan Token & User Data)
```

### Struktur Response JSON (Standard)
Semua response dari Laravel API mengikuti format ini:

```json
{
  "success": true,
  "message": "Login berhasil.",
  "code": 200,
  "data": {
    "token": "1|abcdefghijklmnopqrstuvwxyz...",
    "token_type": "Bearer",
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "farm_name": "Farm ABC",
      "phone": "08123456789",
      "role": "user",
      "status": "active",
      "approval": "approved",
      "created_at": "2024-01-15T10:30:00.000000Z",
      "updated_at": "2024-01-15T10:30:00.000000Z"
    }
  }
}
```

---

## Setup Laravel API

### 1. Lokasi File API Controller

**Path:** `app/Http/Controllers/Api/AuthController.php`

File `AuthController.php` sudah tersedia di:
- **Path lengkap:** `app/Http/Controllers/AuthController.php`
- **Method yang dibutuhkan:** 
  - `registerApi()` - Untuk registrasi user baru
  - `loginApi()` - Untuk login dan mendapat token

### 2. Konfigurasi Routes (routes/api.php)

Rute sudah terdaftar dengan benar:

```php
<?php
// Public Routes - Auth (TIDAK PERLU TOKEN)
Route::post('/auth/register', [AuthController::class, 'registerApi']);
Route::post('/auth/login', [AuthController::class, 'loginApi']);

// Protected Routes - Requires Sanctum Authentication (PERLU TOKEN)
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logoutApi']);
    Route::get('/auth/me', [AuthController::class, 'meApi']);
    // ... routes lainnya
});
```

### 3. Validasi Input & Hash Password

Contoh implementasi di `loginApi()`:

```php
public function loginApi(Request $request)
{
    try {
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        // Cari user berdasarkan email
        $user = User::where('email', $validated['email'])->first();

        // Validasi password menggunakan Hash::check()
        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return $this->errorResponse('Email atau password salah.', 401);
        }

        // Check status user
        if ($user->status === 'inactive') {
            return $this->errorResponse('Akun Anda tidak aktif.', 403);
        }

        // Generate Sanctum Token
        $token = $user->createToken('api-token')->plainTextToken;

        return $this->successResponse([
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'farm_name' => $user->farm_name,
                'phone' => $user->phone,
                'role' => $user->role,
                'status' => $user->status,
                'approval' => $user->approval,
            ],
        ], 'Login berhasil.', 200);
    } catch (ValidationException $e) {
        return $this->validationErrorResponse($e->errors());
    }
}
```

### 4. Setup Sanctum untuk API Tokens

Pastikan konfigurasi di `config/sanctum.php`:

```php
'stateful' => explode(',', env('SANCTUM_STATEFUL_DOMAINS', 'localhost,127.0.0.1,127.0.0.1:3000,localhost:3000')),

'api_middleware' => [
    \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
],
```

---

## Setup Flutter Client

### 1. Dependencies yang Diperlukan

Pastikan `pubspec.yaml` sudah memiliki:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.6.0                    # Untuk HTTP Request
  shared_preferences: ^2.2.0      # Untuk menyimpan token
  provider: ^6.0.0                # Untuk state management (optional)
  intl: ^0.19.0                   # Untuk date formatting
```

### 2. File Structure Flutter

Buat struktur folder seperti ini:

```
lib/
├── models/
│   └── user_model.dart           # Model user dengan factory fromJson
├── services/
│   ├── api_service.dart          # Base HTTP client
│   └── auth_service.dart         # Login & Register logic
├── utils/
│   ├── constants.dart            # BaseUrl dan constants
│   └── shared_prefs.dart         # Token management
└── main.dart
```

### 3. File: lib/utils/constants.dart

```dart
// Constants untuk API configuration
class ApiConstants {
  // ⚠️ GANTI dengan IP lokal laptop Anda
  static const String BASE_URL = 'http://192.168.1.5:8000/api';
  // Alternatif untuk emulator Android
  // static const String BASE_URL = 'http://10.0.2.2:8000/api';
  // Alternatif untuk iOS Simulator
  // static const String BASE_URL = 'http://localhost:8000/api';

  // Endpoints
  static const String LOGIN = '/auth/login';
  static const String REGISTER = '/auth/register';
  static const String LOGOUT = '/auth/logout';
  static const String ME = '/auth/me';
}

class SharedPrefsKeys {
  static const String ACCESS_TOKEN = 'access_token';
  static const String USER_DATA = 'user_data';
}
```

### 4. File: lib/utils/shared_prefs.dart

```dart
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _tokenKey = 'access_token';
  static const String _userKey = 'user_data';

  // Simpan token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('✅ Token tersimpan: $token');
  }

  // Ambil token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Simpan user data (JSON string)
  static Future<void> saveUserData(String userJsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, userJsonString);
    print('✅ User data tersimpan');
  }

  // Ambil user data
  static Future<String?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userKey);
  }

  // Hapus semua (Logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    print('✅ Token dan user data dihapus (Logout)');
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
```

### 5. File: lib/models/user_model.dart

```dart
import 'dart:convert';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String farmName;
  final String phone;
  final String role;
  final String status;
  final String approval;
  final String? createdAt;
  final String? updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.farmName,
    required this.phone,
    required this.role,
    required this.status,
    required this.approval,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor untuk membuat UserModel dari JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      farmName: json['farm_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      status: json['status'] as String? ?? 'active',
      approval: json['approval'] as String? ?? 'pending',
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  /// Convert UserModel ke JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'farm_name': farmName,
      'phone': phone,
      'role': role,
      'status': status,
      'approval': approval,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// Convert UserModel ke JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Factory untuk membuat UserModel dari JSON string
  factory UserModel.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return UserModel.fromJson(json);
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, farmName: $farmName)';
  }
}

/// Response wrapper untuk API response
class ApiResponse<T> {
  final bool success;
  final String message;
  final int code;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    required this.code,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataBuilder,
  ) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      code: json['code'] as int? ?? 0,
      data: json['data'] != null && dataBuilder != null 
          ? dataBuilder(json['data'])
          : null,
    );
  }
}

/// Login Response dengan token
class LoginResponse {
  final String token;
  final String tokenType;
  final UserModel user;

  LoginResponse({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String? ?? '',
      tokenType: json['token_type'] as String? ?? 'Bearer',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }
}
```

### 6. File: lib/services/api_service.dart

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_app/utils/constants.dart';
import 'package:mobile_app/utils/shared_prefs.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  /// Generic GET request
  Future<T> get<T>(
    String endpoint, {
    required T Function(dynamic) dataBuilder,
  }) async {
    try {
      final token = await TokenManager.getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('${ApiConstants.BASE_URL}$endpoint'),
        headers: headers,
      );

      print('🔵 GET $endpoint - Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return dataBuilder(data['data']);
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        await TokenManager.clearAll();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ GET Error: $e');
      rethrow;
    }
  }

  /// Generic POST request
  Future<T> post<T>(
    String endpoint, {
    required Map<String, dynamic> body,
    required T Function(dynamic) dataBuilder,
  }) async {
    try {
      final token = await TokenManager.getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      print('🟢 POST $endpoint - Body: $body');

      final response = await http.post(
        Uri.parse('${ApiConstants.BASE_URL}$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return dataBuilder(data['data']);
      } else if (response.statusCode == 401) {
        await TokenManager.clearAll();
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 422) {
        // Validation error
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception('Validation Error: ${errorData['data']}');
      } else {
        throw Exception('Request failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ POST Error: $e');
      rethrow;
    }
  }
}
```

### 7. File: lib/services/auth_service.dart

```dart
import 'package:mobile_app/models/user_model.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/utils/constants.dart';
import 'package:mobile_app/utils/shared_prefs.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final ApiService apiService = ApiService();

  /// Login ke Laravel API
  /// Returns: [token, user_data]
  Future<Map<String, dynamic>> loginKeLaravel({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Attempting login for: $email');

      final body = {
        'email': email,
        'password': password,
      };

      final token = await TokenManager.getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('${ApiConstants.BASE_URL}${ApiConstants.LOGIN}'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📤 Login Response Status: ${response.statusCode}');
      print('📋 Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Validasi struktur response
        if (!jsonResponse.containsKey('data')) {
          throw Exception('Invalid response structure: missing "data" field');
        }

        final loginData = jsonResponse['data'] as Map<String, dynamic>;
        
        // Parse login response
        final loginResponse = LoginResponse.fromJson(loginData);

        // Simpan token
        await TokenManager.saveToken(loginResponse.token);

        // Simpan user data
        await TokenManager.saveUserData(loginResponse.user.toJsonString());

        print('✅ Login Success!');
        print('Token: ${loginResponse.token}');
        print('User: ${loginResponse.user}');

        return {
          'success': true,
          'token': loginResponse.token,
          'user': loginResponse.user,
        };
      } else if (response.statusCode == 401) {
        throw Exception('Email atau password salah');
      } else if (response.statusCode == 403) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final message = jsonResponse['message'] as String? ?? 'Account not approved';
        throw Exception(message);
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Login Error: $e');
      rethrow;
    }
  }

  /// Register ke Laravel API
  Future<Map<String, dynamic>> registerKeLaravel({
    required String farmName,
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      print('📝 Attempting registration for: $email');

      final body = {
        'farm_name': farmName,
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      };

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http.post(
        Uri.parse('${ApiConstants.BASE_URL}${ApiConstants.REGISTER}'),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📤 Register Response Status: ${response.statusCode}');
      print('📋 Register Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

        print('✅ Registration Success!');

        return {
          'success': true,
          'message': jsonResponse['message'] as String? ?? 'Registration successful',
          'data': jsonResponse['data'],
        };
      } else if (response.statusCode == 422) {
        // Validation error
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        final errors = jsonResponse['data'] as Map<String, dynamic>? ?? {};
        
        String errorMessage = 'Validation failed: ';
        errors.forEach((key, value) {
          if (value is List) {
            errorMessage += '${value.join(', ')} ';
          }
        });

        throw Exception(errorMessage);
      } else {
        throw Exception('Registration failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Register Error: $e');
      rethrow;
    }
  }

  /// Logout dari aplikasi
  Future<void> logout() async {
    try {
      final token = await TokenManager.getToken();
      
      if (token != null) {
        final headers = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        };

        final response = await http.post(
          Uri.parse('${ApiConstants.BASE_URL}${ApiConstants.LOGOUT}'),
          headers: headers,
        );

        print('Logout Response: ${response.statusCode}');
      }

      // Hapus token dan user data
      await TokenManager.clearAll();
      print('✅ Logout Success!');
    } catch (e) {
      print('❌ Logout Error: $e');
      // Still clear local data even if API call fails
      await TokenManager.clearAll();
    }
  }

  /// Ambil data user yang sedang login
  Future<UserModel> getCurrentUser() async {
    try {
      final userJsonString = await TokenManager.getUserData();
      
      if (userJsonString == null || userJsonString.isEmpty) {
        throw Exception('No user data found');
      }

      final user = UserModel.fromJsonString(userJsonString);
      return user;
    } catch (e) {
      print('❌ Get Current User Error: $e');
      rethrow;
    }
  }

  /// Check apakah user sudah login
  Future<bool> isLoggedIn() async {
    return await TokenManager.isLoggedIn();
  }
}
```

---

## Flow Login & Register

### Flow Login
```
User ketik email & password di Flutter
    ↓
AuthService.loginKeLaravel(email, password)
    ↓
POST /api/auth/login dengan credentials
    ↓
Laravel validasi email & password dengan Hash::check()
    ↓
Token Sanctum dihasilkan: $user->createToken('api-token')
    ↓
Response JSON dengan token + user data dikirim ke Flutter
    ↓
Flutter menerima response
    ↓
Token disimpan di SharedPreferences
User data disimpan di SharedPreferences (JSON string)
    ↓
User berhasil login & bisa akses protected endpoints
```

### Flow Register
```
User isi form (farmName, name, email, phone, password)
    ↓
AuthService.registerKeLaravel(...)
    ↓
POST /api/auth/register dengan data
    ↓
Laravel validasi (email unique, password confirmed, dsb)
    ↓
User dibuat dengan Password::make() untuk hash password
    ↓
Response JSON dengan status "pending_approval"
    ↓
Flutter menampilkan pesan: "Registrasi berhasil! Tunggu persetujuan admin"
    ↓
User menunggu admin approval di dashboard web Laravel
```

---

## Troubleshooting

### ❌ Error: "Null check operator used on a null value"

**Penyebab:** Field JSON dari Laravel tidak ada di response atau parsing model salah.

**Solusi:**
1. Debug: Print response dari Laravel
   ```dart
   print('Raw Response: ${response.body}');
   ```

2. Ensure UserModel.fromJson() menggunakan `??` untuk default value:
   ```dart
   factory UserModel.fromJson(Map<String, dynamic> json) {
     return UserModel(
       id: json['id'] as int? ?? 0,  // ← Selalu kasih default
       name: json['name'] as String? ?? '',
       email: json['email'] as String? ?? '',
       // ...
     );
   }
   ```

### ❌ Error: "type 'String' is not a subtype of type 'int'"

**Penyebab:** JSON field mempunyai type yang berbeda dari yang diharapkan.

**Solusi:**
1. Pastikan tipe casting benar di model:
   ```dart
   // ❌ SALAH
   final id = json['id'];  // Bisa String atau int
   
   // ✅ BENAR
   final id = json['id'] as int? ?? 0;  // Paksa jadi int dengan default 0
   ```

2. Check di Laravel response apakah field 'id' sudah int:
   ```php
   'id' => $user->id,  // Pastikan ini integer
   ```

### ❌ Error: "Connection refused" / "Failed host lookup"

**Penyebab:** BaseUrl IP tidak valid atau Laravel server tidak jalan.

**Solusi:**
1. Pastikan Laravel running:
   ```bash
   php artisan serve --host 0.0.0.0 --port 8000
   ```

2. Ganti IP di `constants.dart` sesuai IP laptop:
   ```dart
   // Cek IP laptop: ipconfig (Windows) atau ifconfig (Mac/Linux)
   static const String BASE_URL = 'http://192.168.1.5:8000/api';
   ```

3. Untuk emulator Android, gunakan:
   ```dart
   static const String BASE_URL = 'http://10.0.2.2:8000/api';
   ```

### ❌ Error: "401 Unauthorized"

**Penyebab:** Token tidak dikirim atau token sudah expired.

**Solusi:**
1. Pastikan token dikirim di header setiap request:
   ```dart
   final headers = {
     'Authorization': 'Bearer $token',  // ← Jangan lupa ini
   };
   ```

2. Refresh atau re-login jika token expired.

---

## Testing di Postman

### Test Register
```
POST http://localhost:8000/api/auth/register

Body (JSON):
{
  "farm_name": "Farm ABC",
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "08123456789",
  "password": "password123",
  "password_confirmation": "password123"
}
```

### Test Login
```
POST http://localhost:8000/api/auth/login

Body (JSON):
{
  "email": "john@example.com",
  "password": "password123"
}

Response:
{
  "success": true,
  "message": "Login berhasil.",
  "code": 200,
  "data": {
    "token": "1|abcdefghijk...",
    "token_type": "Bearer",
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      ...
    }
  }
}
```

### Test Protected Endpoint
```
GET http://localhost:8000/api/auth/me

Headers:
Authorization: Bearer 1|abcdefghijk...
Content-Type: application/json
```

---

## Checklist Implementasi

- [ ] Laravel AuthController sudah memiliki `registerApi()` dan `loginApi()`
- [ ] Routes `/api/auth/register` dan `/api/auth/login` terdaftar di `routes/api.php`
- [ ] Sanctum token berfungsi dengan baik
- [ ] Flutter `pubspec.yaml` memiliki `http`, `shared_preferences`
- [ ] Flutter `user_model.dart` dibuat dengan factory `fromJson`
- [ ] Flutter `auth_service.dart` dibuat dengan `loginKeLaravel()` dan `registerKeLaravel()`
- [ ] BaseUrl di `constants.dart` sudah sesuai IP laptop
- [ ] Token disimpan di `SharedPreferences` setelah login
- [ ] User data disimpan sebagai JSON string di `SharedPreferences`
- [ ] Error handling benar (tidak ada null check operator error)
- [ ] Test dengan Postman berhasil
- [ ] Test dengan Flutter emulator/device berhasil

---

## Referensi
- [Laravel Sanctum Documentation](https://laravel.com/docs/11.x/sanctum)
- [Flutter HTTP Package](https://pub.dev/packages/http)
- [Flutter Shared Preferences](https://pub.dev/packages/shared_preferences)
- [JSON Serialization in Flutter](https://flutter.dev/docs/development/data-and-backend/json)

