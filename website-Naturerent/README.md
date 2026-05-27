# 🌲 NatureRent - Operations Portal (Admin Portal)

Portal Operasional untuk mengelola dan memonitor data NatureRent (Dashboard, Komisi, Pemilik Rental, Pengguna, dan Transaksi).

## 🚀 Panduan Memulai di Laptop Baru (Setup Kelompok)

Jika anggota kelompok Anda baru saja melakukan `pull` projek ini dan ingin menjalankannya secara lokal, ikuti langkah-langkah di bawah ini agar sistem login dan database berfungsi dengan benar:

### 1. Salin Environment Variables (`.env.local`)
Karena berkas `.env.local` diabaikan oleh Git untuk alasan keamanan, anggota kelompok **wajib** menyalin berkas `.env.example` menjadi `.env.local`:

```bash
# Masuk ke direktori portal website
cd website-Naturerent

# Salin berkas .env.example menjadi .env.local
cp .env.example .env.local
```

> [!IMPORTANT]
> Pastikan isi berkas `.env.local` memiliki kunci-kunci berikut yang valid agar koneksi ke Supabase berfungsi:
> - `NEXT_PUBLIC_SUPABASE_URL`
> - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
> - `SUPABASE_SERVICE_ROLE_KEY` (Sangat penting agar fitur Edit & Hapus Pengguna tidak terblokir RLS)

### 2. Instal Dependensi
Jalankan perintah berikut untuk menginstal seluruh pustaka yang diperlukan:

```bash
npm install
```

### 3. Jalankan Server Pengembangan
Setelah konfigurasi lingkungan selesai, jalankan server Next.js lokal:

```bash
npm run dev
```

Buka [http://localhost:3000](http://localhost:3000) di browser untuk mengakses portal admin.

---

## 🛠️ Pemecahan Masalah (Troubleshooting)

### ❓ Masalah 1: Login stuck (berputar terus) atau muncul eror saat klik "Masuk"
* **Penyebab:** Berkas `.env.local` belum dibuat atau nilainya kosong/salah, sehingga Supabase Client tidak dapat menginisialisasi URL koneksi (`undefined`).
* **Solusi:** Buat berkas `.env.local` di dalam direktori `website-Naturerent` dan isi sesuai dengan `.env.example`.

### ❓ Masalah 2: Bisa login, tapi data tabel kosong atau tidak dapat diakses
* **Penyebab:** Koneksi database belum terhubung dengan akun Supabase yang sama, atau aturan Row Level Security (RLS) menghalangi akses data.
* **Solusi:** Pastikan `NEXT_PUBLIC_SUPABASE_URL` dan `NEXT_PUBLIC_SUPABASE_ANON_KEY` merujuk ke database Supabase kelompok Anda yang aktif dan memiliki data dummy/asli.

