<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    use ApiResponseTrait;

    // ============ API Methods ============

    /**
     * Register via API
     */
    public function registerApi(Request $request)
    {
        try {
            $validated = $request->validate([
                'farm_name' => 'required|string|max:255',
                'name' => 'required|string|max:255',
                'email' => 'required|email|unique:users',
                'phone' => 'required|string|max:20',
                'password' => 'required|string|min:8|confirmed',
            ]);

            $user = User::create([
                'farm_name' => $validated['farm_name'],
                'name' => $validated['name'],
                'email' => $validated['email'],
                'phone' => $validated['phone'],
                'password' => Hash::make($validated['password']),
                'role' => 'user',
                'status' => 'active',
                'approval' => 'approved',
            ]);

            return $this->successResponse(
                [
                    'id' => $user->id,
                    'email' => $user->email,
                    'name' => $user->name,
                    'farm_name' => $user->farm_name,
                    'status' => 'active',
                ],
                'Pendaftaran berhasil! Silakan masuk.',
                201
            );
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }

    /**
     * Login via API - Returns Sanctum token
     */
    public function loginApi(Request $request)
    {
        try {
            $validated = $request->validate([
                'email' => 'required|email',
                'password' => 'required|string',
            ]);

            $user = User::where('email', $validated['email'])->first();

            if (!$user || !Hash::check($validated['password'], $user->password)) {
                return $this->errorResponse('Email atau password salah.', 401);
            }

            if ($user->status === 'inactive') {
                return $this->errorResponse('Akun Anda tidak aktif.', 403);
            }

            // Create token
            $token = $user->createToken('api-token')->plainTextToken;

            return $this->successResponse([
                'token' => $token,
                'token_type' => 'Bearer',
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'farm_name' => $user->farm_name,
                    'phone' => $user->phone,
                    'role' => $user->role,
                    'status' => $user->status,
                    'approval' => $user->approval,
                ],
            ], 'Login berhasil.', 200);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }

    /**
     * Logout via API - Revoke token
     */
    public function logoutApi(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return $this->successResponse(null, 'Logout berhasil.', 200);
    }

    /**
     * Get current authenticated user
     */
    public function meApi(Request $request)
    {
        $user = $request->user();
        return $this->successResponse([
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'farm_name' => $user->farm_name,
            'phone' => $user->phone,
            'role' => $user->role,
            'status' => $user->status,
            'approval' => $user->approval,
            'created_at' => $user->created_at,
            'updated_at' => $user->updated_at,
        ], 'Success.', 200);
    }

    // ============ Web Methods (Legacy) ============

    public function showLoginForm()
    {
        return view('auth.login');
    }

    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if (Auth::attempt($credentials, $request->boolean('remember'))) {
            $user = Auth::user();
            
            if ($user->status === 'inactive') {
                Auth::logout();
                return back()->withErrors(['email' => 'Akun Anda tidak aktif.']);
            }

            $request->session()->regenerate();
            
            // Redirect based on role
            if ($user->role === 'super_admin') {
                return redirect()->intended(route('super-admin.dashboard'));
            }
            
            return redirect()->intended(route('dashboard'));
        }

        return back()->withErrors([
            'email' => 'Email atau password salah.',
        ])->onlyInput('email');
    }

    public function showRegisterForm()
    {
        return view('auth.register');
    }

    public function register(Request $request)
    {
        $validated = $request->validate([
            'farm_name' => 'required|string|max:255',
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users',
            'phone' => 'required|string|max:20',
            'password' => 'required|string|min:6|confirmed',
        ]);

        $user = User::create([
            'farm_name' => $validated['farm_name'],
            'name' => $validated['name'],
            'email' => $validated['email'],
            'phone' => $validated['phone'],
            'password' => Hash::make($validated['password']),
            'role' => 'user',
            'status' => 'active',
            'approval' => 'approved',
        ]);

        return redirect(route('login'))->with('success', 'Pendaftaran berhasil! Silakan masuk.');
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect(route('landing'));
    }
}
