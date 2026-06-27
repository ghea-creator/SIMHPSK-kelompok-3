# 📚 INDEX - PANDUAN SINKRONISASI DATA LARAVEL 11 ↔ FLUTTER

## 🎯 Tujuan Proyek

Implementasi fitur sinkronisasi data **2-WAY** (dua arah) antara:
- **Backend:** Laravel 11 REST API dengan Sanctum Authentication
- **Mobile:** Flutter App dengan HTTP & SharedPreferences

### Use Cases
1. ✅ User registrasi di Web Laravel → Login di Flutter dengan data yang sama
2. ✅ User input data (harvest, season, stock) → Sync ke database pusat
3. ✅ User logout di Flutter → Token revoke di server
4. ✅ User approval workflow → Kontroled di dashboard web

---

## 📂 STRUKTUR DOKUMENTASI

### 1. 🔧 SYNC_GUIDE_LARAVEL_FLUTTER.md
**Panduan implementasi lengkap (BACA INI PERTAMA)**

Isi:
- Overview arsitektur & alur komunikasi
- Struktur response JSON standard
- Setup Laravel API (AuthController, routes, Sanctum)
- Setup Flutter Client (dependencies, structure)
- Implementasi Models, Services, Constants
- Flow login & register
- Contoh response JSON real

**Kapan baca:**
- Saat pertama kali understand architecture
- Saat implementasi fitur baru
- Saat ada question tentang format response

**File size:** ~500 lines
**Waktu baca:** 45-60 menit

---

### 2. 🚀 QUICK_START_GUIDE.md
**Panduan mulai cepat dengan step-by-step (BACA KEDUA)**

Isi:
- Daftar files yang sudah dibuat
- 7 step implementasi dari 0 sampai production-ready
- Testing dengan Postman
- Integrasi ke Flutter app
- Common patterns (splash screen, protected routes, profile)
- Verification checklist

**Kapan baca:**
- Saat siap mulai implementasi
- Saat stuck di step tertentu
- Saat verify semua working

**File size:** ~400 lines
**Waktu baca:** 30-45 menit

---

### 3. ✅ IMPLEMENTATION_CHECKLIST.md
**Checklist lengkap semua yang harus di-implement**

Isi:
- ✅ Checklist Laravel (controller, routes, Sanctum)
- ✅ Checklist Flutter (dependencies, files, models)
- ✅ Testing checklist (Postman, manual, edge cases)
- ✅ Debugging checklist (common issues, solutions)
- ✅ Verification checklist (security, data integrity, performance)
- ✅ Production checklist

**Kapan baca:**
- Saat pertama kali planning implementation
- Saat progress check
- Saat validate semua done sebelum production

**File size:** ~400 lines
**Waktu baca:** 20-30 menit

---

### 4. 🔧 TROUBLESHOOTING_SINKRONISASI.md
**Panduan troubleshooting 8 common errors**

Error yang di-cover:
1. ❌ "Connection refused" / "Failed host lookup"
2. ❌ "Null check operator used on a null value"
3. ❌ "type 'String' is not a subtype of type 'int'"
4. ❌ "Email atau password salah" (401)
5. ❌ "Token tidak tersimpan"
6. ❌ "Validation Error" (422)
7. ❌ "Session expired" (401 di protected endpoint)
8. ❌ "Network Error" / Timeout

Setiap error ada:
- Tanda-tanda error
- Penyebab umum
- Step-by-step solusi
- Code examples
- Best practices debugging

**Kapan baca:**
- Saat ada error
- Saat stuck di implementation
- Saat learning how to debug

**File size:** ~600 lines
**Waktu baca:** 60 menit

---

## 📦 STRUKTUR LARAVEL CODE

### Backend API - Existing Files (Sudah Ada)

```
app/Http/Controllers/
└── AuthController.php
    ├── registerApi()      → POST /api/auth/register
    ├── loginApi()         → POST /api/auth/login
    ├── logoutApi()        → POST /api/auth/logout
    └── meApi()            → GET  /api/auth/me

app/Models/
└── User.php
    └── HasApiTokens trait

routes/
└── api.php
    ├── POST   /auth/register  (public)
    ├── POST   /auth/login     (public)
    ├── POST   /auth/logout    (protected)
    └── GET    /auth/me        (protected)

config/
└── sanctum.php            (token configuration)
```

### Fitur API
- ✅ User registration dengan validation
- ✅ Password hashing dengan Hash::make()
- ✅ Login dengan validation & token generation
- ✅ Sanctum token creation (api-token)
- ✅ Protected routes dengan auth:sanctum middleware
- ✅ Logout dengan token revocation
- ✅ User data retrieval

---

## 📦 STRUKTUR FLUTTER CODE

### Mobile App - New Files (Baru Dibuat)

#### 1. **Models** - Data structures
```
mobile_app/lib/models/
└── user_model.dart                     ✅ NEW
    ├── class UserModel
    │   ├── fromJson(Map)               (factory constructor)
    │   ├── toJson() → Map
    │   └── toJsonString() → String
    ├── class LoginResponse
    │   └── fromJson(Map)
    ├── class RegisterResponse
    │   └── fromJson(Map)
    └── class ApiResponse<T>
        └── fromJson(Map, dataBuilder)
```

#### 2. **Services** - Business logic
```
mobile_app/lib/services/
├── api_service.dart                    ✅ NEW
│   ├── Singleton pattern
│   ├── get<T>()       → HTTP GET
│   ├── post<T>()      → HTTP POST
│   ├── put<T>()       → HTTP PUT
│   └── delete()       → HTTP DELETE
│   └── Auto token injection
│
└── auth_service.dart                   ✅ NEW
    ├── Singleton pattern
    ├── loginKeLaravel(email, password)
    ├── registerKeLaravel(...)
    ├── logout()
    ├── getCurrentUser()
    ├── isLoggedIn()
    └── getToken()
```

#### 3. **Utilities** - Constants & helpers
```
mobile_app/lib/utils/
├── constants.dart                      ✅ NEW
│   ├── BASE_URL          (API endpoint)
│   ├── Endpoint constants
│   └── Response codes
│
└── shared_prefs.dart                   ✅ NEW
    ├── TokenManager class
    ├── saveToken()
    ├── getToken()
    ├── saveUserData()
    ├── getUserData()
    ├── clearAll()        (logout)
    └── isLoggedIn()
```

#### 4. **Examples** - UI implementations
```
mobile_app/lib/examples/
├── login_example.dart                  ✅ NEW
│   ├── LoginExample StatefulWidget
│   ├── Email & password input
│   ├── AuthService.loginKeLaravel()
│   ├── Token saving
│   └── Error handling & dialogs
│
├── register_example.dart               ✅ NEW
│   ├── RegisterExample StatefulWidget
│   ├── Form with validation
│   ├── AuthService.registerKeLaravel()
│   ├── Success/error messages
│   └── Field validation examples
│
└── quick_test_example.dart             ✅ NEW
    ├── TestPage StatefulWidget
    ├── 7 test buttons
    ├── Real-time output display
    └── Console logging
```

---

## 🔄 DATA FLOW DIAGRAMS

### Login Flow
```
┌─────────────────────────────────────────────────────────────┐
│                   USER TAPS LOGIN BUTTON                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│      FLUTTER: Validate input (email, password)              │
│         - Check not empty                                    │
│         - Check email format                                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│   FLUTTER: AuthService.loginKeLaravel(email, password)      │
│   HTTP POST: http://192.168.x.x:8000/api/auth/login        │
│   Body: {email, password}                                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│   LARAVEL: AuthController.loginApi()                        │
│   - Validate input: required, email format                  │
│   - Find user by email: User::where('email', ...)          │
│   - Verify password: Hash::check(password, user.password)  │
│   - Check status: active, approved                          │
│   - Generate token: user->createToken('api-token')         │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│   LARAVEL: Return response (200 OK)                         │
│   {                                                          │
│     "success": true,                                         │
│     "message": "Login berhasil.",                           │
│     "code": 200,                                             │
│     "data": {                                                │
│       "token": "1|abcdefghijk...",                          │
│       "token_type": "Bearer",                               │
│       "user": { id, name, email, ... }                      │
│     }                                                        │
│   }                                                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│   FLUTTER: Parse response                                   │
│   - Check status 200                                         │
│   - Parse LoginResponse.fromJson()                          │
│   - Extract token & user                                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│   FLUTTER: Save token & user data                           │
│   - TokenManager.saveToken(token)                           │
│   - TokenManager.saveUserData(userJsonString)               │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│   FLUTTER: Navigate to home screen                          │
│   - Show user data                                           │
│   - Token ready untuk protected endpoints                   │
└─────────────────────────────────────────────────────────────┘
```

### Register Flow
```
┌────────────────────────────────────────────────┐
│  USER FILLS REGISTER FORM & TAPS REGISTER      │
└──────────┬───────────────────────────────────┘
           │
           ▼
┌────────────────────────────────────────────────┐
│  FLUTTER: Validate input                       │
│  - Check all fields not empty                  │
│  - Check email format                          │
│  - Check password >= 8 chars                   │
│  - Check password confirmation match          │
└──────────┬───────────────────────────────────┘
           │
           ▼
┌────────────────────────────────────────────────┐
│  FLUTTER: AuthService.registerKeLaravel(...)   │
│  HTTP POST: /api/auth/register                │
│  Body: {farm_name, name, email, phone,        │
│         password, password_confirmation}      │
└──────────┬───────────────────────────────────┘
           │
           ▼
┌────────────────────────────────────────────────┐
│  LARAVEL: AuthController.registerApi()         │
│  - Validate all fields                         │
│  - Check email unique                          │
│  - Hash password: Hash::make(password)        │
│  - Create user with status=active,            │
│    approval=pending                            │
└──────────┬───────────────────────────────────┘
           │
           ▼
┌────────────────────────────────────────────────┐
│  LARAVEL: Return response (201 Created)        │
│  Message: "Tunggu persetujuan admin"          │
└──────────┬───────────────────────────────────┘
           │
           ▼
┌────────────────────────────────────────────────┐
│  FLUTTER: Show success message                 │
│  "Registrasi berhasil! Tunggu approval..."     │
└────────────────────────────────────────────────┘
           │
           ▼
┌────────────────────────────────────────────────┐
│  ADMIN: Approve di Laravel dashboard           │
│  User status: active, approval: approved      │
└────────────────────────────────────────────────┘
           │
           ▼
┌────────────────────────────────────────────────┐
│  USER: Login di Flutter dengan credentials    │
│  (Lihat Login Flow di atas)                   │
└────────────────────────────────────────────────┘
```

---

## 🎯 LEARNING PATH

**Recommended reading order:**

1. **Start here:** `QUICK_START_GUIDE.md`
   - Understand step-by-step
   - Follow 7 implementation steps
   - ~30 minutes

2. **Deep dive:** `SYNC_GUIDE_LARAVEL_FLUTTER.md`
   - Understand architecture in detail
   - Learn response format
   - Study code examples
   - ~60 minutes

3. **Reference:** `TROUBLESHOOTING_SINKRONISASI.md`
   - When encounter errors
   - Learn debugging techniques
   - ~60 minutes (as needed)

4. **Verify:** `IMPLEMENTATION_CHECKLIST.md`
   - Check implementation completeness
   - Verify all working
   - ~30 minutes

---

## 🛠️ YANG SUDAH READY

### ✅ Backend (Laravel)
- [x] AuthController dengan register & login
- [x] Routes API yang tepat
- [x] Sanctum configuration
- [x] Password hashing
- [x] Token generation
- [x] Protected routes

### ✅ Frontend (Flutter)
- [x] User Model dengan factory constructors
- [x] Auth Service dengan semua methods
- [x] API Service sebagai HTTP client base
- [x] Token management dengan SharedPreferences
- [x] Constants dengan BaseUrl
- [x] 3 example UI (login, register, quick test)
- [x] Comprehensive documentation
- [x] Troubleshooting guide

---

## ⚙️ QUICK SETUP (5 minutes)

### 1. Update IP
```dart
// lib/utils/constants.dart
static const String BASE_URL = 'http://YOUR_IP:8000/api';
```

### 2. Run Laravel
```bash
php artisan serve --host 0.0.0.0 --port 8000
```

### 3. Run Flutter
```bash
flutter run
```

### 4. Test Login
- Register user (or use existing)
- Login with credentials
- Should navigate to home

---

## 📞 QUICK REFERENCE

| Topic | File |
|-------|------|
| Implementation steps | QUICK_START_GUIDE.md |
| Architecture & design | SYNC_GUIDE_LARAVEL_FLUTTER.md |
| Error solutions | TROUBLESHOOTING_SINKRONISASI.md |
| Complete checklist | IMPLEMENTATION_CHECKLIST.md |
| Login UI example | mobile_app/lib/examples/login_example.dart |
| Register UI example | mobile_app/lib/examples/register_example.dart |
| Auth service | mobile_app/lib/services/auth_service.dart |
| User model | mobile_app/lib/models/user_model.dart |
| Constants config | mobile_app/lib/utils/constants.dart |

---

## 🚀 NEXT STEPS

1. Read `QUICK_START_GUIDE.md`
2. Follow 7 implementation steps
3. Test with Postman
4. Test with Flutter
5. If error, check `TROUBLESHOOTING_SINKRONISASI.md`
6. Use `IMPLEMENTATION_CHECKLIST.md` to verify

---

## 💡 TIPS FOR SUCCESS

1. **Always test API first** dengan Postman sebelum Flutter
2. **Update IP address** sesuai laptop Anda
3. **Check console output** untuk debug messages
4. **Read error carefully** - pesan error sudah ada solusinya
5. **Verify response format** - pastikan match dengan model
6. **Test offline scenario** - implementasi error handling
7. **Keep token secure** - jangan expose di logs

---

**Last Updated:** May 28, 2026
**Status:** ✅ Ready for Implementation
**Document Version:** 1.0

---

**Selamat mengimplementasikan! 🎉**

Untuk bantuan, refer ke dokumentasi yang sesuai atau check troubleshooting guide.
