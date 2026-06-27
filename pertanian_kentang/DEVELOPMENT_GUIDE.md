# SIMHPSK - Development Guide

Panduan untuk development dan testing SIMHPSK secara lokal.

## Prerequisites

- PHP 8.2+
- MySQL 5.7+ atau SQLite
- Composer
- Node.js & NPM (opsional)
- Git

## Quick Start

### 1. Setup Project
```bash
# Clone atau navigate ke project
cd c:\laragon\www\pertanian_kentang

# Install dependencies
composer install

# Generate app key
php artisan key:generate

# Create .env file
cp .env.example .env
```

### 2. Database Configuration

Edit `.env`:
```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=simhpsk
DB_USERNAME=root
DB_PASSWORD=
```

### 3. Run Migrations
```bash
php artisan migrate

# If you want to seed demo data
php artisan db:seed
```

### 4. Start Development Server
```bash
php artisan serve
```

Access aplikasi di: `http://localhost:8000`

## Demo Credentials

```
Admin:
Email: admin@simhpsk.com
Password: admin123

Super Admin:
Email: superadmin@simhpsk.com
Password: superadmin123
```

## Database Commands

### Reset Database
```bash
# Drop semua tabel dan jalankan ulang migrasi
php artisan migrate:fresh

# Reset dengan seeding
php artisan migrate:fresh --seed
```

### Rollback Migrations
```bash
# Undo last migration
php artisan migrate:rollback

# Undo all migrations
php artisan migrate:reset

# Undo specific migration
php artisan migrate:rollback --step=1
```

### Create Migration
```bash
php artisan make:migration create_table_name

# With model
php artisan make:model ModelName -m
```

### Seed Database
```bash
# Run all seeders
php artisan db:seed

# Run specific seeder
php artisan db:seed --class=UserSeeder
```

## Development Tasks

### Create Model
```bash
php artisan make:model ModelName

# With migration
php artisan make:model ModelName -m

# With factory & seeder
php artisan make:model ModelName -mfs
```

### Create Controller
```bash
php artisan make:controller ControllerName

# RESTful controller
php artisan make:controller ControllerName --resource

# With model binding
php artisan make:controller ControllerName -m ModelName -r
```

### Create Migration
```bash
# For creating new table
php artisan make:migration create_table_name --create=table_name

# For modifying table
php artisan make:migration add_column_to_table_name --table=table_name
```

### Create Factory
```bash
php artisan make:factory FactoryName

# With model
php artisan make:factory FactoryName -m ModelName
```

### Create Seeder
```bash
php artisan make:seeder SeederName
```

## Testing

### Run Tests
```bash
# Run all tests
./vendor/bin/phpunit

# Run specific test
./vendor/bin/phpunit tests/Feature/AuthenticationTest.php

# Run with coverage
./vendor/bin/phpunit --coverage-html coverage/
```

### Create Test
```bash
php artisan make:test TestName

# Feature test
php artisan make:test TestName --type=feature

# Unit test
php artisan make:test TestName --unit
```

## Code Quality

### Run Linting
```bash
# Using Laravel Pint (built-in PHP-CS-Fixer wrapper)
./vendor/bin/pint

# Check without fixing
./vendor/bin/pint --test
```

### Static Analysis
```bash
# Using Laravel Tinker for analysis
php artisan tinker
```

## Debugging

### Laravel Tinker
```bash
php artisan tinker

# Try commands
>>> $user = App\Models\User::first();
>>> $user->email;
>>> App\Models\Setting::get('min_stock');
```

### Debug Bar (Install if needed)
```bash
composer require barryvdh/laravel-debugbar --dev

# Auto-loaded in development
```

## Useful Routes

```bash
# View all routes
php artisan route:list

# View specific routes
php artisan route:list --name=harvest
```

## Cache Commands

### Clear Cache
```bash
# Clear all cache
php artisan cache:clear

# Clear config cache
php artisan config:clear

# Clear route cache
php artisan route:clear

# Clear view cache
php artisan view:clear
```

## Development Directory Structure

```
app/
├── Http/
│   ├── Controllers/     # Aplikasi logic
│   └── Middleware/      # Custom middleware
├── Models/              # Database models
└── Helpers/             # Helper functions

database/
├── migrations/          # Schema definitions
├── factories/           # Model factories untuk testing
└── seeders/             # Database seeders

resources/
├── views/               # Blade templates
│   ├── layouts/         # Master layouts
│   ├── components/      # Reusable components
│   ├── pages/           # Page views
│   └── super-admin/     # Super admin views
├── css/                 # Stylesheets
└── js/                  # JavaScript

routes/
└── web.php              # Web routes

tests/
├── Feature/             # Feature tests
└── Unit/                # Unit tests

config/
├── app.php              # Application config
├── database.php         # Database config
├── auth.php             # Auth config
└── ...                  # Other configs
```

## Git Workflow

### Commit Changes
```bash
# Check status
git status

# Add changes
git add .

# Commit
git commit -m "Feature: Add harvest management"
```

### Branching
```bash
# Create feature branch
git checkout -b feature/harvest-management

# Push to remote
git push origin feature/harvest-management

# Create pull request on GitHub
```

### Branch Naming Conventions
- `feature/` - New features
- `fix/` - Bug fixes
- `refactor/` - Code refactoring
- `test/` - Test additions
- `docs/` - Documentation

## Environment Variables

### Development (.env)
```
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost:8000

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_DATABASE=simhpsk
DB_USERNAME=root
DB_PASSWORD=

MAIL_MAILER=log
```

### Testing (.env.testing)
```
APP_ENV=testing
APP_DEBUG=true

DB_CONNECTION=sqlite
DB_DATABASE=:memory:

MAIL_MAILER=log
```

## Common Issues

### CORS Error
**Solution:** Check `config/cors.php` dan pastikan domain sudah di-allow

### Session Not Persisting
```bash
php artisan session:table
php artisan migrate
```

### Migration Error
```bash
# Check migration status
php artisan migrate:status

# Reset dan coba lagi
php artisan migrate:fresh
```

### Permission Denied on storage/
```bash
chmod -R 755 storage/
chmod -R 755 bootstrap/cache/
```

### Composer memory limit
```bash
php -d memory_limit=-1 /usr/bin/composer install
```

## IDE Setup

### VS Code Extensions
- Laravel Extension Pack
- PHP Intelephense
- Blade syntax highlighting
- Thunder Client (for API testing)

### PhpStorm
- Jetbrains plugins auto-configured
- Built-in Laravel support
- Database tools

## Performance Tips

1. **Use eager loading** untuk Eloquent relations
   ```php
   $users = User::with('harvests')->get();
   ```

2. **Add database indexes** untuk frequently queried columns

3. **Cache queries** menggunakan Redis atau Memcached

4. **Use artisan commands** untuk heavy operations

5. **Lazy loading** untuk large datasets

## Documentation

- [Laravel Documentation](https://laravel.com/docs/11)
- [Bootstrap Documentation](https://getbootstrap.com/docs/5.3)
- [Chart.js Documentation](https://www.chartjs.org/docs/latest)
- [Blade Templating](https://laravel.com/docs/11/views#blade-templating)

## Support

Untuk questions atau issues dalam development, buat issue di GitHub repo.
