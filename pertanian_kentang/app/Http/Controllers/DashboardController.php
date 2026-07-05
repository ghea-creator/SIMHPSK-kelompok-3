<?php

namespace App\Http\Controllers;

use App\Models\DashboardMenu;
use App\Models\Harvest;
use App\Models\ProductionCost;
use App\Models\Sale;
use App\Models\Season;
use App\Models\Setting;
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

        // Get the last 6 months up to the latest recorded harvest/sale date (or current date, whichever is later)
        $latestHarvest = Harvest::where('user_id', $userId)->max('date');
        $latestSale = Sale::where('user_id', $userId)->max('date');
        
        $referenceDate = now();
        if ($latestHarvest) {
            $hDate = \Carbon\Carbon::parse($latestHarvest);
            if ($hDate->isAfter($referenceDate)) {
                $referenceDate = $hDate;
            }
        }
        if ($latestSale) {
            $sDate = \Carbon\Carbon::parse($latestSale);
            if ($sDate->isAfter($referenceDate)) {
                $referenceDate = $sDate;
            }
        }

        $monthlyStats = [];
        for ($i = 5; $i >= 0; $i--) {
            // Copy reference date and subtract months
            $date = $referenceDate->copy()->subMonths($i);
            $monthNum = $date->month;
            $year = $date->year;
            
            $monthsIndo = [
                1 => 'Jan', 2 => 'Feb', 3 => 'Mar', 4 => 'Apr', 5 => 'Mei', 6 => 'Jun',
                7 => 'Jul', 8 => 'Agt', 9 => 'Sep', 10 => 'Okt', 11 => 'Nov', 12 => 'Des'
            ];
            $label = $monthsIndo[$monthNum] ?? $date->format('M');

            $harvestSum = (double)Harvest::where('user_id', $userId)
                ->whereYear('date', $year)
                ->whereMonth('date', $monthNum)
                ->sum('weight_kg');

            $salesSum = (double)Sale::where('user_id', $userId)
                ->whereYear('date', $year)
                ->whereMonth('date', $monthNum)
                ->sum('weight_kg');

            $monthlyStats[] = [
                'label' => $label,
                'harvest' => $harvestSum,
                'sales' => $salesSum,
            ];
        }

        $data = [
            'totalStok' => $stockBalance,
            'totalPenjualan' => $totalRevenue,
            'totalBiaya' => $totalCost,
            'totalPanen' => $totalHarvest,
            'targetPanen' => (int)($activeSeason?->target_kg ?? 0),
            'minStock' => (int)Setting::get('min_stock', 100),
            'maxStock' => (int)Setting::get('max_stock', 5000),
            'notifyLowStock' => (bool)Setting::get('notify_low_stock', 1),
            'notifyNewSale' => (bool)Setting::get('notify_new_sale', 1),
            'notifyCost' => (bool)Setting::get('notify_cost', 1),
            'harvests' => $recentHarvests,
            'transactions' => $recentTransactions,
            'profitLoss' => [
                'revenue' => $totalRevenue,
                'cost' => $totalCost,
                'profit' => $estimatedProfit,
            ],
            'monthlyStats' => $monthlyStats,
        ];

        return $this->successResponse($data, 'Data dashboard berhasil diambil.');
    }
}
