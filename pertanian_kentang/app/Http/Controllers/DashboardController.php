<?php

namespace App\Http\Controllers;

use App\Models\DashboardMenu;
use App\Models\Harvest;
use App\Models\ProductionCost;
use App\Models\Sale;
use App\Models\Season;
use App\Models\StockTransaction;
use App\Traits\ApiResponseTrait;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    use ApiResponseTrait;
    public function index(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->indexApi($request);
        }

        return $this->disabledWebResponse('Halaman dashboard dinonaktifkan. Gunakan endpoint API /api/dashboard.');
    }

    public function indexApi(Request $request)
    {
        $userId = $request->user()->id;
        $activeSeason = Season::where('user_id', $userId)->where('status', 'active')->first();
        
        $stockBalance = (int)StockTransaction::getCurrentBalance($userId);
        $totalRevenue = (int)Sale::where('user_id', $userId)->sum('total');
        $totalCost = (int)ProductionCost::where('user_id', $userId)->sum('amount');
        $estimatedProfit = $totalRevenue - $totalCost;
        $totalHarvest = (int)Harvest::where('user_id', $userId)->sum('weight_kg');

        $recentHarvests = Harvest::where('user_id', $userId)
            ->with('season')
            ->latest('date')
            ->take(5)
            ->get()
            ->map(function ($h) {
                return [
                    'id' => $h->id,
                    'season_name' => $h->season?->name ?? 'N/A',
                    'quantity' => (int)$h->weight_kg,
                    'status' => $h->status,
                ];
            });

        $recentTransactions = StockTransaction::where('user_id', $userId)
            ->latest('date')
            ->take(5)
            ->get()
            ->map(function ($t) {
                return [
                    'id' => $t->id,
                    'type' => $t->type,
                    'quantity' => (int)$t->amount,
                    'created_at' => $t->created_at->toIso8601String(),
                ];
            });

        $data = [
            'totalStok' => $stockBalance,
            'totalPenjualan' => $totalRevenue,
            'totalBiaya' => $totalCost,
            'totalPanen' => $totalHarvest,
            'targetPanen' => (int)($activeSeason?->target_kg ?? 0),
            'harvests' => $recentHarvests,
            'transactions' => $recentTransactions,
            'profitLoss' => [
                'revenue' => $totalRevenue,
                'cost' => $totalCost,
                'profit' => $estimatedProfit,
            ],
        ];

        return $this->successResponse($data, 'Data dashboard berhasil diambil.');
    }
}
