# PANDUAN EXPORT LAPORAN KE EXCEL & PDF

Fitur export laporan sudah berhasil diimplementasikan! Anda sekarang dapat mengexport laporan ke format Excel (.xlsx) dan PDF.

## 📋 Fitur yang Tersedia

### 1. **Laporan Laba Rugi**
   - **Excel Export**: Download laporan dalam format Excel dengan formatting profesional
   - **PDF Export**: Download laporan dalam format PDF yang siap cetak

### 2. **Laporan Target vs Realisasi**
   - **Excel Export**: Download dalam format Excel
   - **PDF Export**: Download dalam format PDF dengan color-coded status

## 🌐 Akses Export Laporan

### Dari Web Application

#### Laporan Laba Rugi
```
Klik tombol "Export" pada halaman /reports/profit-loss

- Export ke Excel: /reports/export/profit-loss/excel
- Export ke PDF: /reports/export/profit-loss/pdf
```

#### Laporan Target vs Realisasi
```
Klik tombol "Export" pada halaman /reports/target-vs-actual

- Export ke Excel: /reports/export/target-vs-actual/excel
- Export ke PDF: /reports/export/target-vs-actual/pdf
```

### Dari API (Mobile App & Frontend)

Semua endpoint API memerlukan Bearer Token authentication.

#### Profit Loss Report
```
GET /api/reports/export/profit-loss/excel?season_id={season_id}
GET /api/reports/export/profit-loss/pdf?season_id={season_id}
```

#### Target vs Actual Report
```
GET /api/reports/export/target-vs-actual/excel
GET /api/reports/export/target-vs-actual/pdf
```

## 📝 Contoh Request

### cURL Example
```bash
# Export Profit Loss Excel dengan season filter
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://localhost:8000/api/reports/export/profit-loss/excel?season_id=1" \
  --output laporan.xlsx

# Export Target vs Actual PDF
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://localhost:8000/api/reports/export/target-vs-actual/pdf" \
  --output laporan.pdf
```

### JavaScript/Fetch Example
```javascript
// Export Excel dengan authorization
const token = 'your_bearer_token';

fetch('/api/reports/export/profit-loss/excel?season_id=1', {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  }
})
.then(response => response.blob())
.then(blob => {
  // Download file
  const url = window.URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'laporan.xlsx';
  a.click();
});
```

## 📊 Format Export

### Excel Export (.xlsx)
- **Header Section**: Informasi petani, farm, dan tanggal export
- **Summary**: Total pendapatan, biaya, dan laba/rugi
- **Detail**: Tabel lengkap dengan formatting profesional
- **Column Width**: Otomatis sesuai dengan konten
- **Styling**: Header dengan warna gray, alignment yang tepat

### PDF Export
- **Header**: Logo dan informasi laporan
- **Summary Section**: Ringkasan keuangan dengan highlight
- **Detail Tables**: Tabel terformat dengan border dan padding
- **Color Coding**: 
  - 🟢 Tercapai (≥100%)
  - 🟡 Hampir (70%-99%)
  - 🔴 Kurang (<70%)
- **Footer**: Timestamp otomatis

## 🔧 Parameter Query

### Optional Parameters

#### `season_id` (opsional)
Filter laporan berdasarkan season_id tertentu.
- Tanpa parameter: Tampilkan semua data
- Dengan parameter: Tampilkan data untuk season tertentu

```
Contoh: /api/reports/export/profit-loss/excel?season_id=2
```

## 🔐 Keamanan

✅ Semua export routes dilindungi dengan authentication Sanctum
✅ User hanya bisa mengexport data mereka sendiri
✅ Error handling yang komprehensif
✅ Validasi request sebelum processing

## 📁 File-File yang Dibuat/Diupdate

### Files Created:
1. `app/Exports/ProfitLossExport.php` - Excel exporter class
2. `app/Exports/TargetVsActualExport.php` - Excel exporter class
3. `resources/views/reports/profit-loss-pdf.blade.php` - PDF template
4. `resources/views/reports/target-vs-actual-pdf.blade.php` - PDF template

### Files Updated:
1. `app/Http/Controllers/ReportController.php` - Tambahan export methods
2. `routes/api.php` - Tambahan API routes untuk export
3. `routes/web.php` - Tambahan web routes untuk export

## ⚙️ Dependencies

Export functionality menggunakan library yang sudah di-install:
- `maatwebsite/excel` - Untuk Excel export
- `barryvdh/laravel-dompdf` - Untuk PDF export

## 🚀 Cara Menggunakan di Frontend

### Tambahkan button di halaman laporan:

```html
<!-- Di halaman profit-loss.blade.php -->
<div class="export-buttons">
  <a href="{{ route('report.export.profit-loss.excel', ['season_id' => request('season_id')]) }}" 
     class="btn btn-success">
    <i class="fas fa-download"></i> Export Excel
  </a>
  <a href="{{ route('report.export.profit-loss.pdf', ['season_id' => request('season_id')]) }}" 
     class="btn btn-danger">
    <i class="fas fa-file-pdf"></i> Export PDF
  </a>
</div>
```

## 📱 Integrasi Mobile App

Untuk Flutter app, gunakan endpoint API dengan Bearer token:

```dart
Future<void> downloadReportExcel(String seasonId) async {
  final token = _authService.token;
  final response = await http.get(
    Uri.parse('$baseUrl/api/reports/export/profit-loss/excel?season_id=$seasonId'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );
  
  if (response.statusCode == 200) {
    // Save file to device
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/laporan.xlsx');
    await file.writeAsBytes(response.bodyBytes);
  }
}
```

## ✨ Fitur Tambahan

Anda dapat menambahkan fitur berikut di masa depan:
- [ ] Export multiple reports sekaligus
- [ ] Schedule automated report generation
- [ ] Email report langsung ke user
- [ ] Custom report templates
- [ ] Add charts/graphs ke PDF report
- [ ] Multi-language support

## 🐛 Troubleshooting

### Error: "File not found" untuk PDF
- Pastikan views directory ada di `resources/views/reports/`
- Restart Laravel development server

### Error: "Class not found" untuk Exporter
- Pastikan file ada di `app/Exports/`
- Run `composer dump-autoload`

### Error: 401 Unauthorized (API)
- Pastikan token valid dan belum expired
- Gunakan Header: `Authorization: Bearer YOUR_TOKEN`

## 📞 Support

Jika ada masalah atau pertanyaan, cek:
1. File syntax dengan `php -l filename.php`
2. Routes dengan `php artisan route:list | grep export`
3. Dependencies dengan `composer show | grep -E "(excel|dompdf)"`

---

**Status**: ✅ Implementasi Complete
**Last Updated**: {{ now()->format('d-m-Y H:i:s') }}
