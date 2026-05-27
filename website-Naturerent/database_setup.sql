-- ============================================================================
-- NATURE RENT - DATABASE PRIVILEGES & SECURITY SETUP
-- ============================================================================
-- File ini mendokumentasikan semua perubahan hak akses (privileges) dan 
-- kebijakan keamanan (RLS) yang diperlukan di Supabase PostgreSQL agar 
-- aplikasi web admin Next.js dapat melakukan operasi CRUD secara penuh.
--
-- CARA PENGGUNAAN:
-- Salin seluruh isi berkas ini dan tempel (paste) ke dalam menu SQL Editor
-- di dashboard Supabase Anda, lalu klik "Run".
-- ============================================================================

-- ----------------------------------------------------------------------------
-- BAGIAN 1: HAK AKSES TINGKAT TABEL (TABLE-LEVEL PRIVILEGES / GRANTS)
-- ----------------------------------------------------------------------------
-- Penjelasan: Error "permission denied for table users" dipicu oleh tidak
-- adanya hak izin dasar tingkat PostgreSQL untuk melakukan operasi UPDATE/DELETE 
-- pada tabel 'users' untuk peran API Supabase ('anon' dan 'authenticated').
-- Query di bawah memulihkan hak akses default Supabase secara menyeluruh.

-- A. Berikan izin penggunaan skema public
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- B. Berikan hak akses CRUD penuh ke tabel-tabel utama
GRANT ALL PRIVILEGES ON TABLE public.users TO anon, authenticated, service_role;
GRANT ALL PRIVILEGES ON TABLE public.rental_profiles TO anon, authenticated, service_role;
GRANT ALL PRIVILEGES ON TABLE public.bookings TO anon, authenticated, service_role;

-- C. Berikan hak akses ke seluruh sekuensial (untuk auto-increment ID jika ada)
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

-- D. Atur hak akses otomatis untuk tabel baru di masa mendatang
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;

-- ----------------------------------------------------------------------------
-- BAGIAN 2: KEBIJAKAN KEAMANAN TINGKAT BARIS (ROW LEVEL SECURITY - RLS)
-- ----------------------------------------------------------------------------
-- Penjelasan: RLS digunakan untuk menyaring baris mana saja yang boleh diakses.
-- Kebijakan di bawah ini dirancang agar dinamis dan aman:
-- 1. Peran ADMIN memiliki hak akses CRUD penuh di semua tabel.
-- 2. Pengguna BIASA (misal aplikasi Flutter / mobile) tetap dapat mengakses &
--    mengelola data milik mereka sendiri secara aman tanpa ada gangguan integrasi.

-- A. Aktifkan RLS di seluruh tabel utama
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rental_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- B. Buat Fungsi Helper untuk mengecek apakah user yang sedang login adalah admin
-- Fungsi ini membaca kolom 'role' pada tabel 'public.users' secara aman.
-- Menggunakan SECURITY DEFINER agar fungsi dieksekusi dengan hak akses superuser,
-- sehingga menghindari masalah "infinite recursion" RLS pada tabel users.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- C. KEBIJAKAN AKSES PADA TABEL 'users'
-- 1. Akses CRUD penuh untuk Admin
DROP POLICY IF EXISTS "Admin full access on users" ON public.users;
CREATE POLICY "Admin full access on users" ON public.users
    FOR ALL TO authenticated USING (public.is_admin() = true) WITH CHECK (public.is_admin() = true);

-- 2. Izin SELECT untuk pengguna membaca profil mereka sendiri (misal untuk Login / Flutter)
DROP POLICY IF EXISTS "Users can read own profile" ON public.users;
CREATE POLICY "Users can read own profile" ON public.users
    FOR SELECT TO authenticated USING (auth.uid() = id);

-- 3. Izin UPDATE untuk pengguna mengubah profil mereka sendiri (misal ubah no_wa / nama)
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- 4. Izin INSERT untuk pendaftaran akun baru (baik anonim maupun terautentikasi saat Sign Up)
DROP POLICY IF EXISTS "Enable insert access for all users" ON public.users;
CREATE POLICY "Enable insert access for all users" ON public.users
    FOR INSERT WITH CHECK (true);


-- D. KEBIJAKAN AKSES PADA TABEL 'rental_profiles'
-- 1. Akses CRUD penuh untuk Admin
DROP POLICY IF EXISTS "Admin full access on rental_profiles" ON public.rental_profiles;
CREATE POLICY "Admin full access on rental_profiles" ON public.rental_profiles
    FOR ALL TO authenticated USING (public.is_admin() = true) WITH CHECK (public.is_admin() = true);

-- 2. Akses CRUD penuh untuk pemilik rental mengelola profil rental mereka sendiri
DROP POLICY IF EXISTS "Owners can manage own rental profiles" ON public.rental_profiles;
CREATE POLICY "Owners can manage own rental profiles" ON public.rental_profiles
    FOR ALL TO authenticated USING (auth.uid() = owner_id) WITH CHECK (auth.uid() = owner_id);

-- 3. Akses SELECT publik agar semua pengguna (anon/terautentikasi) dapat mencari rental
DROP POLICY IF EXISTS "Allow public read-only access to active rental profiles" ON public.rental_profiles;
CREATE POLICY "Allow public read-only access to active rental profiles" ON public.rental_profiles
    FOR SELECT TO anon, authenticated USING (is_active = true);


-- E. KEBIJAKAN AKSES PADA TABEL 'bookings'
-- 1. Akses CRUD penuh untuk Admin
DROP POLICY IF EXISTS "Admin full access on bookings" ON public.bookings;
CREATE POLICY "Admin full access on bookings" ON public.bookings
    FOR ALL TO authenticated USING (public.is_admin() = true) WITH CHECK (public.is_admin() = true);

-- 2. Akses CRUD penuh untuk Pelanggan mengelola pemesanan mereka sendiri
DROP POLICY IF EXISTS "Customers can manage own bookings" ON public.bookings;
CREATE POLICY "Customers can manage own bookings" ON public.bookings
    FOR ALL TO authenticated USING (auth.uid() = customer_id) WITH CHECK (auth.uid() = customer_id);

-- 3. Izin SELECT untuk pemilik rental melihat transaksi masuk ke rental mereka
DROP POLICY IF EXISTS "Owners can view bookings for their rentals" ON public.bookings;
CREATE POLICY "Owners can view bookings for their rentals" ON public.bookings
    FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.rental_profiles rp
            WHERE rp.id = rental_id AND rp.owner_id = auth.uid()
        )
    );

-- ----------------------------------------------------------------------------
-- BAGIAN 3: KONFIGURASI PENDUKUNG QRIS PER RENTAL
-- ----------------------------------------------------------------------------
-- A. Tambahkan kolom qris_image_url dan qris_merchant_name ke rental_profiles jika belum ada
ALTER TABLE public.rental_profiles
  ADD COLUMN IF NOT EXISTS qris_image_url text,
  ADD COLUMN IF NOT EXISTS qris_merchant_name text;

-- B. Kebijakan Keamanan (RLS) untuk Storage Bucket 'qris-images'
-- Pengguna terautentikasi (admin/pemilik rental) diizinkan untuk mengunggah dan memperbarui file.
-- Semua pengguna (termasuk anonim) diizinkan untuk membaca gambar QRIS.

-- 1. Kebijakan SELECT (Membaca file)
DROP POLICY IF EXISTS "Public can read qris images" ON storage.objects;
CREATE POLICY "Public can read qris images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'qris-images');

-- 2. Kebijakan INSERT (Mengunggah file)
DROP POLICY IF EXISTS "Authenticated can upload qris images" ON storage.objects;
CREATE POLICY "Authenticated can upload qris images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'qris-images');

-- 3. Kebijakan UPDATE (Memperbarui file)
DROP POLICY IF EXISTS "Authenticated can update qris images" ON storage.objects;
CREATE POLICY "Authenticated can update qris images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'qris-images')
WITH CHECK (bucket_id = 'qris-images');

-- 4. Kebijakan DELETE (Menghapus file)
DROP POLICY IF EXISTS "Authenticated can delete qris images" ON storage.objects;
CREATE POLICY "Authenticated can delete qris images"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'qris-images');

-- ============================================================================
-- AKHIR DARI SCRIPT
-- ============================================================================
