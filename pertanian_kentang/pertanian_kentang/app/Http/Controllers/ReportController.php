<?php

namespace App\Http\Controllers;

use App\Models\Harvest;
use App\Models\ProductionCost;
use App\Models\Sale;
use App\Models\Season;
use App\Traits\ApiResponseTrait;
use App\Exports\ProfitLossExport;
use App\Exports\TargetVsActualExport;
use Maatwebsite\Excel\Facades\Excel;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class ReportController extends Controller
{
    use ApiResponseTrait;
    public function profitLoss(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->profitLossApi($request);
        }

        return $this->disabledWebResponse('Halaman laporan laba rugi dinonaktifkan. Gunakan endpoint API /api/reports/profit-loss.');
    }

    public function targetVsActual(Request $request)
    {
        if ($request->wantsJson()) {
            return $this->targetVsActualApi($request);
        }

        return $this->disabledWebResponse('Halaman laporan target vs realisasi dinonaktifkan. Gunakan endpoint API /api/reports/target-vs-actual.');
    }

    public function profitLossApi(Request $request)
    {
        $userId = $request->user()->id;
        $seasonId = $request->query('season_id');
        
        $harvestQuery = Harvest::where('user_id', $userId);
        if ($seasonId) {
            $harvestQuery->where('season_id', $seasonId);
        }
        $totalHarvest = (int)$harvestQuery->sum('weight_kg');

        $saleQuery = Sale::where('user_id', $userId);
        if ($seasonId) {
            $saleQuery->where('season_id', $seasonId);
        }
        $totalRevenue = (int)$saleQuery->sum('total');

        $costQuery = ProductionCost::where('user_id', $userId);
        if ($seasonId) {
            $costQuery->where('season_id', $seasonId);
        }
        $totalCost = (int)$costQuery->sum('amount');
        $profit = $totalRevenue - $totalCost;

        return $this->successResponse([
            'total_harvest_kg' => $totalHarvest,
            'total_revenue' => $totalRevenue,
            'total_cost' => $totalCost,
            'profit' => $profit,
        ], 'Laporan laba rugi berhasil diambil.');
    }

    public function targetVsActualApi(Request $request)
    {
        $userId = $request->user()->id;
        $seasons = Season::where('user_id', $userId)->get();
        
        $data = [];
        foreach ($seasons as $season) {
            $harvest = (int)$season->harvests()->sum('weight_kg');
            $target = (int)$season->target_kg;
            $percentage = $target > 0 ? round(($harvest / $target) * 100, 2) : 0;

            $data[] = [
                'season_id' => $season->id,
                'season_name' => $season->name,
                'target' => $target,
                'actual' => $harvest,
                'percentage' => $percentage,
                'status' => $percentage >= 100 ? 'success' : ($percentage >= 70 ? 'warning' : 'danger'),
            ];
        }

        return $this->successResponse($data, 'Laporan target vs realisasi berhasil diambil.');
    }

    // Export Profit-Loss Report to Excel
    public function exportProfitLossExcel(Request $request)
    {
        $userId = auth()->id();
        $seasonId = $request->query('season_id');
        $user = auth()->user();

        // Get data
        $saleQuery = Sale::where('user_id', $userId);
        $costQuery = ProductionCost::where('user_id', $userId);

        if ($seasonId) {
            $saleQuery->where('season_id', $seasonId);
            $costQuery->where('season_id', $seasonId);
        }

        $totalRevenue = $saleQuery->sum('total');
        $totalCost = $costQuery->sum('amount');
        
        $sales = $saleQuery->with('season')->get();
        $costs = $costQuery->with('season')->get();

        $filename = 'Laporan_Laba_Rugi_' . now()->format('Y-m-d_His') . '.xlsx';
        
        return Excel::download(
            new ProfitLossExport($sales, $costs, $user, $totalRevenue, $totalCost),
            $filename
        );
    }

    public function exportProfitLossPdf(Request $request)
    {
        $userId = auth()->id();
        $seasonId = $request->query('season_id');
        $user = auth()->user();

        // Get data
        $saleQuery = Sale::where('user_id', $userId);
        $costQuery = ProductionCost::where('user_id', $userId);

        if ($seasonId) {
            $saleQuery->where('season_id', $seasonId);
            $costQuery->where('season_id', $seasonId);
        }

        $totalRevenue = $saleQuery->sum('total');
        $totalCost = $costQuery->sum('amount');
        $profit = $totalRevenue - $totalCost;
        $sales = $saleQuery->with('season')->get();
        $costs = $costQuery->with('season')->get();

        $pdf = Pdf::loadView('reports.profit-loss-pdf', [
            'user' => $user,
            'totalRevenue' => $totalRevenue,
            'totalCost' => $totalCost,
            'profit' => $profit,
            'sales' => $sales,
            'costs' => $costs,
        ]);

        return $pdf->download('Laporan_Laba_Rugi_' . now()->format('Y-m-d_His') . '.pdf');
    }

    // Export Target vs Actual Report to Excel
    public function exportTargetVsActualExcel(Request $request)
    {
        $userId = auth()->id();
        $user = auth()->user();
        $seasons = Season::where('user_id', $userId)->get();

        $data = [];
        foreach ($seasons as $season) {
            $harvest = $season->harvests()->sum('weight_kg');
            $target = $season->target_kg;
            $percentage = $target > 0 ? round(($harvest / $target) * 100, 2) : 0;

            $data[] = [
                'season' => $season->name,
                'target' => $target,
                'actual' => $harvest,
                'percentage' => $percentage,
                'status' => $percentage >= 100 ? 'success' : ($percentage >= 70 ? 'warning' : 'danger'),
            ];
        }

        $filename = 'Laporan_Target_vs_Realisasi_' . now()->format('Y-m-d_His') . '.xlsx';

        return Excel::download(
            new TargetVsActualExport($data, $user),
            $filename
        );
    }

    public function exportTargetVsActualPdf(Request $request)
    {
        $userId = auth()->id();
        $user = auth()->user();
        $seasons = Season::where('user_id', $userId)->get();

        $data = [];
        foreach ($seasons as $season) {
            $harvest = $season->harvests()->sum('weight_kg');
            $target = $season->target_kg;
            $percentage = $target > 0 ? round(($harvest / $target) * 100, 2) : 0;

            $data[] = [
                'season' => $season->name,
                'target' => $target,
                'actual' => $harvest,
                'percentage' => $percentage,
                'status' => $percentage >= 100 ? 'Tercapai' : ($percentage >= 70 ? 'Hampir' : 'Kurang'),
            ];
        }

        $pdf = Pdf::loadView('reports.target-vs-actual-pdf', [
            'user' => $user,
            'data' => $data,
        ]);

        return $pdf->download('Laporan_Target_vs_Realisasi_' . now()->format('Y-m-d_His') . '.pdf');
    }

    // API Export Methods
    public function exportProfitLossExcelApi(Request $request)
    {
        try {
            $userId = $request->user()->id;
            $seasonId = $request->query('season_id');
            $user = $request->user();

            // Get data
            $saleQuery = Sale::where('user_id', $userId);
            $costQuery = ProductionCost::where('user_id', $userId);

            if ($seasonId) {
                $saleQuery->where('season_id', $seasonId);
                $costQuery->where('season_id', $seasonId);
            }

            $totalRevenue = $saleQuery->sum('total');
            $totalCost = $costQuery->sum('amount');
            
            $sales = $saleQuery->with('season')->get();
            $costs = $costQuery->with('season')->get();

            $filename = 'Laporan_Laba_Rugi_' . now()->format('Y-m-d_His') . '.xlsx';
            
            return Excel::download(
                new ProfitLossExport($sales, $costs, $user, $totalRevenue, $totalCost),
                $filename
            );
        } catch (\Exception $e) {
            return $this->errorResponse('Gagal mengexport laporan: ' . $e->getMessage(), 400);
        }
    }

    public function exportProfitLossPdfApi(Request $request)
    {
        try {
            $userId = $request->user()->id;
            $seasonId = $request->query('season_id');
            $user = $request->user();

            // Get data
            $saleQuery = Sale::where('user_id', $userId);
            $costQuery = ProductionCost::where('user_id', $userId);

            if ($seasonId) {
                $saleQuery->where('season_id', $seasonId);
                $costQuery->where('season_id', $seasonId);
            }

            $totalRevenue = $saleQuery->sum('total');
            $totalCost = $costQuery->sum('amount');
            $profit = $totalRevenue - $totalCost;
            $sales = $saleQuery->with('season')->get();
            $costs = $costQuery->with('season')->get();

            $pdf = Pdf::loadView('reports.profit-loss-pdf', [
                'user' => $user,
                'totalRevenue' => $totalRevenue,
                'totalCost' => $totalCost,
                'profit' => $profit,
                'sales' => $sales,
                'costs' => $costs,
            ]);

            return $pdf->download('Laporan_Laba_Rugi_' . now()->format('Y-m-d_His') . '.pdf');
        } catch (\Exception $e) {
            Log::error('PDF Export Error (Profit-Loss): ' . $e->getMessage() . ' | ' . $e->getTraceAsString());
            return $this->errorResponse('Gagal mengexport laporan: ' . $e->getMessage(), 500);
        }
    }

    public function exportTargetVsActualExcelApi(Request $request)
    {
        try {
            $userId = $request->user()->id;
            $user = $request->user();
            $seasons = Season::where('user_id', $userId)->get();

            $data = [];
            foreach ($seasons as $season) {
                $harvest = $season->harvests()->sum('weight_kg');
                $target = $season->target_kg;
                $percentage = $target > 0 ? round(($harvest / $target) * 100, 2) : 0;

                $data[] = [
                    'season' => $season->name,
                    'target' => $target,
                    'actual' => $harvest,
                    'percentage' => $percentage,
                    'status' => $percentage >= 100 ? 'success' : ($percentage >= 70 ? 'warning' : 'danger'),
                ];
            }

            $filename = 'Laporan_Target_vs_Realisasi_' . now()->format('Y-m-d_His') . '.xlsx';

            return Excel::download(
                new TargetVsActualExport($data, $user),
                $filename
            );
        } catch (\Exception $e) {
            return $this->errorResponse('Gagal mengexport laporan: ' . $e->getMessage(), 400);
        }
    }

    public function exportTargetVsActualPdfApi(Request $request)
    {
        try {
            $userId = $request->user()->id;
            $user = $request->user();
            $seasons = Season::where('user_id', $userId)->get();

            $data = [];
            foreach ($seasons as $season) {
                $harvest = $season->harvests()->sum('weight_kg');
                $target = $season->target_kg;
                $percentage = $target > 0 ? round(($harvest / $target) * 100, 2) : 0;

                $data[] = [
                    'season' => $season->name,
                    'target' => $target,
                    'actual' => $harvest,
                    'percentage' => $percentage,
                    'status' => $percentage >= 100 ? 'Tercapai' : ($percentage >= 70 ? 'Hampir' : 'Kurang'),
                ];
            }

            $pdf = Pdf::loadView('reports.target-vs-actual-pdf', [
                'user' => $user,
                'data' => $data,
            ]);

            return $pdf->download('Laporan_Target_vs_Realisasi_' . now()->format('Y-m-d_His') . '.pdf');
        } catch (\Exception $e) {
            Log::error('PDF Export Error (Target-vs-Actual): ' . $e->getMessage() . ' | ' . $e->getTraceAsString());
            return $this->errorResponse('Gagal mengexport laporan: ' . $e->getMessage(), 500);
        }
    }
}
