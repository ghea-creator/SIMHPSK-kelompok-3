# SIMHPSK - Troubleshooting Guide

Panduan troubleshooting untuk masalah umum di SIMHPSK.

## 🔴 Critical Issues

### Issue: "SQLSTATE[HY000] [1045] Access denied for user"

**Symptom:** Database connection error saat login atau akses dashboard

**Solutions:**

1. **Check .env file:**
   ```bash
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=simhpsk
   DB_USERNAME=root
   DB_PASSWORD=
   ```

2. **Verify MySQL running:**
   ```bash
   # Windows (Laragon)
   MySQL harus running di system tray

   # Linux
   sudo systemctl status mysql
   ```

3. **Test connection:**
   ```bash
   mysql -h 127.0.0.1 -u root -p
   ```

4. **Clear config cache:**
   ```bash
   php artisan config:clear
   php artisan cache:clear
   ```

---

### Issue: "No application encryption key has been specified"

**Symptom:** Error saat startup aplikasi

**Solution:**
```bash
php artisan key:generate
```

---

### Issue: Migration errors / "Table already exists"

**Symptom:** Error saat `php artisan migrate`

**Solutions:**

1. **Check migration status:**
   ```bash
   php artisan migrate:status
   ```

2. **If table exists but migration not recorded:**
   ```bash
   # Reset everything
   php artisan migrate:reset
   php artisan migrate
   php artisan db:seed
   ```

3. **Fresh migration (WARNING: destroys data):**
   ```bash
   php artisan migrate:fresh --seed
   ```

4. **Rollback specific migration:**
   ```bash
   php artisan migrate:rollback --step=1
   ```

---

### Issue: Login tidak berhasil / credentials tidak bekerja

**Symptom:** Login dengan admin@simhpsk.com/admin123 tidak bisa masuk

**Solutions:**

1. **Verify users exist di database:**
   ```bash
   php artisan tinker
   >>> App\Models\User::all();
   ```

2. **If users not exist, seed database:**
   ```bash
   php artisan db:seed
   ```

3. **Check user status/approval:**
   ```bash
   php artisan tinker
   >>> $user = App\Models\User::where('email', 'admin@simhpsk.com')->first();
   >>> $user->status; // Should be 'active'
   >>> $user->approval; // Should be 'approved'
   ```

4. **Manually fix if needed:**
   ```bash
   php artisan tinker
   >>> $user = App\Models\User::where('email', 'admin@simhpsk.com')->first();
   >>> $user->status = 'active';
   >>> $user->approval = 'approved';
   >>> $user->save();
   ```

---

## 🟠 Common Issues

### Issue: "CSRF token mismatch"

**Symptom:** Form submission error

**Solutions:**

1. **Check form has CSRF token:**
   ```blade
   <form method="POST">
       @csrf
       <!-- form fields -->
   </form>
   ```

2. **Clear session:**
   ```bash
   php artisan session:flush
   ```

3. **Check session driver in .env:**
   ```
   SESSION_DRIVER=file
   ```

---

### Issue: File upload tidak bekerja / Foto tidak tersimpan

**Symptom:** Harvest photo upload gagal atau foto tidak muncul

**Solutions:**

1. **Check storage link:**
   ```bash
   php artisan storage:link
   # Should create: public/storage -> ../storage/app/public
   ```

2. **Check permissions:**
   ```bash
   chmod -R 755 storage/
   chmod -R 755 public/
   ```

3. **Check file disk in config/filesystems.php:**
   ```php
   'disks' => [
       'public' => [
           'driver' => 'local',
           'path' => storage_path('app/public'),
           'url' => env('APP_URL').'/storage',
       ],
   ]
   ```

4. **Check .env:**
   ```
   FILESYSTEM_DISK=public
   ```

---

### Issue: Dashboard page blank / tidak menampilkan data

**Symptom:** Dashboard loading tapi tidak ada konten

**Solutions:**

1. **Check Laravel logs:**
   ```bash
   tail -f storage/logs/laravel.log
   ```

2. **Enable debug mode in .env:**
   ```
   APP_DEBUG=true
   ```

3. **Check database query:**
   ```bash
   php artisan tinker
   >>> App\Models\Harvest::count();
   >>> App\Models\Sale::count();
   ```

4. **Clear cache:**
   ```bash
   php artisan cache:clear
   php artisan view:clear
   ```

---

### Issue: "500 Internal Server Error"

**Symptom:** Halaman blank dengan error 500

**Solutions:**

1. **Check Laravel logs:**
   ```bash
   # Full log
   cat storage/logs/laravel.log | tail -50
   
   # Follow real-time
   tail -f storage/logs/laravel.log
   ```

2. **Enable debug:**
   ```
   APP_DEBUG=true
   ```

3. **Check PHP errors:**
   ```bash
   php artisan tinker
   >>> // Try commands manually
   ```

4. **Check app key:**
   ```bash
   php artisan key:generate
   ```

---

### Issue: Chart tidak tampil di report

**Symptom:** Laporan menampilkan tapi chart area kosong

**Solutions:**

1. **Check Chart.js CDN:**
   ```html
   <!-- In view, check CDN link valid -->
   <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
   ```

2. **Check chart container:**
   ```blade
   <canvas id="profitChart"></canvas>
   
   <script>
       var ctx = document.getElementById('profitChart');
       if (ctx) {
           // Chart initialization
       }
   </script>
   ```

3. **Check data passed to view:**
   ```php
   // In controller
   return view('reports.profit-loss', [
       'revenue' => $revenue,
       'costs' => $costs,
       'profit' => $profit,
   ]);
   ```

---

### Issue: Export buttons tidak bekerja

**Symptom:** "Export PDF" atau "Export Excel" button ada tapi tidak jalan

**Solutions:**

This is a known limitation - export functionality UI is ready but backend logic not implemented yet.

**To implement:**

1. **Install package:**
   ```bash
   composer require maatwebsite/excel
   composer require barryvdh/laravel-dompdf
   ```

2. **Create export class:**
   ```bash
   php artisan make:export ReportExport
   ```

3. **Create export method in controller:**
   ```php
   public function exportPDF($id) {
       // Implementation
   }
   ```

---

### Issue: Notification bell tidak menampilkan unread count

**Symptom:** Bell icon ada tapi tidak ada angka unread

**Solutions:**

1. **Check notifications di database:**
   ```bash
   php artisan tinker
   >>> App\Models\Notification::where('is_read', false)->count();
   ```

2. **Check topbar component:**
   ```blade
   <!-- In components/topbar.blade.php -->
   <span class="badge bg-danger">
       {{ auth()->user()->notifications()->where('is_read', false)->count() }}
   </span>
   ```

3. **Manually create notification for testing:**
   ```bash
   php artisan tinker
   >>> App\Models\Notification::create([
   ...     'user_id' => 1,
   ...     'type' => 'test',
   ...     'title' => 'Test',
   ...     'message' => 'Test message',
   ... ]);
   ```

---

## 🟡 UI/UX Issues

### Issue: Sidebar responsive tidak bekerja di mobile

**Symptom:** Sidebar overlap di mobile, tidak collapse

**Solutions:**

1. **Check Bootstrap grid:**
   ```blade
   <div class="row">
       <div class="col-md-3">Sidebar</div>
       <div class="col-md-9">Content</div>
   </div>
   ```

2. **Or use Bootstrap offcanvas:**
   ```blade
   <button class="btn btn-primary" type="button" data-bs-toggle="offcanvas" data-bs-target="#sidebar">
       Menu
   </button>
   ```

---

### Issue: Form validation messages tidak tampil

**Symptom:** Form error tapi tidak ada pesan error

**Solutions:**

1. **Check controller has validation:**
   ```php
   $validated = $request->validate([
       'name' => 'required|string',
       'email' => 'required|email|unique:users',
   ]);
   ```

2. **Check view displays errors:**
   ```blade
   @error('email')
       <span class="text-danger">{{ $message }}</span>
   @enderror
   ```

3. **Check request method is POST/PUT:**
   ```blade
   <form method="POST" action="/seasons">
       @csrf
   </form>
   ```

---

### Issue: Modal tidak bisa dibuka

**Symptom:** Modal button diklik tapi modal tidak muncul

**Solutions:**

1. **Check modal HTML:**
   ```blade
   <div class="modal fade" id="myModal">
       <div class="modal-dialog">
           <!-- Modal content -->
       </div>
   </div>
   ```

2. **Check button trigger:**
   ```blade
   <button type="button" class="btn btn-primary" data-bs-toggle="modal" data-bs-target="#myModal">
       Open
   </button>
   ```

3. **Check Bootstrap JS included:**
   ```html
   <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
   ```

---

## 🟢 Performance Issues

### Issue: Page load lambat

**Symptom:** Dashboard atau laporan lambat loading

**Solutions:**

1. **Check database queries:**
   ```bash
   php artisan tinker
   >>> DB::enableQueryLog();
   >>> App\Models\Harvest::with('season')->get();
   >>> dd(DB::getQueryLog());
   ```

2. **Use eager loading:**
   ```php
   // Bad
   $harvests = Harvest::all();
   foreach ($harvests as $harvest) {
       echo $harvest->season->name;
   }
   
   // Good
   $harvests = Harvest::with('season')->get();
   ```

3. **Add indexes to frequently queried columns:**
   ```php
   // In migration
   $table->index('season_id');
   $table->index('created_at');
   ```

4. **Cache results:**
   ```php
   $harvests = Cache::remember('harvests', 3600, function () {
       return Harvest::with('season')->get();
   });
   ```

---

### Issue: Server memory error (Out of Memory)

**Symptom:** "PHP Fatal error: Allowed memory size exhausted"

**Solutions:**

1. **Increase PHP memory limit in php.ini:**
   ```ini
   memory_limit = 512M
   ```

2. **Or set in .env for artisan:**
   ```bash
   php -d memory_limit=-1 artisan command:name
   ```

3. **Check for memory leaks in code:**
   ```php
   // Avoid loading entire dataset
   $harvests = Harvest::all(); // BAD
   
   // Use pagination or chunking
   Harvest::chunk(100, function ($harvests) {
       // Process $harvests
   });
   ```

---

## 🔧 Debugging Tools

### Tinker (Interactive Shell)

```bash
php artisan tinker

# Common commands
>>> App\Models\User::all();
>>> App\Models\User::find(1);
>>> $user = App\Models\User::find(1);
>>> $user->harvests;
>>> App\Models\Setting::get('min_stock');
>>> DB::table('users')->where('email', 'admin@simhpsk.com')->first();
>>> exit
```

### Check Logs

```bash
# Real-time logs
tail -f storage/logs/laravel.log

# Last 50 lines
tail -50 storage/logs/laravel.log

# Search for errors
grep -i error storage/logs/laravel.log
```

### Test Database Connection

```bash
mysql -h 127.0.0.1 -u root -p simhpsk -e "SELECT * FROM users;"
```

### Clear All Caches

```bash
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan optimize:clear
```

---

## 📞 When All Else Fails

1. **Check system requirements:**
   - PHP 8.2+
   - MySQL 5.7+
   - Composer latest

2. **Delete vendor & reinstall:**
   ```bash
   rm -rf vendor
   composer install
   ```

3. **Fresh install:**
   ```bash
   php artisan migrate:fresh --seed
   ```

4. **Check .env file:**
   ```
   Verify all credentials
   Verify paths are correct
   ```

5. **Check error logs:**
   - Laravel: `storage/logs/laravel.log`
   - MySQL: Check MySQL error log
   - PHP: Check PHP error log

6. **Restart services:**
   ```bash
   # If using Laragon
   Stop & Start in system tray
   
   # Or manually
   php artisan serve --port=8000
   ```

---

## 📋 Checklist for Common Issues

- [ ] .env file configured correctly
- [ ] Database exists and user has permissions
- [ ] Migrations ran successfully (`php artisan migrate:status`)
- [ ] Storage link created (`php artisan storage:link`)
- [ ] App key generated (`php artisan key:generate`)
- [ ] Permissions set correctly (755 for storage/)
- [ ] Browser cache cleared
- [ ] Laravel cache cleared (`php artisan cache:clear`)
- [ ] Debug mode enabled for development (`APP_DEBUG=true`)
- [ ] Check Laravel logs (`tail -f storage/logs/laravel.log`)

---

**Last Updated:** 2024
**Version:** 1.0
