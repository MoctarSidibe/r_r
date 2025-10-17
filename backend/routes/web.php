<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// Health check endpoint
Route::get('/health', function () {
    return response()->json([
        'status' => 'healthy',
        'timestamp' => now(),
        'service' => 'DGTT Auto-Ecole Backend',
        'version' => '1.0.0'
    ]);
});

// API health check endpoint (for Traefik routing)
Route::get('/api/health', function () {
    return response()->json([
        'status' => 'healthy',
        'timestamp' => now(),
        'service' => 'DGTT Auto-Ecole Backend',
        'version' => '1.0.0'
    ]);
});
