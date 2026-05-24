<?php
declare(strict_types=1);

session_start();

require __DIR__ . '/supabase.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Location: ../../indexlogin.php');
    exit;
}

$email = trim((string) ($_POST['email'] ?? ''));
$password = (string) ($_POST['password'] ?? '');

if ($email === '' || $password === '') {
    $_SESSION['login_error'] = 'Silakan isi email dan kata sandi.';
    header('Location: ../../indexlogin.php');
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $_SESSION['login_error'] = 'Format email tidak valid.';
    header('Location: ../../indexlogin.php');
    exit;
}

$response = loginWithSupabase($email, $password);

if (!$response['ok'] || !is_array($response['data'])) {
    $_SESSION['login_error'] = $response['error'] ?: 'Email atau kata sandi salah.';
    header('Location: ../../indexlogin.php');
    exit;
}

$authData = $response['data'];

$_SESSION['supabase_access_token'] = $authData['access_token'] ?? '';
$_SESSION['supabase_refresh_token'] = $authData['refresh_token'] ?? '';
$_SESSION['supabase_user'] = $authData['user'] ?? null;
$_SESSION['user_email'] = $authData['user']['email'] ?? $email;

header('Location: ../../dashboard.html');
exit;
