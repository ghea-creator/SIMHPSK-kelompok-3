# 📋 CHECKLIST IMPLEMENTASI SINKRONISASI LARAVEL ↔ FLUTTER

## ✅ CHECKLIST SISI LARAVEL

### Database & Model
- [x] Table `users` sudah ada dengan struktur yang tepat
- [x] Model `User` sudah di-setup dengan HasApiTokens trait
- [x] Migration users dengan kolom: id, name, email, password, farm_name, phone, role, status, approval

### Authentication Controller
- [x] File `app/Http/Controllers/AuthController.php` sudah ada
- [x] Method `registerApi()` untuk pendaftaran user baru
- [x] Method `loginApi()` untuk login dengan validation
- [x] Method `logoutApi()` untuk logout (revoke token)
- [x] Method `meApi()` untuk get current user info
- [x] Password di-hash menggunakan `Hash::make()`
- [x] Validation errors di-return dengan format yang tepat (422 status)

### Routes Setup
- [x] File `routes/api.php` sudah ada
- [x] Route `POST /api/auth/register` terdaftar (public)
- [x] Route `POST /api/auth/login` terdaftar (public)
- [x] Route `POST /api/auth/logout` terdaftar (protected with auth:sanctum)
- [x] Route `GET /api/auth/me` terdaftar (protected with auth:sanctum)
- [x] Semua protected route menggunakan middleware `auth:sanctum`

### Sanctum Configuration
- [x] Laravel Sanctum sudah diinstall (`laravel/sanctum`)
- [x] `config/sanctum.php` sudah di-publish
- [x] Database migration sanctum sudah di-run (`php artisan migrate`)
- [x] User model menggunakan trait `HasApiTokens`

### Response Format
- [x] Semua response menggunakan trait `ApiResponseTrait`
- [x] Success response: `{success: true, message: "...", code: 200, data: {...}}`
- [x] Error response: `{success: false, message: "...", code: 401/403/etc}`
- [x] User data di-return dengan field: id, name, email, farm_name, phone, role, status, approval
- [x] Token di-return dengan format: `{token: "...", token_type: "Bearer", user: {...}}`

### Testing di Postman
- [x] Test endpoint `/api/auth/register` dengan POST method
- [x] Test endpoint `/api/auth/login` dengan POST method
- [x] Test endpoint `/api/auth/me` dengan GET + Authorization header
- [x] Verify response format sesuai dengan yang diharapkan Flutter

---

## ✅ CHECKLIST SISI FLUTTER

### Dependencies
- [x] `http: ^1.6.0` di `pubspec.yaml`
- [x] `shared_preferences: ^2.2.0` di `pubspec.yaml`
- [x] `provider: ^6.0.0` di `pubspec.yaml` (optional, untuk state management)
- [x] `intl: ^0.19.0` di `pubspec.yaml` (untuk date formatting)
- [x] Run `flutter pub get` setelah update pubspec.yaml

### Folder Structure
```
lib/
├── models/
│   └── user_model.dart           ✅ Sudah dibuat
├── services/
│   ├── api_service.dart          ✅ Sudah dibuat
│   └── auth_service.dart         ✅ Sudah dibuat
├── utils/
│   ├── constants.dart            ✅ Sudah dibuat
│   └── shared_prefs.dart         ✅ Sudah dibuat
└── examples/
    ├── login_example.dart        ✅ Sudah dibuat
    ├── register_example.dart     ✅ Sudah dibuat
    └── quick_test_example.dart   ✅ Sudah dibuat
```

### Model Files
- [x] File `lib/models/user_model.dart` sudah dibuat
- [x] Class `UserModel` dengan semua field yang diperlukan
- [x] Factory constructor `UserModel.fromJson()`
- [x] Factory constructor `UserModel.fromJsonString()`
- [x] Method `toJson()` dan `toJsonString()`
- [x] Class `LoginResponse` untuk parsing login response
- [x] Class `RegisterResponse` untuk parsing register response
- [x] Class `ApiResponse<T>` sebagai generic wrapper

### Service Files
- [x] File `lib/services/api_service.dart` sudah dibuat
- [x] Singleton pattern untuk API Service
- [x] Method `get<T>()` untuk GET request
- [x] Method `post<T>()` untuk POST request
- [x] Method `put<T>()` untuk PUT request
- [x] Method `delete()` untuk DELETE request
- [x] Automatic token injection di Authorization header
- [x] Error handling (401, 403, 422, 500, etc)

### Auth Service
- [x] File `lib/services/auth_service.dart` sudah dibuat
- [x] Singleton pattern untuk Auth Service
- [x] Method `loginKeLaravel(email, password)`
- [x] Method `registerKeLaravel(...)`
- [x] Method `logout()`
- [x] Method `getCurrentUser()`
- [x] Method `isLoggedIn()`
- [x] Method `getToken()`
- [x] Automatic token & user data saving ke SharedPreferences

### Constants & Configuration
- [x] File `lib/utils/constants.dart` sudah dibuat
- [x] Class `ApiConstants` dengan BASE_URL
- [x] ⚠️ BASE_URL sudah di-update dengan IP laptop yang benar
- [x] Endpoint constants: LOGIN, REGISTER, LOGOUT, ME, etc
- [x] SharedPrefsKeys constants
- [x] ResponseCode constants
- [x] UserStatus & ApprovalStatus constants

### Token Management
- [x] File `lib/utils/shared_prefs.dart` sudah dibuat
- [x] Class `TokenManager` untuk manage token & user data
- [x] Method `saveToken(token)`
- [x] Method `getToken()`
- [x] Method `saveUserData(jsonString)`
- [x] Method `getUserData()`
- [x] Method `saveUserId(id)`
- [x] Method `saveUserEmail(email)`
- [x] Method `clearAll()` untuk logout
- [x] Method `isLoggedIn()` untuk check status

### Example Files
- [x] File `lib/examples/login_example.dart` sudah dibuat
- [x] File `lib/examples/register_example.dart` sudah dibuat
- [x] File `lib/examples/quick_test_example.dart` sudah dibuat
- [x] Semua contoh sudah lengkap dengan error handling
- [x] Semua contoh sudah lengkap dengan validasi input

---

## 🧪 TESTING CHECKLIST

### Setup Testing Environment
- [ ] Laravel server running: `php artisan serve --host 0.0.0.0 --port 8000`
- [ ] Database migration sudah di-run
- [ ] Database seeding done (optional, untuk test data)
- [ ] IP address di constants.dart sudah di-update dengan IP laptop
- [ ] Flutter emulator atau device sudah siap

### Manual Testing di Postman
- [ ] POST `/api/auth/register` dengan test data
  - Request body: farmName, name, email, phone, password, password_confirmation
  - Response: 201 status dengan user data
  
- [ ] POST `/api/auth/login` dengan test data
  - Request body: email, password
  - Response: 200 status dengan token dan user data
  
- [ ] GET `/api/auth/me` dengan Authorization header
  - Header: Authorization: Bearer <token>
  - Response: 200 status dengan user data
  
- [ ] POST `/api/auth/logout` dengan Authorization header
  - Header: Authorization: Bearer <token>
  - Response: 200 status

### Flutter Testing
- [ ] Run `flutter pub get` untuk download dependencies
- [ ] Replace login_example.dart ke test widget untuk test login
- [ ] Test login dengan email & password yang valid
  - Expected: Login berhasil, token tersimpan, navigasi ke home
  - Verify: Token ada di SharedPreferences
  - Verify: User data ada di SharedPreferences

- [ ] Test register
  - Input: form data lengkap
  - Expected: 201 response, success message
  - Verify: User ada di database dengan status pending

- [ ] Test offline scenario
  - Disable network/WiFi
  - Coba login
  - Expected: Network error message

- [ ] Test invalid credentials
  - Coba login dengan email salah
  - Expected: "Email atau password salah"
  - Coba login dengan password salah
  - Expected: "Email atau password salah"

- [ ] Test validation error
  - Coba register dengan email yang sudah ada
  - Expected: Validation error message
  - Coba register dengan password tidak cocok
  - Expected: Password validation error

- [ ] Test token expiration
  - Manual delete token dari SharedPreferences
  - Coba akses protected endpoint
  - Expected: 401 error, redirect to login

---

## 🔍 DEBUGGING CHECKLIST

### Common Issues & Solutions

#### ❌ "Connection refused" / "Failed host lookup"
- [ ] Check Laravel server running: `php artisan serve`
- [ ] Check IP address di constants.dart (gunakan `ipconfig` untuk get IP)
- [ ] Check firewall tidak block port 8000
- [ ] Untuk Android emulator gunakan: `http://10.0.2.2:8000/api`
- [ ] Untuk iOS simulator gunakan: `http://localhost:8000/api`

#### ❌ "Null check operator used on a null value"
- [ ] Check response JSON dari Laravel (print di console)
- [ ] Verify UserModel.fromJson() menggunakan `?? defaultValue`
- [ ] Verify semua field di response matching dengan model
- [ ] Check cast type: `as int?`, `as String?`, dll

#### ❌ "type 'String' is not a subtype of type 'int'"
- [ ] Check JSON response field type di Laravel
- [ ] Verify type casting di model: `json['id'] as int?`
- [ ] Print raw response untuk debug field mismatch

#### ❌ "401 Unauthorized"
- [ ] Check token dikirim di header: `Authorization: Bearer $token`
- [ ] Check token tidak expired
- [ ] Check token disimpan dengan benar di SharedPreferences
- [ ] Verify endpoint dilindungi dengan `auth:sanctum` middleware

#### ❌ "422 Validation Error"
- [ ] Check validation rules di Laravel
- [ ] Check request body field names (snake_case vs camelCase)
- [ ] Check required fields tidak ada yang kosong
- [ ] Print error response untuk lihat detailed error message

#### ❌ "Password hashing mismatch"
- [ ] Check password di-hash dengan `Hash::make()` saat register
- [ ] Check password di-verify dengan `Hash::check()` saat login
- [ ] Verify password field tidak di-cast ke hashed di model casts

#### ❌ Token tidak tersimpan
- [ ] Check SharedPreferences berhasil initialize
- [ ] Check `TokenManager.saveToken()` berhasil di-await
- [ ] Check SharedPreferencesKeys.ACCESS_TOKEN key tidak bentrok

#### ❌ API response parsing gagal
- [ ] Print full JSON response: `print('Response: ${response.body}')`
- [ ] Check response structure match dengan model
- [ ] Check field names: snake_case dari Laravel
- [ ] Verify factory constructors handle null values

---

## 📊 VERIFICATION CHECKLIST

### Security
- [ ] Password tidak pernah di-print atau log ke console (production)
- [ ] Token di-simpan di secure storage (tidak hardcode)
- [ ] Authorization header menggunakan `Bearer` scheme
- [ ] Protected endpoints require valid token (auth:sanctum)
- [ ] CORS configuration sudah di-set dengan benar

### Data Integrity
- [ ] User data di-database match dengan response di API
- [ ] Email di-validate unique saat register
- [ ] Phone format sudah valid
- [ ] Farm name tidak kosong
- [ ] Status & approval fields konsisten

### Error Handling
- [ ] Semua exception di-catch dan di-handle
- [ ] User-friendly error message di-tampilkan
- [ ] Network error di-handle dengan graceful
- [ ] Timeout di-handle (set timeout di request)
- [ ] Validation error di-parse dengan benar

### Performance
- [ ] Singleton pattern used untuk API & Auth Service
- [ ] HTTP request tidak duplicate (check network tab)
- [ ] Token caching berfungsi dengan baik
- [ ] Large response handling tested
- [ ] Pagination implemented (jika perlu)

### Code Quality
- [ ] Dokumentasi lengkap dengan comments
- [ ] Code style konsisten (naming convention, formatting)
- [ ] No unused imports atau variables
- [ ] No hardcode values (use constants)
- [ ] Type safety: avoid dynamic, use specific types

---

## 📝 DOKUMENTASI LENGKAP

- [x] File: SYNC_GUIDE_LARAVEL_FLUTTER.md (panduan lengkap)
- [x] File: API_DOCUMENTATION.md (sudah ada di Laravel)
- [x] Code comments: Setiap method sudah ada dokumentasi
- [x] Examples: 3 file contoh implementasi
- [x] This checklist: Sudah lengkap dan detail

---

## 🚀 READY FOR PRODUCTION?

Sebelum go production, pastikan:

- [ ] Security review done
- [ ] Load testing completed
- [ ] Database backup strategy ready
- [ ] Error monitoring setup (Sentry/similar)
- [ ] API rate limiting configured
- [ ] HTTPS/SSL certificate ready
- [ ] Token refresh mechanism implemented (if needed)
- [ ] User data encryption (if sensitive data)
- [ ] Audit logging implemented
- [ ] Disaster recovery plan ready

---

## 📞 SUPPORT & DEBUGGING

Jika ada error, debug dengan urutan ini:

1. **Check Laravel Server**
   ```bash
   php artisan serve --host 0.0.0.0 --port 8000
   ```

2. **Check Network Connection**
   - Ping IP dari Flutter device ke laptop
   - Cek firewall port 8000

3. **Check Response Format**
   - Print JSON response di console
   - Validate dengan online JSON validator

4. **Check Model Parsing**
   - Print parsed UserModel
   - Verify semua field tersisi

5. **Check Token Management**
   - Print token dari SharedPreferences
   - Verify token format valid

6. **Check Error Logs**
   - Laravel logs: `storage/logs/laravel.log`
   - Flutter console: Debug output
   - Database logs (if configured)

---

**Last Updated:** May 28, 2026
**Status:** ✅ Ready for Implementation
