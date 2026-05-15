<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// ALB health check — must respond quickly with 200, no DB dependency
Route::get('/health', function () {
    return response('healthy', 200)->header('Content-Type', 'text/plain');
});
