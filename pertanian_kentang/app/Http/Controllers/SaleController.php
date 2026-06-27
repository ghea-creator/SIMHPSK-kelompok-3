<?php

namespace App\Http\Controllers;

use App\Models\Sale;
use App\Models\Season;
use App\Models\StockTransaction;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class SaleController extends Controller
{
    use ApiResponseTrait;

    public function index(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->indexApi($request);
        }

        return $this->disabledWebResponse('Halaman penjualan dinonaktifkan. Gunakan endpoint API /api/sales.');
    }

    public function indexApi(Request $request)
    {
        $userId = $request->user()->id;
        $perPage = $request->input('per_page', 15);
        $seasonId = $request->input('season_id');

        $query = Sale::where('user_id', $userId)->latest('date');
        if ($seasonId) {
            $query->where('season_id', $seasonId);
        }

        $sales = $query->paginate($perPage);
        $totalSales = Sale::where('user_id', $userId)->sum('total');
        $averagePrice = Sale::where('user_id', $userId)->avg('price_per_kg');

        return $this->successResponse([
            'sales' => $sales->items(),
            'pagination' => [
                'total' => $sales->total(),
                'per_page' => $sales->perPage(),
                'current_page' => $sales->currentPage(),
                'last_page' => $sales->lastPage(),
            ],
            'total_sales' => (int)$totalSales,
            'average_price' => (int)$averagePrice,
        ], 'Daftar penjualan.');
    }

    public function store(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->storeApi($request);
        }

        return $this->disabledWebResponse('Endpoint pencatatan penjualan hanya tersedia melalui API. Gunakan POST /api/sales.');
    }

    public function storeApi(Request $request)
    {
        $validated = $request->validate([
            'season_id'     => 'nullable|integer|exists:seasons,id',
            'quantity'      => 'required_without:weight_kg|numeric|min:0.01',
            'weight_kg'     => 'required_without:quantity|numeric|min:0.01',
            'price_per_unit'=> 'required_without:price_per_kg|numeric|min:0.01',
            'price_per_kg'  => 'required_without:price_per_unit|numeric|min:0.01',
            'sale_date'     => 'nullable|date',
            'date'          => 'nullable|date',
            'buyer_name'    => 'required|string|max:255',
            'buyer_phone'   => 'nullable|string|max:20',
            'notes'         => 'nullable|string|max:1000',
            'status'        => 'nullable|string',
            'payment_status'=> 'nullable|in:paid,unpaid',
        ], [
            'buyer_name.required' => 'Nama pembeli harus diisi.',
            'buyer_name.max'      => 'Nama pembeli maksimal 255 karakter.',
        ]);

        $weightKg = $validated['weight_kg'] ?? $validated['quantity'] ?? 0;
        $pricePerKg = $validated['price_per_kg'] ?? $validated['price_per_unit'] ?? 0;
        $total = $weightKg * $pricePerKg;
        $date = $validated['date'] ?? $validated['sale_date'] ?? now()->toDateString();
        
        $paymentStatus = 'paid';
        if (isset($validated['payment_status'])) {
            $paymentStatus = $validated['payment_status'];
        } elseif (isset($validated['status'])) {
            $paymentStatus = in_array(strtolower($validated['status']), ['paid', 'completed']) ? 'paid' : 'unpaid';
        }

        $dbData = [
            'user_id' => $request->user()->id,
            'season_id' => $validated['season_id'] ?? null,
            'date' => $date,
            'buyer_name' => $validated['buyer_name'],
            'buyer_phone' => $validated['buyer_phone'] ?? null,
            'weight_kg' => $weightKg,
            'price_per_kg' => $pricePerKg,
            'total' => $total,
            'payment_status' => $paymentStatus,
            'notes' => $validated['notes'] ?? null,
        ];

        $sale = Sale::create($dbData);

        StockTransaction::addTransaction('out', $weightKg, 'Penjualan', 'sale_' . $sale->id, $request->user()->id);

        return $this->successResponse([
            'id' => $sale->id,
            'sale_date' => $sale->date->toDateString(),
            'buyer_name' => $sale->buyer_name,
            'buyer_phone' => $sale->buyer_phone,
            'quantity' => (int)$sale->weight_kg,
            'price_per_unit' => (int)$sale->price_per_kg,
            'total_price' => (int)$sale->total,
            'notes' => $sale->notes,
            'status' => $sale->payment_status === 'paid' ? 'completed' : 'pending',
            'created_at' => $sale->created_at->toIso8601String(),
        ], 'Penjualan berhasil dicatat.', 201);
    }

    public function update(Request $request, Sale $sale)
    {
        if ($request->wantsJson()) {
            return $this->updateApi($request, $sale);
        }

        return $this->disabledWebResponse('Endpoint pembaruan penjualan hanya tersedia melalui API. Gunakan PUT /api/sales/{id}.');
    }

    public function updateApi(Request $request, Sale $sale)
    {
        // Check authorization
        if ($sale->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak mengubah data ini.');
        }

        $validated = $request->validate([
            'season_id'     => 'sometimes|required|integer|exists:seasons,id',
            'quantity'      => 'sometimes|required_without:weight_kg|numeric|min:0.01',
            'weight_kg'     => 'sometimes|required_without:quantity|numeric|min:0.01',
            'price_per_unit'=> 'sometimes|required_without:price_per_kg|numeric|min:0.01',
            'price_per_kg'  => 'sometimes|required_without:price_per_unit|numeric|min:0.01',
            'sale_date'     => 'nullable|date',
            'date'          => 'nullable|date',
            'buyer_name'    => 'sometimes|required|string|max:255',
            'buyer_phone'   => 'nullable|string|max:20',
            'notes'         => 'nullable|string|max:1000',
            'status'        => 'nullable|string',
            'payment_status'=> 'nullable|in:paid,unpaid',
        ], [
            'buyer_name.required' => 'Nama pembeli harus diisi.',
            'buyer_name.max'      => 'Nama pembeli maksimal 255 karakter.',
        ]);

        $dbData = [];
        if (isset($validated['season_id'])) $dbData['season_id'] = $validated['season_id'];
        if (isset($validated['buyer_name'])) $dbData['buyer_name'] = $validated['buyer_name'];
        if (isset($validated['buyer_phone'])) $dbData['buyer_phone'] = $validated['buyer_phone'];
        if (isset($validated['notes'])) $dbData['notes'] = $validated['notes'];
        
        $newDate = $validated['date'] ?? $validated['sale_date'] ?? null;
        if ($newDate) $dbData['date'] = $newDate;

        $weightKg = $validated['weight_kg'] ?? $validated['quantity'] ?? null;
        if ($weightKg !== null) $dbData['weight_kg'] = $weightKg;

        $pricePerKg = $validated['price_per_kg'] ?? $validated['price_per_unit'] ?? null;
        if ($pricePerKg !== null) $dbData['price_per_kg'] = $pricePerKg;

        // Recalculate total if quantity or price changed
        if (isset($dbData['weight_kg']) || isset($dbData['price_per_kg'])) {
            $w = $dbData['weight_kg'] ?? $sale->weight_kg;
            $p = $dbData['price_per_kg'] ?? $sale->price_per_kg;
            $dbData['total'] = $w * $p;
        }

        if (isset($validated['payment_status'])) {
            $dbData['payment_status'] = $validated['payment_status'];
        } elseif (isset($validated['status'])) {
            $dbData['payment_status'] = in_array(strtolower($validated['status']), ['paid', 'completed']) ? 'paid' : 'unpaid';
        }

        $oldWeight = $sale->weight_kg;
        $sale->update($dbData);

        if (isset($dbData['weight_kg']) && $oldWeight != $dbData['weight_kg']) {
            $difference = $oldWeight - $dbData['weight_kg'];
            StockTransaction::addTransaction(
                $difference > 0 ? 'in' : 'out',
                abs($difference),
                'Penjualan diupdate',
                'sale_' . $sale->id,
                $request->user()->id
            );
        }

        return $this->successResponse([
            'id' => $sale->id,
            'sale_date' => $sale->date->toDateString(),
            'buyer_name' => $sale->buyer_name,
            'buyer_phone' => $sale->buyer_phone,
            'quantity' => (int)$sale->weight_kg,
            'price_per_unit' => (int)$sale->price_per_kg,
            'total_price' => (int)$sale->total,
            'notes' => $sale->notes,
            'status' => $sale->payment_status === 'paid' ? 'completed' : 'pending',
            'updated_at' => $sale->updated_at->toIso8601String(),
        ], 'Penjualan berhasil diperbarui.', 200);
    }

    public function destroy(Request $request, Sale $sale)
    {
        if ($request->wantsJson()) {
            return $this->destroyApi($request, $sale);
        }

        return $this->disabledWebResponse('Endpoint hapus penjualan hanya tersedia melalui API. Gunakan DELETE /api/sales/{id}.');
    }

    public function destroyApi(Request $request, Sale $sale)
    {
        if ($sale->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak menghapus data ini.');
        }

        $oldWeight = $sale->weight_kg;
        $sale->delete();
        
        StockTransaction::addTransaction('in', $oldWeight, 'Penjualan dihapus', 'sale_deleted', $request->user()->id);
        
        return $this->successResponse(null, 'Penjualan berhasil dihapus.', 200);
    }
}
