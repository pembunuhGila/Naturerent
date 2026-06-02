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
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS phone text;

UPDATE public.users
SET phone = no_wa
WHERE (phone IS NULL OR phone = '')
  AND no_wa IS NOT NULL
  AND no_wa <> '';

CREATE TABLE IF NOT EXISTS public.rental_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  rental_id uuid UNIQUE REFERENCES public.rental_profiles(id) ON DELETE CASCADE,
  jam_operasional jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

GRANT ALL PRIVILEGES ON TABLE public.users TO anon, authenticated, service_role;
GRANT ALL PRIVILEGES ON TABLE public.rental_profiles TO anon, authenticated, service_role;
GRANT ALL PRIVILEGES ON TABLE public.rental_settings TO anon, authenticated, service_role;
GRANT ALL PRIVILEGES ON TABLE public.bookings TO anon, authenticated, service_role;
GRANT ALL PRIVILEGES ON TABLE public.commission_settings TO anon, authenticated, service_role;
GRANT ALL PRIVILEGES ON TABLE public.deliveries TO anon, authenticated, service_role;

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
ALTER TABLE public.rental_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commission_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deliveries ENABLE ROW LEVEL SECURITY;

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

-- Sinkronisasi data user baru dari Supabase Auth ke public.users.
-- Pastikan no_wa ikut tersimpan untuk fitur reset password berbasis nomor WA.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (
    id,
    email,
    nama_lengkap,
    no_wa,
    phone,
    role,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      split_part(NEW.email, '@', 1)
    ),
    COALESCE(NEW.raw_user_meta_data->>'no_wa', NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', NEW.raw_user_meta_data->>'no_wa', ''),
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'customer'::user_role),
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    nama_lengkap = EXCLUDED.nama_lengkap,
    no_wa = COALESCE(NULLIF(EXCLUDED.no_wa, ''), public.users.no_wa),
    phone = COALESCE(NULLIF(EXCLUDED.phone, ''), public.users.phone, public.users.no_wa),
    role = EXCLUDED.role,
    updated_at = NOW();

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Helper publik untuk cek email saat lupa password tanpa membuka data user lain.
-- Cek auth.users juga karena email utama Supabase Auth tersimpan di schema auth,
-- sedangkan public.users bisa saja belum tersinkron penuh.
CREATE OR REPLACE FUNCTION public.email_terdaftar(p_email text)
RETURNS boolean AS $$
DECLARE
  v_email text := lower(trim(p_email));
BEGIN
  IF v_email IS NULL OR v_email = '' THEN
    RETURN false;
  END IF;

  RETURN EXISTS (
    SELECT 1 FROM auth.users
    WHERE lower(email) = v_email
  ) OR EXISTS (
    SELECT 1 FROM public.users
    WHERE lower(email) = v_email
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

GRANT EXECUTE ON FUNCTION public.email_terdaftar(text) TO anon, authenticated;

-- Reset password dari halaman login memakai verifikasi email + nomor WA.
-- SQL-only fallback untuk demo, sehingga tidak perlu deploy Edge Function.
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION public.reset_password_dengan_wa(
  p_email text,
  p_no_wa text,
  p_password_baru text
)
RETURNS boolean AS $$
DECLARE
  v_email text := lower(trim(p_email));
  v_no_wa text := regexp_replace(coalesce(p_no_wa, ''), '\D', '', 'g');
  v_profile public.users%ROWTYPE;
  v_stored_phone text;
BEGIN
  IF v_email IS NULL OR v_email = '' OR position('@' IN v_email) = 0 THEN
    RAISE EXCEPTION 'Format email tidak valid.';
  END IF;

  IF v_no_wa LIKE '62%' THEN
    v_no_wa := '0' || substring(v_no_wa from 3);
  ELSIF v_no_wa LIKE '8%' THEN
    v_no_wa := '0' || v_no_wa;
  END IF;

  IF length(v_no_wa) < 9 THEN
    RAISE EXCEPTION 'Nomor WA tidak valid.';
  END IF;

  IF p_password_baru IS NULL OR length(p_password_baru) < 8 THEN
    RAISE EXCEPTION 'Password baru terlalu lemah. Gunakan minimal 8 karakter.';
  END IF;

  SELECT *
  INTO v_profile
  FROM public.users
  WHERE lower(email) = v_email
  LIMIT 1;

  IF v_profile.id IS NULL THEN
    RAISE EXCEPTION 'Email tidak ditemukan atau belum terdaftar.';
  END IF;

  v_stored_phone := regexp_replace(
    coalesce(v_profile.phone, v_profile.no_wa, ''),
    '\D',
    '',
    'g'
  );

  IF v_stored_phone LIKE '62%' THEN
    v_stored_phone := '0' || substring(v_stored_phone from 3);
  ELSIF v_stored_phone LIKE '8%' THEN
    v_stored_phone := '0' || v_stored_phone;
  END IF;

  IF v_stored_phone = '' OR v_stored_phone <> v_no_wa THEN
    RAISE EXCEPTION 'Nomor WA tidak cocok dengan akun tersebut.';
  END IF;

  UPDATE auth.users
  SET
    encrypted_password = extensions.crypt(
      p_password_baru,
      extensions.gen_salt('bf')
    ),
    updated_at = now()
  WHERE id = v_profile.id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Akun auth tidak ditemukan.';
  END IF;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth, extensions;

GRANT EXECUTE ON FUNCTION public.reset_password_dengan_wa(text, text, text)
TO anon, authenticated;

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

-- E. KEBIJAKAN AKSES PADA TABEL 'rental_settings'
ALTER TABLE public.rental_settings
  ADD COLUMN IF NOT EXISTS jam_operasional jsonb;

DROP POLICY IF EXISTS "Owners can manage own rental settings" ON public.rental_settings;
CREATE POLICY "Owners can manage own rental settings" ON public.rental_settings
    FOR ALL TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.rental_profiles rp
            WHERE rp.id = rental_id AND rp.owner_id = auth.uid()
        )
    ) WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.rental_profiles rp
            WHERE rp.id = rental_id AND rp.owner_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Allow public read-only access to rental settings" ON public.rental_settings;
CREATE POLICY "Allow public read-only access to rental settings" ON public.rental_settings
    FOR SELECT TO anon, authenticated USING (
        EXISTS (
            SELECT 1 FROM public.rental_profiles rp
            WHERE rp.id = rental_id AND rp.is_active = true
        )
    );


-- F. KEBIJAKAN AKSES PADA TABEL 'bookings'
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

-- 4. Izin UPDATE untuk pemilik rental memproses pesanan mereka sendiri
DROP POLICY IF EXISTS "Owners can update bookings for their rentals" ON public.bookings;
CREATE POLICY "Owners can update bookings for their rentals" ON public.bookings
    FOR UPDATE TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.rental_profiles rp
            WHERE rp.id = rental_id AND rp.owner_id = auth.uid()
        )
    ) WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.rental_profiles rp
            WHERE rp.id = rental_id AND rp.owner_id = auth.uid()
        )
    );

-- G. KEBIJAKAN AKSES PADA TABEL 'commission_settings'
-- 1. Akses CRUD penuh untuk Admin
DROP POLICY IF EXISTS "Admin full access on commission_settings" ON public.commission_settings;
CREATE POLICY "Admin full access on commission_settings" ON public.commission_settings
    FOR ALL TO authenticated USING (public.is_admin() = true) WITH CHECK (public.is_admin() = true);

-- 2. Izin SELECT untuk semua pengguna terautentikasi (agar database trigger bisa membaca tarif komisi saat checkout)
DROP POLICY IF EXISTS "Allow select for all authenticated users on commission_settings" ON public.commission_settings;
CREATE POLICY "Allow select for all authenticated users on commission_settings" ON public.commission_settings
    FOR SELECT TO authenticated USING (true);

-- H. KEBIJAKAN AKSES PADA TABEL 'deliveries'
-- 1. Akses CRUD penuh untuk Admin
DROP POLICY IF EXISTS "Admin full access on deliveries" ON public.deliveries;
CREATE POLICY "Admin full access on deliveries" ON public.deliveries
    FOR ALL TO authenticated USING (public.is_admin() = true) WITH CHECK (public.is_admin() = true);

-- 2. Izin SELECT untuk semua pengguna terautentikasi (agar pemilik rental/pelanggan bisa melihat status pengiriman)
DROP POLICY IF EXISTS "Allow select for all authenticated users on deliveries" ON public.deliveries;
CREATE POLICY "Allow select for all authenticated users on deliveries" ON public.deliveries
    FOR SELECT TO authenticated USING (true);

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

-- ----------------------------------------------------------------------------
-- BAGIAN 4: HAK AKSES & KEBIJAKAN KEAMANAN TABEL WISATA_LOCATIONS
-- ----------------------------------------------------------------------------
-- A. Berikan hak akses CRUD penuh ke tabel wisata_locations
GRANT ALL PRIVILEGES ON TABLE public.wisata_locations TO anon, authenticated, service_role;

-- B. Aktifkan Row Level Security (RLS) pada tabel wisata_locations
ALTER TABLE public.wisata_locations ENABLE ROW LEVEL SECURITY;

-- C. Buat Kebijakan Akses Keamanan (RLS Policies)
-- 1. Izin SELECT untuk semua orang (publik/anon & terautentikasi) agar destinasi tampil di peta/aplikasi
DROP POLICY IF EXISTS "Allow public read access to wisata_locations" ON public.wisata_locations;
CREATE POLICY "Allow public read access to wisata_locations"
ON public.wisata_locations
FOR SELECT
TO anon, authenticated
USING (true);

-- 2. Izin INSERT untuk pengguna terautentikasi (admin/owner) agar bisa menambah destinasi
DROP POLICY IF EXISTS "Allow authenticated insert access to wisata_locations" ON public.wisata_locations;
CREATE POLICY "Allow authenticated insert access to wisata_locations"
ON public.wisata_locations
FOR INSERT
TO authenticated
WITH CHECK (true);

-- 3. Izin UPDATE untuk pengguna terautentikasi (admin/owner) agar bisa mengedit destinasi
DROP POLICY IF EXISTS "Allow authenticated update access to wisata_locations" ON public.wisata_locations;
CREATE POLICY "Allow authenticated update access to wisata_locations"
ON public.wisata_locations
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- 4. Izin DELETE untuk pengguna terautentikasi (admin/owner) agar bisa menghapus destinasi
DROP POLICY IF EXISTS "Allow authenticated delete access to wisata_locations" ON public.wisata_locations;
CREATE POLICY "Allow authenticated delete access to wisata_locations"
ON public.wisata_locations
FOR DELETE
TO authenticated
USING (true);

-- ============================================================================
-- AKHIR DARI SCRIPT
-- ============================================================================
