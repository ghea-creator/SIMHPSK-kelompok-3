<?php

namespace App\Http\Controllers\SuperAdmin;

use App\Http\Controllers\Controller;
use App\Models\DashboardMenu;
use App\Models\LandingContent;
use App\Models\User;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth; // FIX 1: Ditambahkan karena lu pakai auth() login secara manual

class SuperAdminController extends Controller
{
    use ApiResponseTrait;

    public function dashboard(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->dashboardApi();
        }

        return $this->disabledWebResponse('Halaman dashboard super admin dinonaktifkan. Gunakan endpoint API /api/super-admin/dashboard.');
    }

    // User Management
    public function users(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->indexUsersApi();
        }

        return $this->disabledWebResponse('Halaman daftar user super admin dinonaktifkan. Gunakan endpoint API /api/super-admin/users.');
    }

    public function storeUser(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->storeUserApi($request);
        }

        return $this->disabledWebResponse('Endpoint pembuatan user hanya tersedia melalui API. Gunakan POST /api/super-admin/users.');
    }

    public function updateUser(Request $request, User $user)
    {
        if ($request->wantsJson()) {
            return $this->updateUserApi($request, $user);
        }

        return $this->disabledWebResponse('Endpoint pembaruan user hanya tersedia melalui API. Gunakan PUT /api/super-admin/users/{id}.');
    }

    public function destroyUser(Request $request, User $user)
    {
        if ($request->wantsJson()) {
            return $this->destroyUserApi($user);
        }

        return $this->disabledWebResponse('Endpoint hapus user hanya tersedia melalui API. Gunakan DELETE /api/super-admin/users/{id}.');
    }

    // Landing Page Editor
    public function editLanding(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->getLandingApi();
        }

        return $this->disabledWebResponse('Halaman editor landing page dinonaktifkan. Gunakan endpoint API /api/super-admin/landing.');
    }

    public function updateLanding(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->updateLandingApi($request);
        }

        return $this->disabledWebResponse('Endpoint update landing page hanya tersedia melalui API. Gunakan POST /api/super-admin/landing.');
    }

    // Dashboard Menu Management
    public function dashboardMenus(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->indexMenusApi();
        }

        return $this->disabledWebResponse('Halaman menu dashboard super admin dinonaktifkan. Gunakan endpoint API /api/super-admin/menus.');
    }

    public function storeMenu(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->storeMenuApi($request);
        }

        return $this->disabledWebResponse('Endpoint pembuatan menu dashboard hanya tersedia melalui API. Gunakan POST /api/super-admin/menus.');
    }

    public function updateMenu(Request $request, DashboardMenu $menu)
    {
        if ($request->wantsJson()) {
            return $this->updateMenuApi($request, $menu);
        }

        return $this->disabledWebResponse('Endpoint pembaruan menu dashboard hanya tersedia melalui API. Gunakan PUT /api/super-admin/menus/{id}.');
    }

    public function destroyMenu(Request $request, DashboardMenu $menu)
    {
        if ($request->wantsJson()) {
            return $this->destroyMenuApi($menu);
        }

        return $this->disabledWebResponse('Endpoint hapus menu dashboard hanya tersedia melalui API. Gunakan DELETE /api/super-admin/menus/{id}.');
    }

    // Impersonate User
    public function impersonate(User $user)
    {
        return $this->disabledWebResponse('Impersonate hanya tersedia melalui UI yang belum diaktifkan. Gunakan API dengan otentikasi token jika diperlukan.');
    }

    public function stopImpersonate()
    {
        return $this->disabledWebResponse('Impersonate stop hanya tersedia melalui UI yang belum diaktifkan.');
    }

    // API Super Admin Dashboard
    public function dashboardApi()
    {
        $totalUsers = User::count();
        $activeUsers = User::where('status', 'active')->count();

        return $this->successResponse([
            'totalUsers' => $totalUsers,
            'activeUsers' => $activeUsers,
        ], 'Data dashboard super admin berhasil diambil.');
    }

    // API User Management
    public function indexUsersApi()
    {
        $users = User::latest()->get();
        return $this->successResponse($users, 'Daftar user berhasil diambil.');
    }

    public function storeUserApi(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:6',
            'phone' => 'required|string|max:20',
            'farm_name' => 'required|string|max:255',
            'role' => 'required|in:user,super_admin',
            'status' => 'required|in:active,inactive',
        ]);

        $validated['password'] = Hash::make($validated['password']);
        $user = User::create($validated);

        return $this->successResponse($user, 'User berhasil ditambahkan.', 201);
    }

    public function updateUserApi(Request $request, User $user)
    {
        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'email' => 'sometimes|required|email|unique:users,email,' . $user->id,
            'phone' => 'sometimes|required|string|max:20',
            'farm_name' => 'sometimes|required|string|max:255',
            'role' => 'sometimes|required|in:user,super_admin',
            'status' => 'sometimes|required|in:active,inactive',
            'password' => 'sometimes|string|min:6',
        ]);

        if ($request->filled('password')) {
            $validated['password'] = Hash::make($request->password);
        }

        $user->update($validated);
        return $this->successResponse($user, 'User berhasil diperbarui.');
    }

    public function destroyUserApi(User $user)
    {
        if ($user->role === 'super_admin' && User::where('role', 'super_admin')->count() === 1) {
            return $this->errorResponse('Tidak bisa menghapus super admin terakhir.', 422);
        }

        $user->delete();
        return $this->successResponse(null, 'User berhasil dihapus.');
    }

    // API Landing Content
    public function getLandingApi()
    {
        $contents = LandingContent::all()->pluck('content', 'section');
        return $this->successResponse($contents, 'Konten landing page berhasil diambil.');
    }

    public function updateLandingApi(Request $request)
    {
        $sections = [
            'hero_title', 'hero_description', 'hero_cta_1', 'hero_cta_2',
            'feature_1_title', 'feature_1_desc', 'feature_2_title', 'feature_2_desc',
            'feature_3_title', 'feature_3_desc', 'feature_4_title', 'feature_4_desc',
            'feature_5_title', 'feature_5_desc', 'feature_6_title', 'feature_6_desc',
        ];

        foreach ($sections as $section) {
            if ($request->has($section)) {
                LandingContent::updateOrCreate(
                    ['section' => $section],
                    ['content' => $request->input($section)]
                );
            }
        }

        $contents = LandingContent::all()->pluck('content', 'section');
        return $this->successResponse($contents, 'Landing page berhasil diperbarui.');
    }

    // API Dashboard Menus
    public function indexMenusApi()
    {
        $menus = DashboardMenu::orderBy('sort_order')->get();
        return $this->successResponse($menus, 'Daftar menu dashboard berhasil diambil.');
    }

    public function storeMenuApi(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'icon' => 'required|string|max:100',
            'color' => 'required|regex:/^#[A-Fa-f0-9]{6}$/',
            'description' => 'required|string|max:500',
            'url' => 'nullable|string|max:500',
            'sort_order' => 'required|integer',
        ]);

        $menu = DashboardMenu::create($validated);
        return $this->successResponse($menu, 'Menu dashboard berhasil ditambahkan.', 201);
    }

    public function updateMenuApi(Request $request, DashboardMenu $menu)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'icon' => 'required|string|max:100',
            'color' => 'required|regex:/^#[A-Fa-f0-9]{6}$/',
            'description' => 'required|string|max:500',
            'url' => 'nullable|string|max:500',
            'sort_order' => 'required|integer',
            'is_active' => 'boolean',
        ]);

        $menu->update($validated);
        return $this->successResponse($menu, 'Menu dashboard berhasil diperbarui.');
    }

    public function destroyMenuApi(DashboardMenu $menu)
    {
        $menu->delete();
        return $this->successResponse(null, 'Menu dashboard berhasil dihapus.');
    }

    // API Impersonate
    public function impersonateApi(Request $request, User $user)
    {
        if ($user->role === 'super_admin') {
            return $this->errorResponse('Tidak bisa impersonate super admin lain.', 422);
        }

        // Create token for the target user (Menggunakan Laravel Sanctum)
        $token = $user->createToken('impersonate_token')->plainTextToken;

        return $this->successResponse([
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'farm_name' => $user->farm_name,
                'role' => $user->role,
                'status' => $user->status,
            ]
        ], 'Berhasil masuk sebagai ' . $user->name);
    }
}