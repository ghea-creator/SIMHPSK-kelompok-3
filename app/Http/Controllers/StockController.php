<?php

namespace App\Http\Controllers;

use App\Models\Setting;
use App\Models\StockTransaction;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class StockController extends Controller
{
    use ApiResponseTrait;

    // ============ API Methods ============

    /**
     * Get stock status and transactions - API
     */
    public function index(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->indexApi($request);
        }

        return $this->disabledWebResponse('Halaman stok gudang dinonaktifkan. Gunakan endpoint API /api/stock.');
    }

    /**
     * Get stock status and transactions - API
     */
    public function indexApi(Request $request)
    {
        $userId = $request->user()->id;
        $currentBalance = (int)StockTransaction::getCurrentBalance($userId);
        $totalIncoming = (int)StockTransaction::where('user_id', $userId)->where('type', 'in')->sum('amount');
        $totalOutgoing = (int)StockTransaction::where('user_id', $userId)->where('type', 'out')->sum('amount');

        $transactions = StockTransaction::where('user_id', $userId)
            ->latest('date')
            ->get()
            ->map(function ($t) {
                return [
                    'id' => $t->id,
                    'type' => $t->type,
                    'quantity' => (int)$t->amount,
                    'transaction_date' => $t->date,
                    'notes' => $t->notes,
                    'reference' => $t->reference,
                    'created_at' => $t->created_at->toIso8601String(),
                ];
            });

        return $this->successResponse([
            'totalIncoming' => $totalIncoming,
            'totalOutgoing' => $totalOutgoing,
            'currentStock' => $currentBalance,
            'transactions' => $transactions,
        ], 'Status persediaan barang.');
    }

    /**
     * Add incoming stock - API
     */
    public function storeIncoming(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->storeIncomingApi($request);
        }

        return $this->disabledWebResponse('Endpoint transaksi masuk stok hanya tersedia melalui API. Gunakan POST /api/stock/in.');
    }

    /**
     * Add incoming stock - API
     */
    public function storeIncomingApi(Request $request)
    {
        try {
            $validated = $request->validate([
                'amount' => 'required|numeric|min:0.01',
                'notes' => 'required|string|max:255',
            ]);

            $transaction = StockTransaction::addTransaction('in', $validated['amount'], $validated['notes'], null, $request->user()->id);

            return $this->successResponse([
                'id' => $transaction->id,
                'type' => $transaction->type,
                'amount' => $transaction->amount,
                'balance_after' => $transaction->balance_after,
                'notes' => $transaction->notes,
                'date' => $transaction->date,
                'created_at' => $transaction->created_at,
            ], 'Transaksi masuk berhasil dicatat.', 201);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }

    /**
     * Add outgoing stock - API
     */
    public function storeOutgoing(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->storeOutgoingApi($request);
        }

        return $this->disabledWebResponse('Endpoint transaksi keluar stok hanya tersedia melalui API. Gunakan POST /api/stock/out.');
    }

    /**
     * Add outgoing stock - API
     */
    public function storeOutgoingApi(Request $request)
    {
        try {
            $validated = $request->validate([
                'amount' => 'required|numeric|min:0.01',
                'notes' => 'required|string|max:255',
            ]);

            $transaction = StockTransaction::addTransaction('out', $validated['amount'], $validated['notes'], null, $request->user()->id);

            return $this->successResponse([
                'id' => $transaction->id,
                'type' => $transaction->type,
                'amount' => $transaction->amount,
                'balance_after' => $transaction->balance_after,
                'notes' => $transaction->notes,
                'date' => $transaction->date,
                'created_at' => $transaction->created_at,
            ], 'Transaksi keluar berhasil dicatat.', 201);
        } catch (ValidationException $e) {
            return $this->validationErrorResponse($e->errors());
        }
    }

    /**
     * Delete stock transaction - API
     */
    public function destroyTransaction(Request $request, StockTransaction $transaction)
    {
        if ($request->wantsJson()) {
            return $this->destroyTransactionApi($request, $transaction);
        }

        return $this->disabledWebResponse('Endpoint hapus transaksi stok hanya tersedia melalui API. Gunakan DELETE /api/stock/{transaction}.');
    }

    /**
     * Delete stock transaction - API
     */
    public function destroyTransactionApi(Request $request, StockTransaction $transaction)
    {
        // Check authorization
        if ($transaction->user_id !== $request->user()->id) {
            return $this->forbiddenResponse('Anda tidak berhak menghapus data ini.');
        }

        $transaction->delete();
        StockTransaction::rebuildBalances($request->user()->id);

        return $this->successResponse(null, 'Transaksi berhasil dihapus.', 200);
    }
}
