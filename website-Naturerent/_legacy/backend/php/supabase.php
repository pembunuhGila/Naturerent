<?php
declare(strict_types=1);

const SUPABASE_URL = 'https://hctdfnwfigcjycemacif.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhjdGRmbndmaWdjanljZW1hY2lmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0NTgzODUsImV4cCI6MjA5NDAzNDM4NX0.rMZ2rjhb7THR4H5hRszI7USqFwrQC-gNUY8ttjHUKfw';

function supabaseRequest(string $method, string $path, ?array $payload = null, ?string $accessToken = null): array
{
    $url = rtrim(SUPABASE_URL, '/') . '/' . ltrim($path, '/');

    $headers = [
        'Content-Type: application/json',
        'apikey: ' . SUPABASE_ANON_KEY,
    ];

    if ($accessToken !== null) {
        $headers[] = 'Authorization: Bearer ' . $accessToken;
    }

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_CUSTOMREQUEST => strtoupper($method),
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 20,
    ]);

    if ($payload !== null) {
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    }

    $rawResponse = curl_exec($ch);
    $curlError = curl_error($ch);
    $statusCode = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($rawResponse === false) {
        return [
            'ok' => false,
            'status' => 0,
            'data' => null,
            'error' => $curlError ?: 'Tidak bisa terhubung ke Supabase.',
        ];
    }

    $data = json_decode($rawResponse, true);

    return [
        'ok' => $statusCode >= 200 && $statusCode < 300,
        'status' => $statusCode,
        'data' => is_array($data) ? $data : null,
        'error' => is_array($data)
            ? ($data['msg'] ?? $data['message'] ?? $data['error_description'] ?? $data['error'] ?? null)
            : null,
    ];
}

function loginWithSupabase(string $email, string $password): array
{
    return supabaseRequest('POST', '/auth/v1/token?grant_type=password', [
        'email' => $email,
        'password' => $password,
    ]);
}
