@echo off
REM ============================================
REM START BACKEND & FRONTEND ABSENSI
REM ============================================
REM Pastikan Laragon/MySQL sudah running!
REM ============================================

echo.
echo ====================================
echo   🚀 STARTING BACKEND & FRONTEND
echo ====================================
echo.
echo 📌 PASTIKAN LARAGON SUDAH RUNNING!
echo    (MySQL harus aktif di port 3306)
echo.
timeout /t 3

REM Start Backend
echo.
echo [1/2] 🔧 Starting Backend Server...
echo        Port: 5000
echo.
start "Backend - Absensi" cmd /k "cd /d c:\laragon\www\backend-absensi && echo. && echo 🔧 Backend Server Starting... && echo. && node index.js"

REM Wait untuk backend initialize
timeout /t 4

REM Start Frontend
echo.
echo [2/2] ⚛️  Starting Frontend (React/Vite)...
echo        Port: 5173
echo.
start "Frontend - Absensi" cmd /k "cd /d c:\laragon\www\backend-absensi\frontend-absensi && echo. && echo ⚛️  Frontend Server Starting... && echo. && npm run dev"

REM Wait sedikit kemudian kasih info
timeout /t 3

REM Show info
cls
echo.
echo ====================================
echo    ✅ APLIKASI SIAP DIAKSES
echo ====================================
echo.
echo 🌐 Frontend:  http://localhost:5173/
echo 🔗 Backend:   http://localhost:5000
echo.
echo 📝 LOGIN:
echo    Username: admin
echo    Password: 123456
echo.
echo 💡 TIPS:
echo    - Frontend akan otomatis terbuka di browser
echo    - Jika tidak, buka manual: http://localhost:5173/
echo    - Kedua terminal harus tetap terbuka
echo    - Close window untuk stop aplikasi
echo.
echo ====================================
echo.
pause
