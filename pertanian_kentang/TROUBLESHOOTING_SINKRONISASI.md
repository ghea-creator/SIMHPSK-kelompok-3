# 🔧 PANDUAN TROUBLESHOOTING SINKRONISASI LARAVEL ↔ FLUTTER

## 📋 Daftar Error & Solusi

---

## ❌ ERROR 1: "Connection refused" / "Failed to connect"

### Tanda-tanda:
```
I/flutter ( 1234): 🔴 Network Error: SocketException: Failed host lookup: '192.168.1.5'
```

### Penyebab Umum:
1. Laravel server tidak running
2. IP address salah di `constants.dart`
3. Firewall memblock port 8000
4. Device tidak bisa reach server (WiFi different, network issue)
5. Port 8000 sudah dipakai aplikasi lain

### Solusi:

#### Step 1: Pastikan Laravel Server Running
```bash
# Terminal - folder Laravel
cd c:\laragon\www\pertanian_kentangnew\pertanian_kentang

# Run server dengan host 0.0.0.0 agar accessible dari device lain
php artisan serve --host 0.0.0.0 --port 8000

# Output harus seperti ini:
# Laravel development server started: http://127.0.0.1:8000
# ✅ Server sudah jalan
```

#### Step 2: Get IP Laptop Anda
```bash
# Windows - buka CMD/PowerShell
ipconfig

# Cari IPv4 Address, contoh output:
# IPv4 Address. . . . . . . . . . . : 192.168.1.5

# Copy IP tersebut (192.168.1.5)
```

#### Step 3: Update IP di Flutter
```dart
// File: lib/utils/constants.dart

class ApiConstants {
  // 🔴 GANTI 192.168.1.5 dengan IP Anda
  static const String BASE_URL = 'http://192.168.1.5:8000/api';
}
```

#### Step 4: Tentukan Platform & BaseUrl yang Tepat

**Jika menggunakan Physical Device (Real Phone):**
```dart
static const String BASE_URL = 'http://192.168.1.5:8000/api';
```

**Jika menggunakan Android Emulator:**
```dart
// Android emulator tidak bisa akses localhost
// Gunakan IP special 10.0.2.2 yang refer ke host
static const String BASE_URL = 'http://10.0.2.2:8000/api';
```

**Jika menggunakan iOS Simulator (di Mac yang sama):**
```dart
// iOS simulator bisa akses localhost langsung
static const String BASE_URL = 'http://localhost:8000/api';
```

#### Step 5: Test Koneksi
```bash
# Dari device/emulator, coba ping
ping 192.168.1.5

# Atau test dengan Postman
# GET http://192.168.1.5:8000/api/auth/me
# (tanpa header dulu, cek response)
```

---

## ❌ ERROR 2: "Null check operator used on a null value"

### Tanda-tanda:
```
Exception: Null check operator used on a null value
  at Object.noSuchMethod (dart:core-patch/object_patch.dart:54:47)
  at main.dart:123:45
```

### Penyebab Umum:
1. Field di JSON response tidak ada / null
2. Field name tidak match (snake_case vs camelCase)
3. Model factory constructor tidak handle null
4. Response structure berbeda dari yang diharapkan

### Solusi:

#### Step 1: Debug - Print Response
```dart
// Di auth_service.dart, tambahkan print:
final response = await http.post(...);

print('📋 Raw Response: ${response.body}');  // ← Tambahkan ini
final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

// Lihat console output
// Bandingkan dengan field di model
```

#### Step 2: Check Field Names
Pastikan field names di Laravel response match dengan model parsing:

```dart
// Laravel response fields (snake_case):
{
  "id": 1,
  "name": "John",
  "farm_name": "Farm ABC",  // ← snake_case
  "email": "john@example.com"
}

// Flutter model factory:
factory UserModel.fromJson(Map<String, dynamic> json) {
  return UserModel(
    id: json['id'] as int? ?? 0,  // ← Cast & provide default
    name: json['name'] as String? ?? '',
    farmName: json['farm_name'] as String? ?? '',  // ← Match snake_case
    email: json['email'] as String? ?? '',
  );
}
```

#### Step 3: Always Use Null Coalescing (`??`)
```dart
// ❌ WRONG - bisa null error
final id = json['id'] as int;

// ✅ CORRECT - dengan default value
final id = json['id'] as int? ?? 0;
```

#### Step 4: Validate Response Structure
```dart
// Sebelum parse, check struktur
if (!jsonResponse.containsKey('data')) {
  throw Exception('Invalid response: missing data field');
}

final data = jsonResponse['data'] as Map<String, dynamic>? ?? {};

if (data.isEmpty) {
  throw Exception('Empty data received');
}
```

#### Step 5: Contoh Safe Parsing
```dart
// lib/models/user_model.dart - Safe factory method

factory UserModel.fromJson(Map<String, dynamic> json) {
  // Debug: print raw json
  print('Parsing JSON: $json');
  
  return UserModel(
    // Gunakan as Type? untuk type safety
    // Gunakan ?? untuk default value
    // Ini mencegah null error
    
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
```

---

## ❌ ERROR 3: "type 'String' is not a subtype of type 'int'"

### Tanda-tanda:
```
TypeError: type 'String' is not a subtype of type 'int'
```

### Penyebab:
1. JSON field di-return sebagai String, tapi model expect int
2. Type casting tidak benar di model
3. Database column type berbeda dari yang diharapkan

### Solusi:

#### Check JSON Field Type di Laravel
```php
// app/Http/Controllers/AuthController.php
public function loginApi(Request $request)
{
    // ...
    
    return $this->successResponse([
        'token' => $token,
        'user' => [
            'id' => (int)$user->id,  // ← Pastikan type int
            'name' => (string)$user->name,
            // ...
        ],
    ]);
}
```

#### Check Model Type Casting
```dart
// lib/models/user_model.dart
factory UserModel.fromJson(Map<String, dynamic> json) {
  return UserModel(
    // ❌ WRONG
    id: json['id'],  // Type bisa apa saja
    
    // ✅ CORRECT
    id: (json['id'] is int) 
        ? json['id'] as int 
        : int.tryParse(json['id'].toString()) ?? 0,
  );
}
```

#### Safe Number Parsing
```dart
// Helper function untuk parse number safely
int _parseInt(dynamic value, [int defaultValue = 0]) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

// Gunakan di model
factory UserModel.fromJson(Map<String, dynamic> json) {
  return UserModel(
    id: _parseInt(json['id'], 0),
    // ...
  );
}
```

---

## ❌ ERROR 4: "Email atau password salah" (401 Unauthorized)

### Tanda-tanda:
```
Login Error: Email atau password salah
```

### Penyebab:
1. Email tidak ada di database
2. Password tidak match
3. User status inactive
4. User approval pending/rejected

### Solusi:

#### Step 1: Verify User di Database
```bash
# Terminal - folder Laravel
php artisan tinker

# Di tinker shell:
App\Models\User::where('email', 'test@example.com')->first();

# Output harus menunjukkan user data
# Jika null, user tidak ada di database
```

#### Step 2: Check Password Hash
```bash
# Di tinker shell, verify password:
$user = App\Models\User::find(1);
Hash::check('password123', $user->password);  // return true/false
```

#### Step 3: Register User Baru
Jika user tidak ada, gunakan app untuk register:

```dart
// Di Flutter app
final result = await AuthService().registerKeLaravel(
  farmName: 'Test Farm',
  name: 'Test User',
  email: 'testuser@example.com',
  phone: '08123456789',
  password: 'testpassword123',
  passwordConfirmation: 'testpassword123',
);

// User akan dibuat dengan status active, approval pending
// Admin perlu approve di dashboard
```

#### Step 4: Check User Status & Approval
```bash
# Di tinker shell:
$user = App\Models\User::find(1);
dd([
  'status' => $user->status,
  'approval' => $user->approval
]);

# Harus output:
# status => "active"
# approval => "approved"  (jangan pending atau rejected)
```

#### Step 5: Update User Status (untuk testing)
```bash
# Di tinker shell:
$user = App\Models\User::find(1);
$user->update(['status' => 'active', 'approval' => 'approved']);

# Sekarang user bisa login
```

---

## ❌ ERROR 5: "Token tidak tersimpan" / "Null" saat ambil token

### Tanda-tanda:
```
⚠️ No token found in local storage
```

### Penyebab:
1. Token tidak berhasil disimpan ke SharedPreferences
2. SharedPreferences belum initialize
3. Token berhasil disimpan tapi app restart/clean

### Solusi:

#### Step 1: Debug Token Saving
```dart
// Di auth_service.dart, tambahkan log:
await TokenManager.saveToken(loginResponse.token);

// Di shared_prefs.dart
static Future<void> saveToken(String token) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(_tokenKey, token);
    
    print('Token save result: $saved');  // ← Add this
    print('Token: ${token.substring(0, 20)}...');
    
    // Verify immediately
    final check = prefs.getString(_tokenKey);
    print('Token verify: ${check?.substring(0, 20)}...');
  } catch (e) {
    print('Error: $e');
  }
}
```

#### Step 2: Initialize SharedPreferences
Pastikan SharedPreferences sudah initialize di main.dart:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences (jika belum)
  // Untuk plugin modern, auto initialize
  
  runApp(const MyApp());
}
```

#### Step 3: Check SharedPreferences Content
```dart
// Buat debug screen untuk lihat SharedPreferences:
void _debugShowAllSharedPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  
  print('=== SharedPreferences Content ===');
  final allKeys = prefs.getKeys();
  
  for (var key in allKeys) {
    final value = prefs.get(key);
    print('$key: $value');
  }
}
```

#### Step 4: Clear & Retry
```dart
// Clear semua data
await TokenManager.clearAll();

// Retry login
await AuthService().loginKeLaravel(...);

// Verify token tersimpan
final token = await TokenManager.getToken();
print('Token: $token');
```

---

## ❌ ERROR 6: "Validation Error" (422 - Unprocessable Entity)

### Tanda-tanda:
```
Validation failed:
• The email has already been taken.
• The password confirmation does not match.
```

### Penyebab:
1. Email sudah terdaftar di database
2. Password tidak cocok (password_confirmation berbeda)
3. Field required kosong
4. Field value tidak match validation rules

### Solusi:

#### Step 1: Check Validation Error Response
```dart
// Di auth_service.dart, parse error detail:
if (response.statusCode == 422) {
  final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
  final errors = jsonResponse['data'] as Map<String, dynamic>? ?? {};
  
  print('Validation Errors:');
  errors.forEach((field, messages) {
    print('$field: $messages');
  });
}
```

#### Step 2: Validate Input di Flutter
```dart
// lib/examples/register_example.dart
bool _validateForm() {
  // Check email tidak kosong
  if (_emailController.text.isEmpty) {
    setState(() => _errorMessage = 'Email tidak boleh kosong');
    return false;
  }
  
  // Check email format
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  );
  if (!emailRegex.hasMatch(_emailController.text)) {
    setState(() => _errorMessage = 'Format email tidak valid');
    return false;
  }
  
  // Check password length
  if (_passwordController.text.length < 8) {
    setState(() => _errorMessage = 'Password minimal 8 karakter');
    return false;
  }
  
  // Check password confirmation
  if (_passwordController.text != _passwordConfirmController.text) {
    setState(() => _errorMessage = 'Password tidak cocok');
    return false;
  }
  
  return true;
}
```

#### Step 3: Use Unique Email
```dart
// Generate unique email untuk testing:
final randomEmail = 'test${DateTime.now().millisecond}@example.com';

final result = await AuthService().registerKeLaravel(
  email: randomEmail,  // ← Unique email
  // ...
);
```

#### Step 4: Check Laravel Validation Rules
```php
// app/Http/Controllers/AuthController.php
public function registerApi(Request $request)
{
    $validated = $request->validate([
        'email' => 'required|email|unique:users',  // ← unique rule
        'password' => 'required|string|min:8|confirmed',  // ← confirmed rule
        'password_confirmation' => 'required',  // ← required
        // ...
    ]);
}
```

---

## ❌ ERROR 7: "Session expired" (401 di Protected Endpoint)

### Tanda-tanda:
```
Session expired. Please login again.
```

### Penyebab:
1. Token sudah invalid/expired
2. Token di-revoke di server
3. Database token record dihapus
4. Browser/device cache lama

### Solusi:

#### Step 1: Handle Token Expiration
```dart
// Di api_service.dart
if (response.statusCode == 401) {
  print('Token expired or invalid');
  
  // Clear local data
  await TokenManager.clearAll();
  
  // Navigate to login
  // NavigatorState.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
  
  throw Exception('Session expired. Please login again.');
}
```

#### Step 2: Implement Token Refresh (Optional)
```dart
// Jika Laravel support refresh token:
Future<void> _refreshToken() async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConstants.BASE_URL}/auth/refresh'),
      headers: {
        'Authorization': 'Bearer ${await TokenManager.getToken()}',
      },
    );
    
    if (response.statusCode == 200) {
      final newToken = jsonDecode(response.body)['data']['token'];
      await TokenManager.saveToken(newToken);
    } else {
      // Re-login required
      await TokenManager.clearAll();
    }
  } catch (e) {
    print('Token refresh failed: $e');
  }
}
```

#### Step 3: Re-Login User
```dart
// Show login screen when token expired
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Session Expired'),
    content: const Text('Please login again'),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        },
        child: const Text('Login'),
      ),
    ],
  ),
);
```

---

## ❌ ERROR 8: "Network Error" / Timeout

### Tanda-tanda:
```
SocketException: Failed connect to 192.168.1.5:8000
Exception: Network error. Please check your connection.
```

### Penyebab:
1. WiFi terputus
2. Server crashed atau down
3. Network timeout (server response lambat)
4. DNS resolution error

### Solusi:

#### Step 1: Add Timeout
```dart
// Di api_service.dart
final response = await http.post(
  Uri.parse(url),
  headers: headers,
  body: jsonEncode(body),
).timeout(const Duration(seconds: 30));  // ← Add timeout
```

#### Step 2: Better Network Error Handling
```dart
try {
  final response = await http.post(...).timeout(
    const Duration(seconds: 30),
    onTimeout: () {
      throw TimeoutException('Request timeout');
    },
  );
} on TimeoutException catch (e) {
  print('Request timeout: $e');
  throw Exception('Server tidak merespons. Cek koneksi Anda.');
} on SocketException catch (e) {
  print('Socket error: $e');
  throw Exception('Koneksi internet gagal. Pastikan WiFi terhubung.');
} on FormatException catch (e) {
  print('Format error: $e');
  throw Exception('Response format tidak valid.');
}
```

#### Step 3: Check Server Status
```bash
# Terminal
php artisan serve --host 0.0.0.0 --port 8000

# Jika ada error, output akan menunjukkan
# Cek Laravel log:
tail -f storage/logs/laravel.log
```

#### Step 4: Implement Retry Logic
```dart
Future<T> _retryRequest<T>(
  Future<T> Function() request, {
  int maxRetries = 3,
}) async {
  int retries = 0;
  
  while (retries < maxRetries) {
    try {
      return await request();
    } catch (e) {
      retries++;
      
      if (retries >= maxRetries) {
        rethrow;
      }
      
      print('Retry $retries/$maxRetries after 2 seconds...');
      await Future.delayed(const Duration(seconds: 2));
    }
  }
  
  throw Exception('Request failed after $maxRetries retries');
}

// Gunakan:
try {
  final user = await _retryRequest(
    () => AuthService().loginKeLaravel(email, password),
  );
} catch (e) {
  print('Final error: $e');
}
```

---

## ✅ BEST PRACTICES DEBUGGING

### 1. Always Log
```dart
// Jangan lepas print() statements
print('🔵 [REQUEST] POST /auth/login');
print('   Body: $body');
print('   Status: ${response.statusCode}');
print('   Response: ${response.body}');
```

### 2. Use Debug Console
```bash
# Flutter debug output
flutter run -v  # verbose mode, lebih detail log
```

### 3. Check Logs
```bash
# Laravel logs
tail -f storage/logs/laravel.log

# Database logs (if configured)
tail -f storage/logs/database.log
```

### 4. Use Browser DevTools
- Open http://localhost:8000 di browser untuk test endpoint
- Buka Network tab untuk lihat request/response

### 5. Use API Testing Tools
- **Postman**: Test API endpoints sebelum Flutter
- **Insomnia**: Alternative to Postman
- **REST Client VS Code Extension**: Plugin untuk VS Code

### 6. Device/Emulator Logs
```bash
# Android logcat
adb logcat | grep flutter

# iOS logs (Mac only)
xcrun simctl spawn booted log stream --predicate 'eventMessage contains "flutter"'
```

---

## 🎯 DEBUGGING WORKFLOW

Saat ada error, ikuti step ini:

1. **Cek Console Output**
   - Lihat print statements
   - Cari error message yang jelas

2. **Print Response**
   - Print raw JSON response dari server
   - Bandingkan dengan expected format

3. **Check Server Status**
   - Verify Laravel server running
   - Check server logs: `storage/logs/laravel.log`

4. **Test dengan Postman**
   - Test endpoint dengan curl atau Postman
   - Verify response format

5. **Check Model Parsing**
   - Print parsed object
   - Verify semua field ada

6. **Check Device Connection**
   - Verify device bisa reach server
   - Check network tab

7. **Simplify & Isolate**
   - Test dengan minimal code
   - Remove complexity satu per satu

8. **Search Error Message**
   - Google error message
   - Check Stack Overflow
   - Check documentation

---

**Happy Debugging! 🚀**
