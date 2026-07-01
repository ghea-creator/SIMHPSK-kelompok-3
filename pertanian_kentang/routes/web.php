<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\CostController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\HarvestController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\SaleController;
use App\Http\Controllers\SeasonController;
use App\Http\Controllers\PasswordResetController;
use App\Http\Controllers\SettingController;
use App\Http\Controllers\StockController;
use App\Http\Controllers\SuperAdmin\SuperAdminController;
use Illuminate\Support\Facades\Route;

// Public Routes
Route::get('/', function () {
    return response()->json([
        'success' => true,
        'message' => 'Welcome to SIMHPSK API Server',
        'status' => 'online',
        'frontend' => 'Please access the application using the Flutter Web/Mobile frontend.'
    ]);
})->name('landing');

Route::get('/login', function() {
    return response()->json([
        'success' => false,
        'message' => 'Blade views have been disabled. Please authenticate via the Flutter client using API /api/auth/login'
    ], 401);
})->name('login');
Route::post('/login', [AuthController::class, 'login']);
Route::get('/register', function() {
    return response()->json([
        'success' => false,
        'message' => 'Blade views have been disabled. Please register via the Flutter client using API /api/auth/register'
    ], 401);
})->name('register');
Route::post('/register', [AuthController::class, 'register']);

// Password Reset Routes
Route::get('/forgot-password', [PasswordResetController::class, 'showForgotPasswordForm'])->name('password.request');
Route::post('/forgot-password', [PasswordResetController::class, 'sendResetLinkEmail'])->name('password.email');
Route::get('/reset-password/{token?}', [PasswordResetController::class, 'showResetPasswordForm'])->name('password.reset');
Route::post('/reset-password', [PasswordResetController::class, 'resetPassword'])->name('password.update');
Route::get('/password-reset-success', [PasswordResetController::class, 'showResetSuccess'])->name('password.reset.success');

// Protected Routes
Route::middleware('auth')->group(function () {
    // Logout
    Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

    // Admin Routes
    Route::get('/dashboard', function() {
        return response()->json([
            'success' => false,
            'message' => 'Blade views have been disabled. Please access the Dashboard via the Flutter client.'
        ]);
    })->name('dashboard');

    Route::get('/test-auth', function () {
        return 'Authenticated as ' . auth()->id();
    });

    // Seasons
    Route::get('/seasons', [SeasonController::class, 'index'])->name('seasons.index');
    Route::post('/seasons', [SeasonController::class, 'store'])->name('seasons.store');
    Route::put('/seasons/{season}', [SeasonController::class, 'update'])->name('seasons.update');
    Route::delete('/seasons/{season}', [SeasonController::class, 'destroy'])->name('seasons.destroy');

    // Harvests
    Route::get('/harvests', [HarvestController::class, 'index'])->name('harvests.index');
    Route::post('/harvests', [HarvestController::class, 'store'])->name('harvests.store');
    Route::put('/harvests/{harvest}', [HarvestController::class, 'update'])->name('harvests.update');
    Route::delete('/harvests/{harvest}', [HarvestController::class, 'destroy'])->name('harvests.destroy');

    // Stock
    Route::get('/stock', [StockController::class, 'index'])->name('stock.index');
    Route::post('/stock/in', [StockController::class, 'storeIncoming'])->name('stock.in');
    Route::post('/stock/out', [StockController::class, 'storeOutgoing'])->name('stock.out');
    Route::delete('/stock/{transaction}', [StockController::class, 'destroyTransaction'])->name('stock.destroy');

    // Sales
    Route::get('/sales', [SaleController::class, 'index'])->name('sales.index');
    Route::post('/sales', [SaleController::class, 'store'])->name('sales.store');
    Route::put('/sales/{sale}', [SaleController::class, 'update'])->name('sales.update');
    Route::delete('/sales/{sale}', [SaleController::class, 'destroy'])->name('sales.destroy');

    // Costs
    Route::get('/costs', [CostController::class, 'index'])->name('costs.index');
    Route::post('/costs', [CostController::class, 'store'])->name('costs.store');
    Route::put('/costs/{cost}', [CostController::class, 'update'])->name('costs.update');
    Route::delete('/costs/{cost}', [CostController::class, 'destroy'])->name('costs.destroy');

    // Reports
    Route::get('/reports/profit-loss', [ReportController::class, 'profitLoss'])->name('report.profit-loss');
    Route::get('/reports/target-vs-actual', [ReportController::class, 'targetVsActual'])->name('report.target-vs-actual');
    Route::get('/reports/export/profit-loss/excel', [ReportController::class, 'exportProfitLossExcel'])->name('report.export.profit-loss.excel');
    Route::get('/reports/export/profit-loss/pdf', [ReportController::class, 'exportProfitLossPdf'])->name('report.export.profit-loss.pdf');
    Route::get('/reports/export/target-vs-actual/excel', [ReportController::class, 'exportTargetVsActualExcel'])->name('report.export.target-vs-actual.excel');
    Route::get('/reports/export/target-vs-actual/pdf', [ReportController::class, 'exportTargetVsActualPdf'])->name('report.export.target-vs-actual.pdf');

    // Chatbot
    Route::get('/chatbot', function () {
        return response()->json([
            'success' => false,
            'message' => 'Blade views have been disabled. Please access Chatbot via the Flutter client.'
        ]);
    })->name('chatbot');

    // Settings
    Route::get('/settings', [SettingController::class, 'index'])->name('settings.index');
    Route::post('/settings/profile', [SettingController::class, 'updateProfile'])->name('settings.profile');
    Route::post('/settings/password', [SettingController::class, 'updatePassword'])->name('settings.password');
    Route::post('/settings/gudang', [SettingController::class, 'updateGudang'])->name('settings.gudang');
    Route::post('/settings/notifications', [SettingController::class, 'updateNotifications'])->name('settings.notifications');
    Route::delete('/settings/account', [SettingController::class, 'deleteAccount'])->name('settings.account.delete');

    // Super Admin Routes
    Route::middleware('super-admin')->prefix('super-admin')->name('super-admin.')->group(function () {
        Route::get('/', [SuperAdminController::class, 'dashboard'])->name('dashboard');
        
        // User Management
        Route::get('/users', [SuperAdminController::class, 'users'])->name('users');
        Route::post('/users', [SuperAdminController::class, 'storeUser'])->name('users.store');
        Route::put('/users/{user}', [SuperAdminController::class, 'updateUser'])->name('users.update');
        Route::delete('/users/{user}', [SuperAdminController::class, 'destroyUser'])->name('users.destroy');
        Route::get('/users/{user}/impersonate', [SuperAdminController::class, 'impersonate'])->name('users.impersonate');
        
        // Landing Page Editor
        Route::get('/landing-editor', [SuperAdminController::class, 'editLanding'])->name('landing-editor');
        Route::post('/landing-editor', [SuperAdminController::class, 'updateLanding'])->name('landing-editor.update');

        // Dashboard Menus
        Route::get('/menus', [SuperAdminController::class, 'dashboardMenus'])->name('dashboard-menus');
        Route::post('/menus', [SuperAdminController::class, 'storeMenu'])->name('dashboard-menus.store');
        Route::put('/menus/{menu}', [SuperAdminController::class, 'updateMenu'])->name('dashboard-menus.update');
        Route::delete('/menus/{menu}', [SuperAdminController::class, 'destroyMenu'])->name('dashboard-menus.destroy');

        // Feedbacks
        Route::get('/feedbacks', [App\Http\Controllers\FeedbackController::class, 'indexSuperAdmin'])->name('feedbacks.index');
        Route::post('/feedbacks/{feedback}/read', [App\Http\Controllers\FeedbackController::class, 'markAsRead'])->name('feedbacks.read');
        Route::delete('/feedbacks/{feedback}', [App\Http\Controllers\FeedbackController::class, 'destroy'])->name('feedbacks.destroy');
    });

    // Stop Impersonate (accessible by impersonated users)
    Route::get('/super-admin/stop-impersonate', [SuperAdminController::class, 'stopImpersonate'])->name('super-admin.stop-impersonate');
    
    // Feedback (User Side)
    Route::post('/feedback', [App\Http\Controllers\FeedbackController::class, 'store'])->name('feedback.store');
});
