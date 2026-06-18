<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\CostController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\HarvestController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\SaleController;
use App\Http\Controllers\SeasonController;
use App\Http\Controllers\SettingController;
use App\Http\Controllers\StockController;
use App\Http\Controllers\PasswordResetController;
use App\Http\Controllers\SuperAdmin\SuperAdminController;
use App\Http\Controllers\FeedbackController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ChatbotController;

// Public Routes - Auth
Route::post('/auth/register', [AuthController::class, 'registerApi']);
Route::post('/auth/login', [AuthController::class, 'loginApi']);

Route::post('/auth/forgot-password', [PasswordResetController::class, 'sendResetLinkEmailApi']);
Route::post('/auth/reset-password', [PasswordResetController::class, 'resetPasswordApi']);

// chatbot route
Route::post('/chat', [ChatbotController::class, 'chat']);
// Public landing content
Route::get('/landing', [SuperAdminController::class, 'getLandingApi']);

// Protected Routes - Requires Sanctum Authentication
Route::middleware('auth:sanctum')->group(function () {
    // Auth
    Route::post('/auth/logout', [AuthController::class, 'logoutApi']);
    Route::get('/auth/me', [AuthController::class, 'meApi']);

    // Dashboard
    Route::get('/dashboard', [DashboardController::class, 'indexApi']);
    Route::get('/menus', [SuperAdminController::class, 'indexMenusApi']);

    // Seasons (Resource)
    Route::apiResource('seasons', SeasonController::class)->names('api.seasons');

    // Harvests (Resource)
    Route::apiResource('harvests', HarvestController::class)->names('api.harvests');

    // Stock
    Route::get('/stock', [StockController::class, 'indexApi']);
    Route::post('/stock/in', [StockController::class, 'storeIncomingApi']);
    Route::post('/stock/out', [StockController::class, 'storeOutgoingApi']);
    Route::delete('/stock/{transaction}', [StockController::class, 'destroyTransactionApi']);

    // Sales (Resource)
    Route::apiResource('sales', SaleController::class)->names('api.sales');

    // Costs (Resource)
    Route::apiResource('costs', CostController::class)->names('api.costs');

    // Reports
    Route::get('/reports/profit-loss', [ReportController::class, 'profitLossApi']);
    Route::get('/reports/target-vs-actual', [ReportController::class, 'targetVsActualApi']);
    Route::get('/reports/export/profit-loss/excel', [ReportController::class, 'exportProfitLossExcelApi']);
    Route::get('/reports/export/profit-loss/pdf', [ReportController::class, 'exportProfitLossPdfApi']);
    Route::get('/reports/export/target-vs-actual/excel', [ReportController::class, 'exportTargetVsActualExcelApi']);
    Route::get('/reports/export/target-vs-actual/pdf', [ReportController::class, 'exportTargetVsActualPdfApi']);

    // Settings
    Route::get('/settings', [SettingController::class, 'indexApi']);
    Route::post('/settings/profile', [SettingController::class, 'updateProfileApi']);
    Route::post('/settings/password', [SettingController::class, 'updatePasswordApi']);
    Route::post('/settings/gudang', [SettingController::class, 'updateGudangApi']);
    Route::post('/settings/notifications', [SettingController::class, 'updateNotificationsApi']);
    Route::delete('/settings/account', [SettingController::class, 'deleteAccountApi']);

    // Feedback
    Route::post('/feedback', [FeedbackController::class, 'storeApi']);
    // Super Admin Routes
    Route::middleware('role:super_admin')->prefix('super-admin')->group(function () {
        Route::get('/dashboard', [SuperAdminController::class, 'dashboardApi']);
        
        // User Management
        Route::get('/users', [SuperAdminController::class, 'indexUsersApi']);
        Route::post('/users', [SuperAdminController::class, 'storeUserApi']);
        Route::put('/users/{user}', [SuperAdminController::class, 'updateUserApi']);
        Route::delete('/users/{user}', [SuperAdminController::class, 'destroyUserApi']);
        Route::post('/users/{user}/impersonate', [SuperAdminController::class, 'impersonateApi']);
        
        // Landing Content
        Route::get('/landing', [SuperAdminController::class, 'getLandingApi']);
        Route::post('/landing', [SuperAdminController::class, 'updateLandingApi']);

        // Dashboard Menus
        Route::get('/menus', [SuperAdminController::class, 'indexMenusApi']);
        Route::post('/menus', [SuperAdminController::class, 'storeMenuApi']);
        Route::put('/menus/{menu}', [SuperAdminController::class, 'updateMenuApi']);
        Route::delete('/menus/{menu}', [SuperAdminController::class, 'destroyMenuApi']);

        // Feedbacks
        Route::get('/feedbacks', [FeedbackController::class, 'indexSuperAdminApi']);
        Route::post('/feedbacks/{feedback}/read', [FeedbackController::class, 'markAsReadApi']);
        Route::delete('/feedbacks/{feedback}', [FeedbackController::class, 'destroyApi']);

        
    });
});
