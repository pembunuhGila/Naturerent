<?php
session_start();

$loginError = $_SESSION['login_error'] ?? '';
unset($_SESSION['login_error']);
?>
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NatureRent - Masuk</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="stylelogin.css">
</head>
<body>

    <div class="container">
        <header class="logo-container">
            <i class="fa-solid fa-tree logo-icon"></i>
            <span class="logo-text">NatureRent</span>
        </header>

        <main class="login-card">
            <h2>Selamat Datang Kembali</h2>
            <p class="subtitle">Silakan masuk untuk melanjutkan petualangan Anda.</p>

            <?php if ($loginError !== ''): ?>
                <div class="alert-error" role="alert">
                    <?= htmlspecialchars($loginError, ENT_QUOTES, 'UTF-8') ?>
                </div>
            <?php endif; ?>

            <form action="backend/php/login.php" method="POST" novalidate>
                <div class="input-group">
                    <label for="email">Alamat Email</label>
                    <input type="email" id="email" name="email" placeholder="nama@email.com" required autocomplete="email">
                </div>

                <div class="input-group">
                    <div class="label-row">
                        <label for="password">Kata Sandi</label>
                        <a href="#" class="forgot-link">Lupa kata sandi?</a>
                    </div>
                    <input type="password" id="password" name="password" placeholder="Masukkan kata sandi" required autocomplete="current-password">
                </div>

                <div class="divider">
                    <span>ATAU</span>
                </div>

                <button type="button" class="google-btn" disabled title="Aktifkan provider Google di Supabase terlebih dahulu">
                    <svg class="google-icon" viewBox="0 0 24 24" width="18" height="18" xmlns="http://www.w3.org/2000/svg">
                        <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/>
                        <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                        <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z" fill="#FBBC05"/>
                        <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.57 2.82c.87-2.6 3.3-4.53 12-4.53z" fill="#EA4335"/>
                    </svg>
                    Masuk dengan Google
                </button>

                <button type="submit" class="submit-btn">Masuk</button>
            </form>
        </main>

        <footer class="page-footer">
            &copy; 2026 NatureRent. Grounded in nature.
        </footer>
    </div>
</body>
</html>
