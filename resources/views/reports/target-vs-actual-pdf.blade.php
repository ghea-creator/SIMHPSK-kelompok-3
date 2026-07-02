<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    <title>Laporan Target vs Realisasi</title>
    <style>
        @page {
            size: A4;
            margin: 15mm 12mm 15mm 12mm;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: DejaVu Sans, sans-serif;
            font-size: 8px;
            line-height: 1.15;
            color: #222;
            background: #fff;
            padding: 4mm 0;
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

        .section-title {
            font-size: 10px;
            font-weight: bold;
            color: #1B5E20;
            border-bottom: 1px solid #1B5E20;
            padding-bottom: 2px;
            margin-bottom: 4px;
        }
        .section-desc {
            font-size: 7px;
            color: #666;
            margin-bottom: 6px;
        }

        table.data-table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 6px;
            font-size: 8px;
            table-layout: fixed;
        }
        table.data-table colgroup col:first-child { width: 6%; }
        table.data-table colgroup col:nth-child(2) { width: 30%; }
        table.data-table colgroup col:nth-child(3) { width: 12%; }
        table.data-table colgroup col:nth-child(4) { width: 12%; }
        table.data-table colgroup col:nth-child(5) { width: 12%; }
        table.data-table colgroup col:nth-child(6) { width: 15%; }
        table.data-table colgroup col:nth-child(7) { width: 13%; }
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
            vertical-align: middle;
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

        .progress-wrap {
            background: #f0f0f0;
            border-radius: 6px;
            height: 6px;
            width: 100%;
            overflow: hidden;
        }
        .progress-bar {
            height: 6px;
            border-radius: 6px;
        }
        .bar-success { background: #27AE60; }
        .bar-warning { background: #F39C12; }
        .bar-danger  { background: #EB5757; }

        .badge {
            display: inline-block;
            padding: 1px 5px;
            border-radius: 10px;
            font-size: 7px;
            font-weight: bold;
        }
        .badge-success { background: #E8F5E9; color: #27AE60; }
        .badge-warning { background: #FFF8E1; color: #F39C12; }
        .badge-danger  { background: #FFEBEE; color: #EB5757; }

        .summary-row {
            margin-bottom: 8px;
        }
        .summary-cards { width: 100%; border-collapse: collapse; margin-bottom: 10px; }
        .summary-cards td { padding: 7px 8px; border: 1px solid #e0e0e0; vertical-align: middle; }
        .card-label { font-size: 7px; color: #888; font-weight: bold; text-transform: uppercase; letter-spacing: 0.3px; }
        .card-value { font-size: 11px; font-weight: bold; margin-top: 1px; }
        .card-green .card-value { color: #27AE60; }
        .card-orange .card-value { color: #F39C12; }
        .card-blue .card-value { color: #2D9CDB; }

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
    <h1>🌿 Laporan Target vs Realisasi Panen</h1>
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
    <tr>
        <td>Jumlah Musim</td>
        <td>: {{ count($data) }} musim tanam</td>
    </tr>
</table>

{{-- Summary Stats --}}
@php
    $totalSukses  = count(array_filter($data, fn($d) => $d['percentage'] >= 100));
    $totalHampir  = count(array_filter($data, fn($d) => $d['percentage'] >= 70 && $d['percentage'] < 100));
    $totalKurang  = count(array_filter($data, fn($d) => $d['percentage'] < 70));
@endphp

<table class="summary-cards">
    <tr>
        <td class="card-green">
            <div class="card-label">Tercapai (≥100%)</div>
            <div class="card-value">{{ $totalSukses }} musim</div>
        </td>
        <td class="card-orange">
            <div class="card-label">Hampir Tercapai (70-99%)</div>
            <div class="card-value">{{ $totalHampir }} musim</div>
        </td>
        <td>
            <div class="card-label" style="color:#888;">Kurang (<70%)</div>
            <div class="card-value" style="color:#EB5757;">{{ $totalKurang }} musim</div>
        </td>
    </tr>
</table>

<div class="section-title">Rincian Realisasi per Musim Tanam</div>
<div class="section-desc">Perbandingan bobot panen aktual terhadap target awal yang ditetapkan.</div>

@if(count($data) > 0)
<table class="data-table">
    <colgroup>
        <col style="width:6%;" />
        <col style="width:30%;" />
        <col style="width:12%;" />
        <col style="width:12%;" />
        <col style="width:12%;" />
        <col style="width:15%;" />
        <col style="width:13%;" />
    </colgroup>
    <thead>
        <tr>
            <th>#</th>
            <th>Nama Musim Tanam</th>
            <th class="text-right">Target (kg)</th>
            <th class="text-right">Aktual (kg)</th>
            <th class="text-right">Selisih (kg)</th>
            <th class="text-center">Realisasi</th>
            <th class="text-center">Status</th>
        </tr>
    </thead>
    <tbody>
        @foreach($data as $i => $item)
        @php
            $selisih = $item['actual'] - $item['target'];
            $badgeClass = $item['percentage'] >= 100 ? 'badge-success' : ($item['percentage'] >= 70 ? 'badge-warning' : 'badge-danger');
            $barClass   = $item['percentage'] >= 100 ? 'bar-success' : ($item['percentage'] >= 70 ? 'bar-warning' : 'bar-danger');
            $width      = min($item['percentage'], 100);
        @endphp
        <tr>
            <td class="text-center">{{ $i + 1 }}</td>
            <td><strong>{{ $item['season'] }}</strong></td>
            <td class="text-right">{{ number_format($item['target'], 0, ',', '.') }}</td>
            <td class="text-right">{{ number_format($item['actual'], 0, ',', '.') }}</td>
            <td class="text-right" style="color:{{ $selisih >= 0 ? '#27AE60' : '#EB5757' }}">
                {{ $selisih >= 0 ? '+' : '' }}{{ number_format($selisih, 0, ',', '.') }}
            </td>
            <td>
                <div class="progress-wrap">
                    <div class="progress-bar {{ $barClass }}" style="width:{{ $width }}%;"></div>
                </div>
                <div style="text-align:center; font-size:9px; margin-top:2px; font-weight:bold;">{{ number_format($item['percentage'], 1) }}%</div>
            </td>
            <td class="text-center">
                <span class="badge {{ $badgeClass }}">{{ $item['status'] }}</span>
            </td>
        </tr>
        @endforeach
    </tbody>
</table>
@else
<p style="color:#888; padding: 20px; text-align: center;">Belum ada data musim tanam terdaftar.</p>
@endif

<div class="footer">
    Laporan ini digenerate otomatis oleh sistem Pertanian Kentang &bull; {{ now()->format('d M Y H:i:s') }}
</div>

</body>
</html>
