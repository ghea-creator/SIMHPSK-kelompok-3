<?php

namespace App\Http\Controllers;

use App\Models\Harvest;
use App\Models\Season;
use App\Models\StockTransaction;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class HarvestController extends Controller
{
    use ApiResponseTrait;

    // ============ API Methods ============

    /**
     * Get all harvests - API
     */
    public function index(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->indexApi($request);
        }

        return $this->disabledWebResponse('Halaman pencatatan panen dinonaktifkan. Gunakan endpoint API /api/harvests.');
    }

    /**
     * List harvests with pagination - API
     */
    public function indexApi(Request $request)
    {
        $userId = $request->user()->id;
        $perPage = $request->input('per_page', 15);
        $seasonId = $request->input('season_id');

        $query = Harvest::where('user_id', $userId)->with('season')->latest('date');

        if ($seasonId) {
            $query->where('season_id', $seasonId);
        }

        $harvests = $query->paginate($perPage);
        $activeSeason = Season::where('user_id', $userId)->where('status', 'active')->first();
        $totalHarvest = Harvest::where('user_id', $userId)->sum('weight_kg');

        return $this->successResponse([
            'harvests' => $harvests->items(),
            'pagination' => [
                'total' => $harvests->total(),
                'per_page' => $harvests->perPage(),
                'current_page' => $harvests->currentPage(),
                'last_page' => $harvests->lastPage(),
            ],
            'active_season' => $activeSeason,
            'total_harvest_kg' => $totalHarvest,
        ], 'Daftar pencatatan panen.');
    }

    /**
     * Create new harvest - API
     */
    public function store(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->storeApi($request);
        }

        return $this->disabledWebResponse('Endpoint pembuatan panen hanya tersedia melalui API. Gunakan POST /api/harvests.');
    }

    /**
     * Create new harvest - API
     */
    public function storeApi(Request $request)
    {
        $validated = $request->validate([
            'season_id'    => 'required|integer|exists:seasons,id',
            'harvest_date' => 'nullable|date',
            'date'         => 'nullable|date',
            'quantity'     => 'nullable|integer|min:0',
            'weight_kg'    => 'required|numeric|min:0.01',
            'notes'        => 'nullable|string|max:1000',
            'status'       => 'nullable|in:recorded,verified,cancelled',
        ], [
            'season_id.required' => 'Musim tanam harus dipilih.',
            'season_id.exists'   => 'Musim tanam tidak ditemukan.',
            'weight_kg.required' => 'Berat (kg) harus diisi.',
            'weight_kg.min'      => 'Berat minimal 0.01 kg.',
        ]);

        // Verify season belongs to user
        $season = Season::where('id', $validated['season_id'])
            ->where('user_id', $request->user()->id)
            ->first();

        if (!$season) {
            return $this->forbiddenResponse('Musim tanam tidak ditemukan atau bukan milik Anda.');
        }

        $dbData = [
            'user_id' => $request->user()->id,
            'season_id' => $validated['season_id'],
            'quantity' => $validated['quantity'] ?? 0,
            'date' => $validated['harvest_date'] ?? $validated['date'] ?? now()->toDateString(),
            'weight_kg' => $validated['weight_kg'],
            'notes' => $validated['notes'] ?? null,
            'status' => isset($validated['status']) && in_array($validated['status'], ['recorded', 'verified', 'cancelled']) ? $validated['status'] : 'recorded',
        ];

        $harvest = Harvest::create($dbData);

        StockTransaction::addTransaction('in', $dbData['weight_kg'], 'Panen masuk', 'harvest_' . $harvest->id, $request->user()->id);

        return $this->successResponse([
            'id' => $harvest->id,
            'season_id' => $harvest->season_id,
            'season_name' => $season->name,
            'harvest_date' => $harvest->date->toDateString(),
            'weight_kg' => (int)$harvest->weight_kg,
            'quantity' => (int)($harvest->quantity ?? 0),
            'status' => $harvest->status,
            'notes' => $harvest->notes ?? '',
            'created_at' => $harvest->created_at->toIso8601String(),
        ], 'Pencatatan panen berhasil ditambahkan.', 201);
    }

    /**
     * Update harvest - API
     */
    public function update(Request $request, Harvest $harvest)
    {
        if ($request->wantsJson()) {
            return $this->updateApi($request, $harvest);
        }

        return $this->disabledWebResponse('Endpoint pembaruan panen hanya tersedia melalui API. Gunakan PUT /api/harvests/{id}.');
    }

    /**
     * Update harvest - API
     */
    public function updateApi(Request $request, Harvest $harvest)
    {
        // Check authorization
        if ($harvest->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak mengubah data ini.');
        }

        $validated = $request->validate([
            'season_id'    => 'sometimes|required|integer|exists:seasons,id',
            'harvest_date' => 'nullable|date',
            'date'         => 'nullable|date',
            'quantity'     => 'nullable|integer|min:0',
            'weight_kg'    => 'sometimes|required|numeric|min:0.01',
            'notes'        => 'nullable|string|max:1000',
            'status'       => 'nullable|in:recorded,verified,cancelled',
        ], [
            'season_id.required' => 'Musim tanam harus dipilih.',
            'season_id.exists'   => 'Musim tanam tidak ditemukan.',
            'weight_kg.required' => 'Berat (kg) harus diisi.',
            'weight_kg.min'      => 'Berat minimal 0.01 kg.',
        ]);

        // Verify season belongs to user if season_id is provided
        if (isset($validated['season_id'])) {
            $season = Season::where('id', $validated['season_id'])
                ->where('user_id', $request->user()->id)
                ->first();

            if (!$season) {
                return $this->forbiddenResponse('Musim tanam tidak ditemukan atau bukan milik Anda.');
            }
        }

        $dbData = [];
        if (isset($validated['season_id'])) $dbData['season_id'] = $validated['season_id'];
        
        $newDate = $validated['harvest_date'] ?? $validated['date'] ?? null;
        if ($newDate) $dbData['date'] = $newDate;

        if (isset($validated['weight_kg'])) $dbData['weight_kg'] = $validated['weight_kg'];
        if (isset($validated['quantity'])) $dbData['quantity'] = $validated['quantity'];
        if (isset($validated['notes'])) $dbData['notes'] = $validated['notes'];
        
        if (isset($validated['status'])) {
            $dbData['status'] = in_array($validated['status'], ['recorded', 'verified', 'cancelled']) ? $validated['status'] : $harvest->status;
        }

        $oldWeight = $harvest->weight_kg;
        $harvest->update($dbData);

        if (isset($dbData['weight_kg']) && $oldWeight != $dbData['weight_kg']) {
            $difference = $dbData['weight_kg'] - $oldWeight;
            StockTransaction::addTransaction(
                $difference > 0 ? 'in' : 'out',
                abs($difference),
                'Panen diupdate',
                'harvest_' . $harvest->id,
                $request->user()->id
            );
        }

        $seasonName = $harvest->season?->name ?? 'N/A';

        return $this->successResponse([
            'id' => $harvest->id,
            'season_id' => $harvest->season_id,
            'season_name' => $seasonName,
            'harvest_date' => $harvest->date->toDateString(),
            'weight_kg' => (int)$harvest->weight_kg,
            'quantity' => (int)($harvest->quantity ?? 0),
            'status' => $harvest->status,
            'notes' => $harvest->notes ?? '',
            'updated_at' => $harvest->updated_at->toIso8601String(),
        ], 'Pencatatan panen berhasil diperbarui.', 200);
    }

    /**
     * Delete harvest - API
     */
    public function destroy(Request $request, Harvest $harvest)
    {
        // Check if request wants JSON (API) or HTML (Web)
        if ($request->wantsJson()) {
            return $this->destroyApi($request, $harvest);
        }

        // Web response
        $harvest->delete();
        return back()->with('success', 'Pencatatan panen berhasil dihapus.');
    }

    /**
     * Delete harvest - API
     */
    public function destroyApi(Request $request, Harvest $harvest)
    {
        // Check authorization
        if ($harvest->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak menghapus data ini.');
        }

        $harvest->delete();
        return $this->successResponse(null, 'Pencatatan panen berhasil dihapus.', 200);
    }
}
