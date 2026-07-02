<?php
require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

Illuminate\Support\Facades\Auth::loginUsingId(1);
$request = new Illuminate\Http\Request();
$controller = app(\App\Http\Controllers\ReportController::class);
$response = $controller->exportProfitLossPdf($request);
file_put_contents(__DIR__.'/../storage/app/public/sample_profit.pdf', $response->getContent());
echo "saved\n";