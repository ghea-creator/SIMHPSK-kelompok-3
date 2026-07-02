<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    <title>Laporan Laba Rugi</title>
    <style>
        @page {
            size: A4;
            margin: 0;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: DejaVu Sans, sans-serif;
            font-size: 8px;
            line-height: 1.15;
            color: #222;
            background: #fff;
            padding: 20mm;
        }
        .header {
            background: #1B5E20;
            color: white;
            padding: 8px 10px;
            border-radius: 3px;
            margin-bottom: 8px;
        }
        .header h1 { font-size: 14px; margin-bottom: 1px; }
        .header p { font-size: 7.5px; color: #A5D6A7; }
        .meta-table { width: 100%; margin-bottom: 8px; }
        .meta-table td { padding: 1px 2px; font-size: 8px; }
        .meta-table td:first-child { color: #555; width: 120px; }
        .summary-row {
            display: block;
            margin-bottom: 8px;
        }
        .summary-cards { width: 100%; border-collapse: collapse; margin-bottom: 10px; table-layout: fixed; }
        .summary-cards td { padding: 7px 8px; border: 1px solid #e0e0e0; vertical-align: top; border-radius: 3px; width:33%; }
        .summary-cards .card-label { font-size: 7px; color: #888; font-weight: bold; text-transform: uppercase; letter-spacing: 0.3px; }
        .summary-cards .card-value { font-size: 11px; font-weight: bold; margin-top: 1px; }
        .card-green .card-value { color: #27AE60; }
        .card-red .card-value { color: #EB5757; }
        .card-blue .card-value { color: #2D9CDB; }

        .profit-box {
            padding: 7px 8px;
            border-radius: 3px;
            margin-bottom: 10px;
            text-align: center;
        }
        .profit-box.profit { background: #1B5E20; color: white; }
        .profit-box.loss { background: #B71C1C; color: white; }
        .profit-box .label { font-size: 7px; letter-spacing: 0.7px; text-transform: uppercase; opacity: 0.82; }
        .profit-box .amount { font-size: 14px; font-weight: bold; margin-top: 2px; }

        .section-title {
            font-size: 10px;
            font-weight: bold;
            color: #1B5E20;
            border-bottom: 1px solid #1B5E20;
            padding-bottom: 2px;
            margin-bottom: 4px;
            margin-top: 8px;
        }

        table.data-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 6px;
            font-size: 8px;
            table-layout: fixed;
        }
        table.data-table colgroup col:first-child { width: 6%; }
        table.data-table colgroup col:nth-child(2) { width: 14%; }
        table.data-table colgroup col:nth-child(3) { width: 32%; }
        table.data-table colgroup col:nth-child(4) { width: 16%; }
        table.data-table colgroup col:nth-child(5) { width: 16%; }
        table.data-table colgroup col:nth-child(6) { width: 16%; }
        table.data-table thead th {
            background: #E8F5E9;
            color: #1B5E20;
            padding: 3px 4px;
            text-align: left;
            font-weight: bold;
            border: 1px solid #C8E6C9;
            word-break: break-word;
        }
        table.data-table tbody td {
            padding: 3px 5px;
            border: 1px solid #e0e0e0;
            vertical-align: top;
            word-break: break-word;
            white-space: normal;
        }
        table.data-table tbody tr {
            page-break-inside: avoid;
        }
        table.data-table tbody tr:nth-child(even) td {
            background: #F9FBE7;
        }
        .text-right { text-align: right; }
        .text-center { text-align: center; }
        .badge {
            display: inline-block;
            padding: 1px 5px;
            border-radius: 10px;
            font-size: 7px;
            font-weight: bold;
        }
        .badge-success { background: #E8F5E9; color: #27AE60; }
        .badge-danger { background: #FFEBEE; color: #EB5757; }
        .footer {
            margin-top: 6px;
            border-top: 1px solid #e0e0e0;
            padding-top: 4px;
            font-size: 6.5px;
            color: #aaa;
            text-align: center;
        }
    </style>
</head>
<body>

<div class="header">
    <h1>🌿 Laporan Laba Rugi</h1>
    <p>{{ $user->farm_name ?? $user->name }} &bull; Dicetak pada {{ now()->format('d M Y, H:i') }}</p>
</div>

<table class="meta-table">
    <tr>
        <td>Petani / Kelompok</td>
        <td>: <strong>{{ $user->name }}</strong></td>
    </tr>
    <tr>
        <td>Email</td>
        <td>: {{ $user->email }}</td>
    </tr>
    <tr>
        <td>Tanggal Cetak</td>
        <td>: {{ now()->format('d F Y') }}</td>
    </tr>
</table>

{{-- Summary Cards --}}
<table class="summary-cards">
    <tr>
        <td class="card-green">
            <div class="card-label">Total Pendapatan</div>
            <div class="card-value">Rp {{ number_format($totalRevenue, 0, ',', '.') }}</div>
        </td>
        <td class="card-red">
            <div class="card-label">Total Biaya Produksi</div>
            <div class="card-value">Rp {{ number_format($totalCost, 0, ',', '.') }}</div>
        </td>
        <td class="{{ $profit >= 0 ? 'card-green' : 'card-red' }}">
            <div class="card-label">{{ $profit >= 0 ? 'Keuntungan Bersih' : 'Kerugian Bersih' }}</div>
            <div class="card-value">Rp {{ number_format(abs($profit), 0, ',', '.') }}</div>
        </td>
    </tr>
</table>

{{-- Profit / Loss Banner --}}
<div class="profit-box {{ $profit >= 0 ? 'profit' : 'loss' }}">
    <div class="label">{{ $profit >= 0 ? 'TOTAL KEUNTUNGAN BERSIH' : 'TOTAL KERUGIAN BERSIH' }}</div>
    <div class="amount">Rp {{ number_format(abs($profit), 0, ',', '.') }}</div>
</div>

{{-- Rincian Penjualan --}}
@if($sales->count() > 0)
<div class="section-title">Rincian Penjualan</div>
<table class="data-table">
    <colgroup>
        <col style="width:6%;" />
        <col style="width:14%;" />
        <col style="width:32%;" />
        <col style="width:16%;" />
        <col style="width:16%;" />
        <col style="width:16%;" />
    </colgroup>
    <thead>
        <tr>
            <th>#</th>
            <th>Tanggal</th>
            <th>Pembeli</th>
            <th>Musim Tanam</th>
            <th class="text-right">Harga/kg</th>
            <th class="text-right">Total</th>
        </tr>
    </thead>
    <tbody>
        @foreach($sales as $i => $sale)
        <tr>
            <td class="text-center">{{ $i + 1 }}</td>
            <td>{{ \Carbon\Carbon::parse($sale->sale_date ?? $sale->date)->format('d M Y') }}</td>
            <td>{{ $sale->buyer_name }}</td>
            <td>{{ $sale->season->name ?? '-' }}</td>
            <td class="text-right">Rp {{ number_format($sale->price_per_kg, 0, ',', '.') }}</td>
            <td class="text-right">Rp {{ number_format($sale->total, 0, ',', '.') }}</td>
        </tr>
        @endforeach
        <tr>
            <td colspan="5" class="text-right"><strong>Total Pendapatan</strong></td>
            <td class="text-right"><strong>Rp {{ number_format($totalRevenue, 0, ',', '.') }}</strong></td>
        </tr>
    </tbody>
</table>
@endif

{{-- Rincian Biaya Produksi --}}
@if($costs->count() > 0)
<div class="section-title">Rincian Biaya Produksi</div>
<table class="data-table">
    <colgroup>
        <col style="width:6%;" />
        <col style="width:14%;" />
        <col style="width:18%;" />
        <col style="width:16%;" />
        <col style="width:30%;" />
        <col style="width:16%;" />
    </colgroup>
    <thead>
        <tr>
            <th>#</th>
            <th>Tanggal</th>
            <th>Kategori</th>
            <th>Musim Tanam</th>
            <th>Keterangan</th>
            <th class="text-right">Jumlah</th>
        </tr>
    </thead>
    <tbody>
        @foreach($costs as $i => $cost)
        <tr>
            <td class="text-center">{{ $i + 1 }}</td>
            <td>{{ \Carbon\Carbon::parse($cost->date)->format('d M Y') }}</td>
            <td>{{ $cost->category }}</td>
            <td>{{ $cost->season->name ?? '-' }}</td>
            <td>{{ $cost->notes ?? '-' }}</td>
            <td class="text-right">Rp {{ number_format($cost->amount, 0, ',', '.') }}</td>
        </tr>
        @endforeach
        <tr>
            <td colspan="5" class="text-right"><strong>Total Biaya</strong></td>
            <td class="text-right"><strong>Rp {{ number_format($totalCost, 0, ',', '.') }}</strong></td>
        </tr>
    </tbody>
</table>
@endif

<div class="footer">
    Laporan ini digenerate otomatis oleh sistem Pertanian Kentang &bull; {{ now()->format('d M Y H:i:s') }}
</div>

</body>
</html>
