<?php

namespace App\Http\Controllers;

use App\Models\ProductionCost;
use App\Models\Season;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class CostController extends Controller
{
    use ApiResponseTrait;

    public function index(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->indexApi($request);
        }

        return $this->disabledWebResponse('Halaman biaya produksi dinonaktifkan. Gunakan endpoint API /api/costs.');
    }

    public function indexApi(Request $request)
    {
        $userId = $request->user()->id;
        $perPage = $request->input('per_page', 15);
        $seasonId = $request->input('season_id');

        $query = ProductionCost::where('user_id', $userId)->with('season')->latest('date');
        if ($seasonId) {
            $query->where('season_id', $seasonId);
        }

        $costs = $query->paginate($perPage);
        $totalCost = ProductionCost::where('user_id', $userId)->sum('amount');
        $costByCategory = ProductionCost::getCostByCategory($userId);

        return $this->successResponse([
            'costs' => $costs->items(),
            'pagination' => [
                'total' => $costs->total(),
                'per_page' => $costs->perPage(),
                'current_page' => $costs->currentPage(),
                'last_page' => $costs->lastPage(),
            ],
            'total_cost' => $totalCost,
            'cost_by_category' => $costByCategory,
        ], 'Daftar biaya produksi.');
    }

    public function store(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->storeApi($request);
        }

        return $this->disabledWebResponse('Endpoint pembuatan biaya produksi hanya tersedia melalui API. Gunakan POST /api/costs.');
    }

    public function storeApi(Request $request)
    {
        try {
            $validated = $request->validate([
                'date' => 'required|date',
                'season_id' => 'nullable|exists:seasons,id',
                'category' => 'required|in:seed,fertilizer,pesticide,other',
                'amount' => 'required|numeric|min:0.01',
                'notes' => 'nullable|string|max:255',
            ]);

            $validated['user_id'] = $request->user()->id;
            $cost = ProductionCost::create($validated);

            return $this->successResponse([
                'id' => $cost->id,
                'date' => $cost->date,
                'category' => $cost->category,
                'amount' => $cost->amount,
                'notes' => $cost->notes,
                'created_at' => $cost->created_at,
            ], 'Biaya produksi berhasil ditambahkan.', 201);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }

    public function update(Request $request, ProductionCost $cost)
    {
        if ($request->wantsJson()) {
            return $this->updateApi($request, $cost);
        }

        return $this->disabledWebResponse('Endpoint pembaruan biaya produksi hanya tersedia melalui API. Gunakan PUT /api/costs/{id}.');
    }

    public function updateApi(Request $request, ProductionCost $cost)
    {
        try {
            if ($cost->user_id !== $request->user()->id) {
                return $this->forbiddenResponse('Anda tidak berhak mengubah data ini.');
            }

            $validated = $request->validate([
                'date' => 'required|date',
                'season_id' => 'nullable|exists:seasons,id',
                'category' => 'required|in:seed,fertilizer,pesticide,other',
                'amount' => 'required|numeric|min:0.01',
                'notes' => 'nullable|string|max:255',
            ]);

            $cost->update($validated);

            return $this->successResponse([
                'id' => $cost->id,
                'date' => $cost->date,
                'category' => $cost->category,
                'amount' => $cost->amount,
                'notes' => $cost->notes,
                'updated_at' => $cost->updated_at,
            ], 'Biaya produksi berhasil diperbarui.', 200);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }

    public function destroy(Request $request, ProductionCost $cost)
    {
        if ($request->wantsJson()) {
            return $this->destroyApi($request, $cost);
        }

        return $this->disabledWebResponse('Endpoint hapus biaya produksi hanya tersedia melalui API. Gunakan DELETE /api/costs/{id}.');
    }

    public function destroyApi(Request $request, ProductionCost $cost)
    {
        if ($cost->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak menghapus data ini.');
        }

        $cost->delete();
        return $this->successResponse(null, 'Biaya produksi berhasil dihapus.', 200);
    }
}
