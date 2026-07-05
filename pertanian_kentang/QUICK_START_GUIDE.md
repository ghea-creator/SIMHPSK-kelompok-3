# 🚀 QUICK START GUIDE - IMPLEMENTASI SINKRONISASI

## 📦 Files yang Sudah Dibuat

Semua file di bawah ini sudah dibuat dan siap digunakan:

### Dokumentasi
- ✅ `SYNC_GUIDE_LARAVEL_FLUTTER.md` - Panduan lengkap sinkronisasi
- ✅ `IMPLEMENTATION_CHECKLIST.md` - Checklist implementasi
- ✅ `TROUBLESHOOTING_SINKRONISASI.md` - Panduan troubleshooting
- ✅ `QUICK_START_GUIDE.md` - File ini

### Flutter Code - Models & Utils
```
mobile_app/lib/
├── models/
│   └── user_model.dart              ✅ User model + response wrappers
├── utils/
│   ├── constants.dart               ✅ API constants & configuration
│   └── shared_prefs.dart            ✅ Token & user data management
└── services/
    ├── api_service.dart             ✅ Generic HTTP client
    └── auth_service.dart            ✅ Login, register, logout logic
```

### Flutter Code - Examples
```
mobile_app/lib/examples/
├── login_example.dart               ✅ Complete login screen
├── register_example.dart            ✅ Complete register screen
└── quick_test_example.dart          ✅ Testing UI dengan button
```

---

## 🚀 STEP-BY-STEP IMPLEMENTATION

### STEP 1: Update IP Address (5 menit)

1. **Get IP Laptop:**
   ```bash
   # Windows - buka CMD
   ipconfig
   # Cari: IPv4 Address . . . . . . . . . . . : 192.168.1.5
   ```

2. **Update di Flutter:**
   ```dart
   // File: mobile_app/lib/utils/constants.dart
   
   class ApiConstants {
     // GANTI 192.168.1.5 dengan IP Anda
     static const String BASE_URL = 'http://192.168.1.5:8000/api';
   }
   ```

3. **Verify:**
   ```bash
   # Pastikan IP bisa diakses dari device
   ping 192.168.1.5
   ```

### STEP 2: Setup Laravel Server (5 menit)

```bash
# Terminal 1 - Run Laravel server
cd c:\laragon\www\pertanian_kentangnew\pertanian_kentang

php artisan serve --host 0.0.0.0 --port 8000

# Output:
# Laravel development server started: http://127.0.0.1:8000
```

### STEP 3: Test dengan Postman (10 menit)

#### Test Register
```
POST http://localhost:8000/api/auth/register

Headers:
Content-Type: application/json

Body (JSON):
{
  "farm_name": "Test Farm",
  "name": "Test User",
  "email": "test@example.com",
  "phone": "08123456789",
  "password": "password123",
  "password_confirmation": "password123"
}

Expected Response: 201
{
  "success": true,
  "message": "Pendaftaran berhasil!...",
  "data": {
    "id": 1,
    "name": "Test User",
    "email": "test@example.com",
    "farm_name": "Test Farm",
    "status": "pending_approval"
  }
}
```

#### Test Login
```
POST http://localhost:8000/api/auth/login

Headers:
Content-Type: application/json

Body (JSON):
{
  "email": "test@example.com",
  "password": "password123"
}

Expected Response: 200 (jika user sudah di-approve)
{
  "success": true,
  "message": "Login berhasil.",
  "data": {
    "token": "1|abcdefghijklmnop...",
    "token_type": "Bearer",
    "user": {
      "id": 1,
      "name": "Test User",
      "email": "test@example.com",
      "farm_name": "Test Farm",
      "phone": "08123456789",
      "role": "user",
      "status": "active",
      "approval": "approved"
    }
  }
}
```

### STEP 4: Approve User di Dashboard (jika perlu)

Jika user baru dengan status "pending_approval", approve dulu:

1. Buka `http://localhost:8000`
2. Login dengan admin account
3. Go to user management / approval section
4. Approve user

### STEP 5: Integrate ke Flutter App (30 menit)

#### Option A: Copy dari Example
```dart
// File: lib/screens/login_screen.dart
// Copy dari: lib/examples/login_example.dart

import 'package:mobile_app/examples/login_example.dart';

// Di main.dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginExample(),  // ← Use example widget
    );
  }
}
```

#### Option B: Integrate ke Screen Existing
```dart
// File: lib/screens/auth/login_screen.dart

import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/models/user_model.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final authService = AuthService();
  
  Future<void> _handleLogin(String email, String password) async {
    try {
      final result = await authService.loginKeLaravel(
        email: email,
        password: password,
      );
      
      final user = result['user'] as UserModel;
      
      // ✅ Navigate to home page
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home', arguments: user);
      }
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Implement your UI here
    // Call _handleLogin(email, password) saat login button pressed
    return Scaffold();
  }
}
```

### STEP 6: Test di Flutter (15 menit)

```bash
# Terminal 2 - Flutter
cd c:\laragon\www\pertanian_kentangnew\pertanian_kentang\mobile_app

# Clean & get packages
flutter clean
flutter pub get

# Run app
flutter run -v

# Di app, test:
# 1. Click Login
# 2. Input email & password yang valid
# 3. Should see success & navigate to home
```

### STEP 7: Test Full Flow (30 menit)

**Flow: Register → Approve → Login → Access Data**

1. **Register** via Flutter
   ```dart
   AuthService().registerKeLaravel(...)
   ```

2. **Approve** di Laravel dashboard
   - Login ke http://localhost:8000
   - Approve user yang baru register

3. **Login** via Flutter
   ```dart
   AuthService().loginKeLaravel(email, password)
   ```

4. **Verify** token tersimpan
   ```dart
   final token = await TokenManager.getToken();
   print('Token: $token');
   ```

5. **Access Protected Endpoint**
   ```dart
   final user = await AuthService().getCurrentUser();
   ```

---

## 🎯 COMMON IMPLEMENTATION PATTERNS

### Pattern 1: Splash Screen dengan Auth Check
```dart
// lib/screens/splash_screen.dart

import 'package:mobile_app/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authService = AuthService();
    
    // Wait 2 seconds untuk splash effect
    await Future.delayed(const Duration(seconds: 2));
    
    // Check if user is logged in
    final isLoggedIn = await authService.isLoggedIn();
    
    if (mounted) {
      if (isLoggedIn) {
        // User sudah login, go to home
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // User belum login, go to login
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.agriculture, size: 64),
            const SizedBox(height: 16),
            const Text('Pertanian Kentang'),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
```

### Pattern 2: Protected Routes dengan Guard
```dart
// lib/main.dart

import 'package:mobile_app/services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
      onGenerateRoute: (settings) {
        // Protect routes
        final allowedPublicRoutes = ['/login', '/register', '/splash'];
        
        if (!allowedPublicRoutes.contains(settings.name)) {
          // Protected route - check if logged in
          return _buildProtectedRoute(context, settings);
        }
        
        return null;
      },
    );
  }

  Route? _buildProtectedRoute(BuildContext context, RouteSettings settings) {
    return FutureBuilder<bool>(
      future: AuthService().isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialPageRoute(
            builder: (_) => const SplashScreen(),
          );
        }
        
        final isLoggedIn = snapshot.data ?? false;
        
        if (!isLoggedIn) {
          return MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          );
        }
        
        return null;
      },
    );
  }
}
```

### Pattern 3: User Profile Display
```dart
// lib/screens/profile_screen.dart

import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await authService.getCurrentUser();
      
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    try {
      await authService.logout();
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load user'),
              ElevatedButton(
                onPressed: _loadCurrentUser,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: const Text('Name'),
                      subtitle: Text(_currentUser!.name),
                    ),
                    ListTile(
                      title: const Text('Email'),
                      subtitle: Text(_currentUser!.email),
                    ),
                    ListTile(
                      title: const Text('Farm Name'),
                      subtitle: Text(_currentUser!.farmName),
                    ),
                    ListTile(
                      title: const Text('Phone'),
                      subtitle: Text(_currentUser!.phone),
                    ),
                    ListTile(
                      title: const Text('Status'),
                      subtitle: Text(_currentUser!.status),
                    ),
                    ListTile(
                      title: const Text('Approval'),
                      subtitle: Text(_currentUser!.approval),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🎨 UI Integration Examples

### Login Screen Widget
```dart
// Copy dari: lib/examples/login_example.dart
// Atau lihat file tersebut untuk implementasi lengkap
```

### Register Screen Widget
```dart
// Copy dari: lib/examples/register_example.dart
// Atau lihat file tersebut untuk implementasi lengkap
```

---

## ✅ VERIFICATION CHECKLIST

Sebelum production, pastikan:

- [ ] Laravel server berfungsi dengan baik
- [ ] All endpoints tested dengan Postman
- [ ] Flutter dapat connect ke server
- [ ] Login flow working (register → login → home)
- [ ] Token properly stored & retrieved
- [ ] User data properly parsed
- [ ] Logout properly clears token
- [ ] Error handling implemented
- [ ] Network timeout configured
- [ ] Offline scenario handled
- [ ] App relaunch maintains login state
- [ ] Security checks passed

---

## 📚 REFERENCED FILES

Semua file dokumentasi dan code tersedia di:

```
pertanian_kentang/
├── SYNC_GUIDE_LARAVEL_FLUTTER.md          (Panduan lengkap)
├── IMPLEMENTATION_CHECKLIST.md            (Checklist)
├── TROUBLESHOOTING_SINKRONISASI.md        (Troubleshooting)
├── QUICK_START_GUIDE.md                   (File ini)
│
└── mobile_app/lib/
    ├── models/user_model.dart
    ├── services/api_service.dart
    ├── services/auth_service.dart
    ├── utils/constants.dart
    ├── utils/shared_prefs.dart
    └── examples/
        ├── login_example.dart
        ├── register_example.dart
        └── quick_test_example.dart
```

---

## 🚀 NEXT STEPS

Setelah basic auth bekerja:

1. **Add More Endpoints**
   - Seasons API
   - Harvests API
   - Stock API
   - Sales API

2. **Implement State Management**
   - Provider pattern
   - Riverpod
   - GetX

3. **Add Features**
   - Image upload untuk profile
   - Offline sync
   - Background sync dengan WorkManager
   - Push notifications

4. **Production Deployment**
   - Move to HTTPS
   - Setup proper error tracking (Sentry)
   - Load testing
   - Security audit

---

## 💡 TIPS

1. **Always test API first dengan Postman** sebelum integrate ke Flutter
2. **Print response JSON** untuk debug parsing errors
3. **Use meaningful error messages** untuk better UX
4. **Implement retry logic** untuk network issues
5. **Test offline scenario** untuk handle connection loss
6. **Keep token secure** - jangan expose token di logs (production)

---

**Good luck with implementation! 🎉**

Untuk questions atau issues, refer to:
- `TROUBLESHOOTING_SINKRONISASI.md` - Error solutions
- `SYNC_GUIDE_LARAVEL_FLUTTER.md` - Detailed technical guide
- `IMPLEMENTATION_CHECKLIST.md` - Complete checklist
