# SIMHPSK - Quick Reference Guide

Panduan cepat & shortcut untuk development dan operasional SIMHPSK.

## 📱 Demo Credentials

### Admin User
```
Email: admin@simhpsk.com
Password: admin123
Role: admin
```

### Super Admin User
```
Email: superadmin@simhpsk.com
Password: superadmin123
Role: super_admin
```

---

## 🚀 Quick Start Commands

```bash
# Navigate to project
cd c:\laragon\www\pertanian_kentang

# Setup project
composer install
php artisan key:generate

# Prepare database
php artisan migrate
php artisan db:seed

# Start development server
php artisan serve

# Access aplikasi
http://localhost:8000
```

---

## 📁 Project Structure at a Glance

```
pertanian_kentang/
├── app/
│   ├── Http/Controllers/        → Business logic
│   ├── Models/                  → Database models
│   ├── Helpers/                 → Helper functions
│   └── Providers/               → Service providers
│
├── database/
│   ├── migrations/              → Database schemas
│   ├── seeders/                 → Demo data
│   └── factories/               → Test data generators
│
├── resources/
│   ├── views/
│   │   ├── layouts/             → Master layouts
│   │   ├── components/          → Reusable components
│   │   ├── auth/                → Login/Register pages
│   │   ├── dashboard/           → Admin pages
│   │   └── super-admin/         → Super admin pages
│   └── css/
│       └── app.css              → Custom styling
│
├── routes/
│   └── web.php                  → Web routes
│
├── config/                      → Configuration files
├── storage/                     → Logs, cache, uploads
├── tests/                       → Test files
│
├── .env.example                 → Environment template
├── README.md                    → Main documentation
├── API_DOCUMENTATION.md         → API reference
├── DEVELOPMENT_GUIDE.md         → Development tips
├── DEPLOYMENT_GUIDE.md          → Deployment steps
├── TROUBLESHOOTING_GUIDE.md     → Common issues
├── IMPLEMENTATION_CHECKLIST.md  → Feature checklist
└── composer.json                → Dependencies
```

---

## 🎨 Key Files to Know

| File | Purpose |
|------|---------|
| `routes/web.php` | All route definitions |
| `app/Models/` | Data models |
| `app/Http/Controllers/` | Request handlers |
| `resources/views/` | UI templates |
| `resources/css/app.css` | Styling |
| `database/migrations/` | Database schemas |
| `database/seeders/` | Initial data |
| `.env` | Environment config |
| `config/app.php` | Application config |

---

## 🌐 URL Routes Quick Reference

### Public Routes
```
GET  /                          → Landing page
GET  /login                     → Login form
POST /login                     → Process login
GET  /register                  → Register form
POST /register                  → Process registration
```

### Admin Routes (Protected)
```
GET  /dashboard                 → Main dashboard
GET  /seasons                   → List seasons
POST /seasons                   → Create season
PUT  /seasons/{id}              → Update season
DELETE /seasons/{id}            → Delete season

GET  /harvests                  → List harvests
POST /harvests                  → Create harvest
GET  /stock                     → Stock status
POST /stock/outgoing            → Record outgoing stock
GET  /sales                     → List sales
POST /sales                     → Create sale

GET  /reports/profit-loss       → P&L report
GET  /reports/target-vs-actual  → Target vs Actual
GET  /settings                  → Settings page
POST /settings/profile          → Update profile
POST /settings/password         → Change password
```

### Super Admin Routes (Protected)
```
GET  /super-admin               → Super admin dashboard
GET  /super-admin/users         → List users
POST /super-admin/users         → Create user
GET  /super-admin/landing-editor → Edit landing page
POST /super-admin/landing-editor → Update landing
GET  /super-admin/menus         → List menus
POST /super-admin/menus         → Create menu
```

---

## 🎯 Common Tasks & Commands

### Database Operations

```bash
# Create migration
php artisan make:migration create_table_name

# Run migrations
php artisan migrate

# Rollback last migration
php artisan migrate:rollback

# Reset all migrations
php artisan migrate:reset

# Fresh migration (WARNING: deletes all data)
php artisan migrate:fresh --seed

# Check migration status
php artisan migrate:status
```

### Model & Controller Creation

```bash
# Create model with migration
php artisan make:model ModelName -m

# Create model with all
php artisan make:model ModelName -mfs

# Create controller
php artisan make:controller ControllerName --resource

# Create with model binding
php artisan make:controller PostController -m Post -r
```

### Testing

```bash
# Run all tests
./vendor/bin/phpunit

# Run specific test
./vendor/bin/phpunit tests/Feature/AuthTest.php

# Run with coverage
./vendor/bin/phpunit --coverage-html coverage/
```

### Cache & Optimization

```bash
# Clear all cache
php artisan cache:clear

# Clear config cache
php artisan config:clear

# Clear route cache
php artisan route:clear

# Clear view cache
php artisan view:clear

# Optimize for production
php artisan optimize
```

### Code Quality

```bash
# Format code with Pint
./vendor/bin/pint

# Check without fixing
./vendor/bin/pint --test

# Run tinker (REPL)
php artisan tinker
```

---

## 🔐 Security Checklist

Before deployment:

```bash
# Set production app key
APP_ENV=production

# Disable debug
APP_DEBUG=false

# Generate new app key
php artisan key:generate

# Hash config
php artisan config:cache

# Cache routes
php artisan route:cache

# Cache views
php artisan view:cache
```

---

## 📊 Database Schema Quick View

### Core Tables

| Table | Purpose |
|-------|---------|
| `users` | User accounts with roles |
| `seasons` | Planting seasons |
| `harvests` | Harvest records |
| `stock_transactions` | Stock movement log |
| `sales` | Sales transactions |
| `production_costs` | Cost tracking |
| `settings` | App configuration |
| `notifications` | User notifications |
| `dashboard_menus` | Custom menu items |
| `landing_contents` | Landing page content |

### Key Fields

**Users Table**
```
id, name, email, password, farm_name, phone, role, status, approval, created_at
```

**Harvests Table**
```
id, season_id, date, weight_kg, notes, photo, status, created_at
```

**Sales Table**
```
id, date, buyer_name, weight_kg, price_per_kg, total, payment_status
```

**Settings Table**
```
key, value (min_stock, max_stock, notifications, etc.)
```

---

## 🎨 Color Scheme

```css
Primary Color:    #1A7A4A (Green)
Accent Color:     #F5A623 (Orange/Yellow)
Success Color:    #27AE60 (Green)
Danger Color:     #E74C3C (Red)
Info Color:       #3498DB (Blue)
Warning Color:    #F39C12 (Orange)
Secondary Color:  #7F8C8D (Gray)
```

---

## 📱 Bootstrap Breakpoints

```
xs: < 576px      (Mobile)
sm: ≥ 576px      (Phone)
md: ≥ 768px      (Tablet)
lg: ≥ 992px      (Laptop)
xl: ≥ 1200px     (Desktop)
xxl: ≥ 1400px    (Large Desktop)
```

Usage in classes:
```html
<div class="col-12 col-md-6 col-lg-4">
    <!-- 12 cols mobile, 6 cols tablet, 4 cols desktop -->
</div>
```

---

## 🔍 Common Blade Syntax

```blade
<!-- Variables -->
{{ $variable }}
{{ $variable ?? 'default' }}

<!-- Conditionals -->
@if (condition)
@elseif (condition)
@else
@endif

<!-- Loops -->
@foreach ($items as $item)
    {{ $item }}
@endforeach

@forelse ($items as $item)
    {{ $item }}
@empty
    <p>No items</p>
@endforelse

<!-- Auth -->
@auth
    <p>User logged in</p>
@endauth

@guest
    <p>User not logged in</p>
@endguest

<!-- Errors -->
@error('field')
    <span>{{ $message }}</span>
@enderror

<!-- Components -->
@component('components.stat-card')
    @slot('title') Title @endslot
@endcomponent

<!-- Or shorthand -->
<x-stat-card title="Title" />
```

---

## 🖥️ HTTP Methods Quick Reference

```
GET     - Retrieve data (safe, no side effects)
POST    - Create new resource
PUT     - Update entire resource (idempotent)
PATCH   - Partial update
DELETE  - Remove resource
HEAD    - Like GET but no response body
OPTIONS - Describe communication options
```

In Laravel forms:
```blade
<!-- POST -->
<form method="POST" action="/resource">
    @csrf
    <!-- fields -->
</form>

<!-- PUT (via _method) -->
<form method="POST" action="/resource/1">
    @csrf
    @method('PUT')
    <!-- fields -->
</form>

<!-- DELETE -->
<form method="POST" action="/resource/1">
    @csrf
    @method('DELETE')
    <!-- fields -->
</form>
```

---

## 🧪 Debugging Helpers

### Dump & Die
```php
dd($variable);          // Dump and die
dump($variable);        // Dump without dying
```

### Query Debugging
```php
DB::enableQueryLog();
// Your code here
dd(DB::getQueryLog());
```

### Tinker Commands
```bash
php artisan tinker

>>> App\Models\User::all();
>>> App\Models\Harvest::where('weight_kg', '>', 500)->get();
>>> Auth::user();
>>> exit
```

---

## 📋 Environment Variables (.env)

```env
# App
APP_NAME=SIMHPSK
APP_ENV=local|production
APP_DEBUG=true|false
APP_URL=http://localhost:8000

# Database
DB_CONNECTION=mysql|sqlite
DB_HOST=127.0.0.1
DB_DATABASE=simhpsk
DB_USERNAME=root
DB_PASSWORD=

# Mail
MAIL_MAILER=log|smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=
MAIL_PASSWORD=

# Cache
CACHE_DRIVER=file|redis
SESSION_DRIVER=file|cookie

# Queue
QUEUE_CONNECTION=sync|database|redis
```

---

## 💡 Tips & Tricks

### 1. Use Route Model Binding
```php
// In route
Route::get('/harvest/{harvest}', [HarvestController::class, 'show']);

// In controller - $harvest is auto-injected
public function show(Harvest $harvest) {
    return view('harvest.show', ['harvest' => $harvest]);
}
```

### 2. Use Eager Loading
```php
// Bad - N+1 query problem
$harvests = Harvest::all();
foreach ($harvests as $harvest) {
    echo $harvest->season->name;
}

// Good - Single query
$harvests = Harvest::with('season')->get();
```

### 3. Use Transactions for Related Updates
```php
DB::transaction(function () {
    Sale::create($data);
    StockTransaction::create($stockData);
    // Both or neither
});
```

### 4. Use Collections
```php
$harvests = Harvest::all();
$totalWeight = $harvests->sum('weight_kg');
$highYield = $harvests->where('weight_kg', '>', 500);
```

### 5. Use Accessors/Mutators
```php
// In model
protected $casts = [
    'weight_kg' => 'decimal:2',
    'price' => 'decimal:2',
];
```

---

## 🚨 Emergency Procedures

### Site is down - Quick recovery

```bash
# 1. Check if Laravel is running
php artisan serve

# 2. Check database connection
mysql -u root -p simhpsk

# 3. Clear all cache
php artisan cache:clear
php artisan view:clear
php artisan config:clear

# 4. Check logs
tail -f storage/logs/laravel.log

# 5. Enable debug
APP_DEBUG=true

# 6. Fresh migration if needed
php artisan migrate:fresh --seed
```

---

## 📞 Support Resources

- **Laravel Docs**: https://laravel.com/docs/11
- **Bootstrap Docs**: https://getbootstrap.com/docs/5.3
- **MySQL Reference**: https://dev.mysql.com/doc/
- **PHP Manual**: https://www.php.net/manual/
- **Chart.js Docs**: https://www.chartjs.org/docs/latest

---

**Keep this handy for quick reference!**

Last Updated: 2024
