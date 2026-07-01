<?php

namespace App\Http\Controllers;

use App\Models\Setting;
use App\Models\User;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

class SettingController extends Controller
{
    use ApiResponseTrait;
    public function index(Request $request)
    {
        return $this->disabledWebResponse('Halaman pengaturan dinonaktifkan. Gunakan endpoint API /api/settings.');
    }

    public function updateProfile(Request $request)
    {
        return $this->disabledWebResponse('Endpoint update profil hanya tersedia melalui API. Gunakan POST /api/settings/profile.');
    }

    public function updatePassword(Request $request)
    {
        return $this->disabledWebResponse('Endpoint ganti password hanya tersedia melalui API. Gunakan POST /api/settings/password.');
    }

    public function updateGudang(Request $request)
    {
        return $this->disabledWebResponse('Endpoint pengaturan gudang hanya tersedia melalui API. Gunakan POST /api/settings/gudang.');
    }

    public function updateNotifications(Request $request)
    {
        return $this->disabledWebResponse('Endpoint pengaturan notifikasi hanya tersedia melalui API. Gunakan POST /api/settings/notifications.');
    }

    public function indexApi(Request $request)
    {
        $user = $request->user();
        $minStock = Setting::get('min_stock', 100);
        $maxStock = Setting::get('max_stock', 5000);
        $notifyLowStock = Setting::get('notify_low_stock', 1);
        $notifyNewSale = Setting::get('notify_new_sale', 1);
        $notifyCost = Setting::get('notify_cost', 1);

        return $this->successResponse([
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'farm_name' => $user->farm_name,
                'role' => $user->role,
                'status' => $user->status,
            ],
            'min_stock' => (int)$minStock,
            'max_stock' => (int)$maxStock,
            'notify_low_stock' => (bool)$notifyLowStock,
            'notify_new_sale' => (bool)$notifyNewSale,
            'notify_cost' => (bool)$notifyCost,
        ], 'Pengaturan berhasil diambil.');
    }

    public function updateProfileApi(Request $request)
    {
        $user = $request->user();
        
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email,' . $user->id,
            'phone' => 'required|string|max:20',
            'farm_name' => 'nullable|string|max:255',
        ]);

        $user->update($validated);
        return $this->successResponse([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'farm_name' => $user->farm_name,
            'role' => $user->role,
            'status' => $user->status,
        ], 'Profil berhasil diperbarui.');
    }

    public function updatePasswordApi(Request $request)
    {
        $user = $request->user();
        
        $validated = $request->validate([
            'current_password' => 'required|string',
            'password' => 'required|string|min:6|confirmed',
        ]);

        if (!Hash::check($validated['current_password'], $user->password)) {
            return $this->errorResponse('Password saat ini tidak sesuai.', 422);
        }

        $user->update(['password' => Hash::make($validated['password'])]);
        return $this->successResponse(null, 'Password berhasil diperbarui.');
    }

    public function updateGudangApi(Request $request)
    {
        $validated = $request->validate([
            'min_stock' => 'required|numeric|min:1',
            'max_stock' => 'required|numeric|min:1',
        ]);

        Setting::set('min_stock', $validated['min_stock']);
        Setting::set('max_stock', $validated['max_stock']);

        return $this->successResponse([
            'min_stock' => (int)$validated['min_stock'],
            'max_stock' => (int)$validated['max_stock'],
        ], 'Pengaturan gudang berhasil diperbarui.');
    }

    public function updateNotificationsApi(Request $request)
    {
        $notifications = $request->validate([
            'notify_low_stock' => 'required|boolean',
            'notify_new_sale' => 'required|boolean',
            'notify_cost' => 'required|boolean',
        ]);

        foreach ($notifications as $key => $value) {
            Setting::set($key, $value ? 1 : 0);
        }

        return $this->successResponse($notifications, 'Pengaturan notifikasi berhasil diperbarui.');
    }

    public function deleteAccountApi(Request $request)
    {
        $user = $request->user();
        if ($user) {
            $user->tokens()->delete();
            $user->delete();
        }
        
        return $this->successResponse(null, 'Akun berhasil dihapus.', 200);
    }

    // ============ Web Methods (Legacy) ============
    public function deleteAccount(Request $request)
    {
        $user = Auth::user();
        Auth::logout();
        if ($user) {
            $user->delete();
        }
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        
        return redirect('/')->with('success', 'Akun berhasil dihapus.');
    }
}
