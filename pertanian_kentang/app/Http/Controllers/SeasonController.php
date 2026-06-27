<?php

namespace App\Http\Controllers;

use App\Models\Season;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class SeasonController extends Controller
{
    use ApiResponseTrait;

    // ============ API Methods ============

    /**
     * Get all seasons - API
     */
    public function index(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->indexApi($request);
        }

        return $this->disabledWebResponse('Halaman musim tanam dinonaktifkan. Gunakan endpoint API /api/seasons.');
    }

    /**
     * List seasons with pagination - API
     */
    public function indexApi(Request $request)
    {
        $perPage = $request->input('per_page', 15);
        $seasons = Season::where('user_id', $request->user()->id)
            ->latest()
            ->paginate($perPage);

        return $this->successResponse($seasons->items(), 'Daftar musim tanam.');
    }

    /**
     * Create new season - API
     */
    public function store(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->storeApi($request);
        }

        return $this->disabledWebResponse('Endpoint pembuatan musim tanam hanya tersedia melalui API. Gunakan POST /api/seasons.');
    }

    /**
     * Create new season - API
     */
    public function storeApi(Request $request)
    {
        try {
            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'start_date' => 'required|date',
                'end_date' => 'required|date|after:start_date',
                'status' => 'required|in:active,completed,cancelled',
                'target_kg' => 'required|numeric|min:0',
            ]);

            $validated['user_id'] = $request->user()->id;
            $season = Season::create($validated);

            return $this->successResponse([
                'id' => $season->id,
                'name' => $season->name,
                'start_date' => $season->start_date,
                'end_date' => $season->end_date,
                'status' => $season->status,
                'target_kg' => $season->target_kg,
                'created_at' => $season->created_at,
            ], 'Musim tanam berhasil ditambahkan.', 201);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }

    /**
     * Update season - API
     */
    public function update(Request $request, Season $season)
    {
        if ($request->wantsJson()) {
            return $this->updateApi($request, $season);
        }

        return $this->disabledWebResponse('Endpoint pembaruan musim tanam hanya tersedia melalui API. Gunakan PUT /api/seasons/{id}.');
    }

    /**
     * Update season - API
     */
    public function updateApi(Request $request, Season $season)
    {
        try {
            // Check authorization
            if ($season->user_id !== $request->user()->id) {
                return $this->forbiddenResponse('Anda tidak berhak mengubah data ini.');
            }

            $validated = $request->validate([
                'name' => 'required|string|max:255',
                'start_date' => 'required|date',
                'end_date' => 'required|date|after:start_date',
                'status' => 'required|in:active,completed,cancelled',
                'target_kg' => 'required|numeric|min:0',
            ]);

            $season->update($validated);

            return $this->successResponse([
                'id' => $season->id,
                'name' => $season->name,
                'start_date' => $season->start_date,
                'end_date' => $season->end_date,
                'status' => $season->status,
                'target_kg' => $season->target_kg,
                'updated_at' => $season->updated_at,
            ], 'Musim tanam berhasil diperbarui.', 200);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }

    /**
     * Delete season - API
     */
    public function destroy(Request $request, Season $season)
    {
        if ($request->wantsJson()) {
            return $this->destroyApi($request, $season);
        }

        return $this->disabledWebResponse('Endpoint hapus musim tanam hanya tersedia melalui API. Gunakan DELETE /api/seasons/{id}.');
    }

    /**
     * Delete season - API
     */
    public function destroyApi(Request $request, Season $season)
    {
        // Check authorization
        if ($season->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak menghapus data ini.');
        }

        $season->delete();
        return $this->successResponse(null, 'Musim tanam berhasil dihapus.', 200);
    }
}
