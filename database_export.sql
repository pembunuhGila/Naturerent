-- ============================================================
-- NatureRent - Full Database Export
-- Generated: 2026-05-26 06:41:09
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;

-- ============================================================
-- ENUMS
-- ============================================================
CREATE TYPE public.audit_action AS ENUM ('INSERT', 'UPDATE', 'DELETE');
CREATE TYPE public.booking_status AS ENUM ('pending', 'confirmed', 'processing', 'rented', 'returned', 'completed', 'cancelled');
CREATE TYPE public.confirmation_action AS ENUM ('confirmed', 'rejected');
CREATE TYPE public.delivery_status AS ENUM ('waiting', 'scheduled', 'on_the_way', 'delivered', 'returning', 'returned');
CREATE TYPE public.delivery_type AS ENUM ('self_pickup', 'delivery');
CREATE TYPE public.notif_type AS ENUM ('booking', 'payment', 'return', 'system', 'delivery');
CREATE TYPE public.payment_status AS ENUM ('pending', 'success', 'failed', 'expired', 'waiting_dp_proof', 'dp_under_review', 'dp_confirmed', 'remaining_unpaid', 'paid');
CREATE TYPE public.user_role AS ENUM ('customer', 'rental_owner', 'admin');

-- ============================================================
-- TABLES
-- ============================================================
-- Table: audit_logs
CREATE TABLE IF NOT EXISTS public.audit_logs (id uuid NOT NULL DEFAULT uuid_generate_v4(),
  table_name text NOT NULL,
  record_id uuid NOT NULL,
  action public.audit_action NOT NULL,
  old_data jsonb,
  new_data jsonb,
  changed_by uuid,
  changed_at TIMESTAMPTZ DEFAULT now()
);

-- Table: booking_confirmations
CREATE TABLE IF NOT EXISTS public.booking_confirmations (id uuid NOT NULL DEFAULT uuid_generate_v4(),
  booking_id uuid NOT NULL,
  owner_id uuid NOT NULL,
  action public.confirmation_action NOT NULL,
  alasan text,
  confirmed_at TIMESTAMPTZ DEFAULT now()
);

-- Table: booking_items
CREATE TABLE IF NOT EXISTS public.booking_items (id uuid NOT NULL DEFAULT uuid_generate_v4(),
  booking_id uuid NOT NULL,
  equipment_id uuid NOT NULL,
  jumlah integer NOT NULL DEFAULT 1,
  harga_per_hari numeric NOT NULL,
  total_harga numeric NOT NULL,
  rental_id uuid,
  nama_equipment text,
  nama_rental text
);

-- Table: bookings
CREATE TABLE IF NOT EXISTS public.bookings (id uuid NOT NULL DEFAULT uuid_generate_v4(),
  customer_id uuid NOT NULL,
  rental_id uuid NOT NULL,
  tgl_mulai date NOT NULL,
  tgl_selesai date NOT NULL,
  total_hari integer,
  subtotal numeric NOT NULL DEFAULT 0,
  tax_rate numeric NOT NULL DEFAULT 11,
  tax_amount numeric NOT NULL DEFAULT 0,
  total_bayar numeric NOT NULL DEFAULT 0,
  commission_amount numeric DEFAULT 0,
  net_to_owner numeric DEFAULT 0,
  tipe_pengiriman public.delivery_type NOT NULL DEFAULT 'self_pickup'::delivery_type,
  biaya_kirim numeric NOT NULL DEFAULT 0,
  status public.booking_status DEFAULT 'pending'::booking_status,
  catatan text,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  booking_code text,
  payment_group_id uuid DEFAULT uuid_generate_v4(),
  biaya_layanan numeric NOT NULL DEFAULT 0,
  dp_percent numeric NOT NULL DEFAULT 30,
  dp_amount numeric NOT NULL DEFAULT 0,
  sisa_bayar numeric NOT NULL DEFAULT 0,
  payment_method text NOT NULL DEFAULT 'qris'::text,
  payment_status public.payment_status NOT NULL DEFAULT 'waiting_dp_proof'::payment_status,
  payment_proof_url text,
  admin_notes text,
  owner_notes text,
  confirmed_by_admin_at TIMESTAMPTZ,
  confirmed_by_owner_at TIMESTAMPTZ,
  processed_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ
);

-- Table: commission_settings
CREATE TABLE IF NOT EXISTS public.commission_settings (id uuid NOT NULL DEFAULT uuid_generate_v4(),
  percentage numeric NOT NULL DEFAULT 10.00,
  updated_by uuid,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table: deliveries
CREATE TABLE IF NOT EXISTS public.deliveries (id uuid NOT NULL DEFAULT uuid_generate_v4(),
  booking_id uuid NOT NULL,
  nama_kurir text,
  alamat_kirim text NOT NULL,
  delivery_lat numeric,
  delivery_lng numeric,
  status public.delivery_status NOT NULL DEFAULT 'waiting'::delivery_status,
  scheduled_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  returned_at TIMESTAMPTZ,
  catatan text,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table: equipment
CREATE TABLE IF NOT EXISTS public.equipment (id uuid NOT NULL DEFAULT uuid_generate_v4(),
  rental_id uuid NOT NULL,
  category_id uuid,
  nama text NOT NULL,
  deskripsi text,
  harga_per_hari numeric NOT NULL,
  stock integer NOT NULL DEFAULT 0,
  image_url text,
  is_available boolean DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table: equipment_availability
CREATE TABLE IF NOT EXISTS public.equipment_availability (id uuid NOT NULL DEFAULT uuid_generate_v4(),
  equipment_id uuid NOT NULL,
  booking_id uuid NOT NULL,
  tgl_mulai date NOT NULL,
  tgl_selesai date NOT NULL,
  jumlah integer NOT NULL DEFAULT 1
);

-- Table: equipment_categories
CREATE TABLE IF NOT EXISTS public.equipment_categories (id uuid NOT NULL DEFAULT uuid_generate_v4(),
  nama text NOT NULL,
  icon text,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Table: equipment_images
CREATE TABLE IF NOT EXISTS public.equipment_images (id uuid NOT NULL DEFAULT uuid_generate_v4(),
  equipment_id uuid NOT NULL,
  image_url text NOT NULL,
  is_primary boolean DEFAULT false,
  sort_order integer DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Table: notifications
CREATE TABLE IF NOT EXISTS public.notifications (id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  judul text NOT NULL,
  pesan text NOT NULL,
  type public.notif_type DEFAULT 'system'::notif_type,
  ref_id uuid,
  is_read boolean DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Table: partner_revenue_reports
CREATE TABLE IF NOT EXISTS public.partner_revenue_reports (id uuid NOT NULL DEFAULT uuid_generate_v4(),
  rental_id uuid NOT NULL,
  period_year smallint NOT NULL,
  period_month smallint NOT NULL,
  total_booking integer NOT NULL DEFAULT 0,
  gross_revenue numeric NOT NULL DEFAULT 0,
  total_komisi numeric NOT NULL DEFAULT 0,
  net_revenue numeric NOT NULL DEFAULT 0,
  generated_at TIMESTAMPTZ DEFAULT now()
);

-- Table: payments
CREATE TABLE IF NOT EXISTS public.payments (id uuid NOT NULL DEFAULT uuid_generate_v4(),
  booking_id uuid NOT NULL,
  jumlah_bayar numeric NOT NULL,
  status public.payment_status DEFAULT 'pending'::payment_status,
  qris_code_url text,
  tgl_bayar TIMESTAMPTZ,
  expired_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Table: platform_settings
CREATE TABLE IF NOT EXISTS public.platform_settings (id integer NOT NULL DEFAULT 1,
  biaya_layanan integer NOT NULL DEFAULT 2000,
  qris_image_url text,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table: rental_favorites
CREATE TABLE IF NOT EXISTS public.rental_favorites (id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL,
  rental_id uuid NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Table: rental_profiles
CREATE TABLE IF NOT EXISTS public.rental_profiles (id uuid NOT NULL DEFAULT uuid_generate_v4(),
  owner_id uuid NOT NULL,
  nama_rental text NOT NULL,
  deskripsi text,
  alamat text,
  geom public.geometry,
  no_wa text,
  foto_banner text,
  is_active boolean DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  lat FLOAT8,
  lng FLOAT8,
  foto_profil text,
  qris_image_url text,
  qris_merchant_name text
);

-- Table: rental_settings
CREATE TABLE IF NOT EXISTS public.rental_settings (id uuid NOT NULL DEFAULT uuid_generate_v4(),
  rental_id uuid NOT NULL,
  jam_operasional jsonb,
  max_delivery_radius_km numeric DEFAULT 10,
  delivery_fee_per_km numeric DEFAULT 0,
  min_rental_days integer DEFAULT 1,
  requires_deposit boolean DEFAULT false,
  deposit_amount numeric DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Table: rental_wisata
CREATE TABLE IF NOT EXISTS public.rental_wisata (id uuid NOT NULL DEFAULT uuid_generate_v4(),
  rental_id uuid NOT NULL,
  wisata_id uuid NOT NULL
);

-- Table: users
CREATE TABLE IF NOT EXISTS public.users (id uuid NOT NULL,
  email text NOT NULL,
  nama_lengkap text NOT NULL,
  no_wa text,
  role public.user_role NOT NULL DEFAULT 'customer'::user_role,
  avatar_url text,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  ktp_url text
);

-- Table: wisata_locations
CREATE TABLE IF NOT EXISTS public.wisata_locations (id uuid NOT NULL DEFAULT uuid_generate_v4(),
  nama text NOT NULL,
  deskripsi text,
  geom public.geometry,
  created_at TIMESTAMPTZ DEFAULT now(),
  foto_url text,
  kategori text DEFAULT 'Gunung'::text,
  lat FLOAT8,
  lng FLOAT8
);



-- ============================================================
-- FUNCTIONS
-- ============================================================
CREATE OR REPLACE FUNCTION public.calculate_booking_totals()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare
    comm_pct numeric;
begin
    new.tax_amount := round(new.subtotal * new.tax_rate / 100, 2);

    new.total_bayar :=
        new.subtotal
        + new.tax_amount
        + new.biaya_layanan
        + new.biaya_kirim;

    new.dp_amount := round(new.subtotal * new.dp_percent / 100, 2);
    new.sisa_bayar := new.total_bayar - new.dp_amount;

    select percentage into comm_pct
    from commission_settings
    order by updated_at desc
    limit 1;

    new.commission_amount := round(new.subtotal * coalesce(comm_pct, 0) / 100, 2);
    new.net_to_owner := new.subtotal - new.commission_amount;

    return new;
end;
$function$


CREATE OR REPLACE FUNCTION public.check_equipment_stock()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    total_stock   INTEGER;
    booked_qty    INTEGER;
    booking_start DATE;
    booking_end   DATE;
BEGIN
    SELECT tgl_mulai, tgl_selesai INTO booking_start, booking_end
    FROM bookings WHERE id = NEW.booking_id;

    SELECT stock INTO total_stock
    FROM equipment WHERE id = NEW.equipment_id;

    SELECT COALESCE(SUM(ea.jumlah), 0) INTO booked_qty
    FROM equipment_availability ea
    JOIN bookings b ON b.id = ea.booking_id
    WHERE ea.equipment_id = NEW.equipment_id
      AND ea.booking_id  <> NEW.booking_id
      AND b.status NOT IN ('cancelled')
      AND ea.tgl_mulai   < booking_end
      AND ea.tgl_selesai > booking_start;

    IF NEW.jumlah > (total_stock - booked_qty) THEN
        RAISE EXCEPTION 'Stok tidak cukup. Tersedia: %, diminta: %',
            (total_stock - booked_qty), NEW.jumlah;
    END IF;

    RETURN NEW;
END;
$function$


CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$ BEGIN INSERT INTO public.users (id, email, nama_lengkap, no_wa, role, created_at, updated_at) VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)), COALESCE(NEW.raw_user_meta_data->>'no_wa', ''), COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'customer'::user_role), NOW(), NOW()) ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email, nama_lengkap = EXCLUDED.nama_lengkap, updated_at = NOW(); RETURN NEW; END; $function$


CREATE OR REPLACE FUNCTION public.record_audit_log()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO audit_logs (table_name, record_id, action, old_data, new_data, changed_by)
    VALUES (
        TG_TABLE_NAME,
        CASE TG_OP WHEN 'DELETE' THEN OLD.id ELSE NEW.id END,
        TG_OP::audit_action,
        CASE TG_OP WHEN 'INSERT' THEN NULL ELSE to_jsonb(OLD) END,
        CASE TG_OP WHEN 'DELETE' THEN NULL ELSE to_jsonb(NEW) END,
        CASE WHEN EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid()) THEN auth.uid() ELSE NULL END
    );
    RETURN COALESCE(NEW, OLD);
END;
$function$


CREATE OR REPLACE FUNCTION public.record_equipment_availability()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    booking_start DATE;
    booking_end   DATE;
BEGIN
    SELECT tgl_mulai, tgl_selesai INTO booking_start, booking_end
    FROM bookings WHERE id = NEW.booking_id;

    INSERT INTO equipment_availability (equipment_id, booking_id, tgl_mulai, tgl_selesai, jumlah)
    VALUES (NEW.equipment_id, NEW.booking_id, booking_start, booking_end, NEW.jumlah)
    ON CONFLICT (equipment_id, booking_id)
    DO UPDATE SET jumlah      = EXCLUDED.jumlah,
                  tgl_mulai   = EXCLUDED.tgl_mulai,
                  tgl_selesai = EXCLUDED.tgl_selesai;

    RETURN NEW;
END;
$function$


CREATE OR REPLACE FUNCTION public.release_equipment_availability()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.status = 'cancelled' AND OLD.status <> 'cancelled' THEN
        DELETE FROM equipment_availability WHERE booking_id = NEW.id;
    END IF;
    RETURN NEW;
END;
$function$


CREATE OR REPLACE FUNCTION public.sync_booking_on_payment()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.status = 'success' AND OLD.status <> 'success' THEN
        UPDATE payments SET tgl_bayar = NOW() WHERE id = NEW.id;
        UPDATE bookings SET status = 'processing', updated_at = NOW() WHERE id = NEW.booking_id;

        INSERT INTO notifications (user_id, judul, pesan, type, ref_id)
        SELECT b.customer_id,
               'Pembayaran Berhasil â',
               'Pembayaran QRIS kamu berhasil. Pesanan sedang diproses.',
               'payment', NEW.booking_id
        FROM bookings b WHERE b.id = NEW.booking_id;
    END IF;

    RETURN NEW;
END;
$function$


CREATE OR REPLACE FUNCTION public.sync_booking_status_on_confirmation()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.action = 'confirmed' THEN
        UPDATE bookings SET status = 'confirmed', updated_at = NOW()
        WHERE id = NEW.booking_id;

        INSERT INTO notifications (user_id, judul, pesan, type, ref_id)
        SELECT b.customer_id,
               'Booking Dikonfirmasi â',
               'Rental telah mengkonfirmasi pesanan kamu. Silakan lakukan pembayaran.',
               'booking', NEW.booking_id
        FROM bookings b WHERE b.id = NEW.booking_id;

    ELSIF NEW.action = 'rejected' THEN
        UPDATE bookings SET status = 'cancelled', updated_at = NOW()
        WHERE id = NEW.booking_id;

        INSERT INTO notifications (user_id, judul, pesan, type, ref_id)
        SELECT b.customer_id,
               'Booking Ditolak',
               COALESCE('Pesanan kamu ditolak rental. Alasan: ' || NEW.alasan,
                        'Pesanan kamu ditolak oleh rental.'),
               'booking', NEW.booking_id
        FROM bookings b WHERE b.id = NEW.booking_id;
    END IF;

    RETURN NEW;
END;
$function$


CREATE OR REPLACE FUNCTION public.sync_booking_status_on_delivery()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.status = 'delivered' AND OLD.status <> 'delivered' THEN
        UPDATE deliveries SET delivered_at = NOW() WHERE id = NEW.id;
        UPDATE bookings  SET status = 'rented', updated_at = NOW() WHERE id = NEW.booking_id;

        INSERT INTO notifications (user_id, judul, pesan, type, ref_id)
        SELECT b.customer_id,
               'Alat Sudah Diantar ð¦',
               'Kurir sedang mengantar alat camping kamu. Selamat mendaki!',
               'delivery', NEW.booking_id
        FROM bookings b WHERE b.id = NEW.booking_id;

    ELSIF NEW.status = 'returned' AND OLD.status <> 'returned' THEN
        UPDATE deliveries SET returned_at = NOW() WHERE id = NEW.id;
        UPDATE bookings  SET status = 'completed', updated_at = NOW() WHERE id = NEW.booking_id;

        INSERT INTO notifications (user_id, judul, pesan, type, ref_id)
        SELECT b.customer_id,
               'Pengembalian Selesai â',
               'Alat sudah diterima kembali oleh rental. Terima kasih!',
               'delivery', NEW.booking_id
        FROM bookings b WHERE b.id = NEW.booking_id;
    END IF;

    RETURN NEW;
END;
$function$


-- ============================================================
-- TRIGGERS
-- ============================================================
CREATE OR REPLACE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE TRIGGER trg_booking_totals BEFORE INSERT OR UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.calculate_booking_totals();
CREATE OR REPLACE TRIGGER trg_check_equipment_stock BEFORE INSERT ON public.booking_items FOR EACH ROW EXECUTE FUNCTION public.check_equipment_stock();
CREATE OR REPLACE TRIGGER trg_record_availability AFTER INSERT OR UPDATE ON public.booking_items FOR EACH ROW EXECUTE FUNCTION public.record_equipment_availability();
CREATE OR REPLACE TRIGGER trg_release_availability AFTER UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.release_equipment_availability();
CREATE OR REPLACE TRIGGER trg_booking_confirmation AFTER INSERT ON public.booking_confirmations FOR EACH ROW EXECUTE FUNCTION public.sync_booking_status_on_confirmation();
CREATE OR REPLACE TRIGGER trg_payment_success AFTER UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.sync_booking_on_payment();
CREATE OR REPLACE TRIGGER trg_delivery_status AFTER UPDATE ON public.deliveries FOR EACH ROW EXECUTE FUNCTION public.sync_booking_status_on_delivery();
CREATE OR REPLACE TRIGGER audit_bookings AFTER INSERT OR UPDATE OR DELETE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.record_audit_log();
CREATE OR REPLACE TRIGGER audit_payments AFTER INSERT OR UPDATE OR DELETE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.record_audit_log();
CREATE OR REPLACE TRIGGER audit_deliveries AFTER INSERT OR UPDATE OR DELETE ON public.deliveries FOR EACH ROW EXECUTE FUNCTION public.record_audit_log();
CREATE OR REPLACE TRIGGER audit_booking_confirmations AFTER INSERT OR UPDATE OR DELETE ON public.booking_confirmations FOR EACH ROW EXECUTE FUNCTION public.record_audit_log();
-- ============================================================
-- FOREIGN KEYS
-- ============================================================
ALTER TABLE public.audit_logs ADD CONSTRAINT audit_logs_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.booking_confirmations ADD CONSTRAINT booking_confirmations_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;
ALTER TABLE public.booking_confirmations ADD CONSTRAINT booking_confirmations_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.booking_items ADD CONSTRAINT booking_items_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;
ALTER TABLE public.booking_items ADD CONSTRAINT booking_items_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipment(id) ON DELETE CASCADE;
ALTER TABLE public.booking_items ADD CONSTRAINT booking_items_rental_id_fkey FOREIGN KEY (rental_id) REFERENCES public.rental_profiles(id) ON DELETE CASCADE;
ALTER TABLE public.bookings ADD CONSTRAINT bookings_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.bookings ADD CONSTRAINT bookings_rental_id_fkey FOREIGN KEY (rental_id) REFERENCES public.rental_profiles(id) ON DELETE CASCADE;
ALTER TABLE public.commission_settings ADD CONSTRAINT commission_settings_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.deliveries ADD CONSTRAINT deliveries_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;
ALTER TABLE public.equipment ADD CONSTRAINT equipment_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.equipment_categories(id) ON DELETE CASCADE;
ALTER TABLE public.equipment ADD CONSTRAINT equipment_rental_id_fkey FOREIGN KEY (rental_id) REFERENCES public.rental_profiles(id) ON DELETE CASCADE;
ALTER TABLE public.equipment_availability ADD CONSTRAINT equipment_availability_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;
ALTER TABLE public.equipment_availability ADD CONSTRAINT equipment_availability_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipment(id) ON DELETE CASCADE;
ALTER TABLE public.equipment_images ADD CONSTRAINT equipment_images_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipment(id) ON DELETE CASCADE;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.partner_revenue_reports ADD CONSTRAINT partner_revenue_reports_rental_id_fkey FOREIGN KEY (rental_id) REFERENCES public.rental_profiles(id) ON DELETE CASCADE;
ALTER TABLE public.payments ADD CONSTRAINT payments_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;
ALTER TABLE public.rental_favorites ADD CONSTRAINT rental_favorites_rental_id_fkey FOREIGN KEY (rental_id) REFERENCES public.rental_profiles(id) ON DELETE CASCADE;
ALTER TABLE public.rental_favorites ADD CONSTRAINT rental_favorites_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.rental_profiles ADD CONSTRAINT rental_profiles_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(id) ON DELETE CASCADE;
ALTER TABLE public.rental_settings ADD CONSTRAINT rental_settings_rental_id_fkey FOREIGN KEY (rental_id) REFERENCES public.rental_profiles(id) ON DELETE CASCADE;
ALTER TABLE public.rental_wisata ADD CONSTRAINT rental_wisata_rental_id_fkey FOREIGN KEY (rental_id) REFERENCES public.rental_profiles(id) ON DELETE CASCADE;
ALTER TABLE public.rental_wisata ADD CONSTRAINT rental_wisata_wisata_id_fkey FOREIGN KEY (wisata_id) REFERENCES public.wisata_locations(id) ON DELETE CASCADE;

-- ============================================================
-- PRIMARY KEYS
-- ============================================================
ALTER TABLE public.audit_logs ADD PRIMARY KEY (id);
ALTER TABLE public.booking_confirmations ADD PRIMARY KEY (id);
ALTER TABLE public.booking_items ADD PRIMARY KEY (id);
ALTER TABLE public.bookings ADD PRIMARY KEY (id);
ALTER TABLE public.commission_settings ADD PRIMARY KEY (id);
ALTER TABLE public.deliveries ADD PRIMARY KEY (id);
ALTER TABLE public.equipment ADD PRIMARY KEY (id);
ALTER TABLE public.equipment_availability ADD PRIMARY KEY (id);
ALTER TABLE public.equipment_categories ADD PRIMARY KEY (id);
ALTER TABLE public.equipment_images ADD PRIMARY KEY (id);
ALTER TABLE public.notifications ADD PRIMARY KEY (id);
ALTER TABLE public.partner_revenue_reports ADD PRIMARY KEY (id);
ALTER TABLE public.payments ADD PRIMARY KEY (id);
ALTER TABLE public.platform_settings ADD PRIMARY KEY (id);
ALTER TABLE public.rental_favorites ADD PRIMARY KEY (id);
ALTER TABLE public.rental_profiles ADD PRIMARY KEY (id);
ALTER TABLE public.rental_settings ADD PRIMARY KEY (id);
ALTER TABLE public.rental_wisata ADD PRIMARY KEY (id);
ALTER TABLE public.users ADD PRIMARY KEY (id);
ALTER TABLE public.wisata_locations ADD PRIMARY KEY (id);

-- ============================================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_confirmations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.commission_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipment_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipment_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.equipment_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partner_revenue_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rental_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rental_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rental_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rental_wisata ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wisata_locations ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- DEFAULT SEED DATA
-- ============================================================
INSERT INTO public.platform_settings (id, biaya_layanan, qris_image_url) VALUES (1, 2000, NULL) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.commission_settings (percentage) VALUES (10.00);
INSERT INTO public.equipment_categories (nama, icon) VALUES ('Tenda', 'tent'), ('Carrier', 'backpack'), ('Sleeping Bag', 'bed'), ('Matras', 'layers'), ('Kompor', 'local_fire_department'), ('Sepatu', 'hiking'), ('Jaket', 'jacket'), ('Lainnya', 'more_horiz') ON CONFLICT DO NOTHING;

-- ============================================================
-- KTP & QRIS STORAGE AND PROFILE POLICIES
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('ktp-docs', 'ktp-docs', true)
ON CONFLICT (id) DO UPDATE
SET public = true;

INSERT INTO storage.buckets (id, name, public)
VALUES ('qris-images', 'qris-images', true)
ON CONFLICT (id) DO UPDATE
SET public = true;

GRANT SELECT ON public.users TO authenticated;
GRANT UPDATE (nama_lengkap, no_wa, avatar_url, ktp_url, updated_at)
ON public.users TO authenticated;

DROP POLICY IF EXISTS "Users can read own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;

CREATE POLICY "Users can read own profile"
ON public.users
FOR SELECT
TO authenticated
USING (id = auth.uid());

CREATE POLICY "Users can update own profile"
ON public.users
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "Authenticated can upload ktp" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated can update ktp" ON storage.objects;
DROP POLICY IF EXISTS "Public can read ktp" ON storage.objects;

CREATE POLICY "Authenticated can upload ktp"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'ktp-docs');

CREATE POLICY "Authenticated can update ktp"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'ktp-docs')
WITH CHECK (bucket_id = 'ktp-docs');

CREATE POLICY "Public can read ktp"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'ktp-docs');

-- QRIS-images bucket policies
DROP POLICY IF EXISTS "Authenticated can upload qris images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated can update qris images" ON storage.objects;
DROP POLICY IF EXISTS "Public can read qris images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated can delete qris images" ON storage.objects;

CREATE POLICY "Authenticated can upload qris images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'qris-images');

CREATE POLICY "Authenticated can update qris images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'qris-images')
WITH CHECK (bucket_id = 'qris-images');

CREATE POLICY "Public can read qris images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'qris-images');

CREATE POLICY "Authenticated can delete qris images"
ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'qris-images');

-- ============================================================
-- WISATA_LOCATIONS GRANTS AND RLS POLICIES
-- ============================================================
-- Grant privileges
GRANT ALL PRIVILEGES ON TABLE public.wisata_locations TO anon, authenticated, service_role;

-- Enable RLS
ALTER TABLE public.wisata_locations ENABLE ROW LEVEL SECURITY;

-- 1. Kebijakan SELECT (Semua orang dapat membaca wisata_locations)
DROP POLICY IF EXISTS "Allow public read access to wisata_locations" ON public.wisata_locations;
CREATE POLICY "Allow public read access to wisata_locations"
ON public.wisata_locations
FOR SELECT
TO anon, authenticated
USING (true);

-- 2. Kebijakan INSERT (Pengguna terautentikasi dapat menambah data)
DROP POLICY IF EXISTS "Allow authenticated insert access to wisata_locations" ON public.wisata_locations;
CREATE POLICY "Allow authenticated insert access to wisata_locations"
ON public.wisata_locations
FOR INSERT
TO authenticated
WITH CHECK (true);

-- 3. Kebijakan UPDATE (Pengguna terautentikasi dapat mengedit data)
DROP POLICY IF EXISTS "Allow authenticated update access to wisata_locations" ON public.wisata_locations;
CREATE POLICY "Allow authenticated update access to wisata_locations"
ON public.wisata_locations
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- 4. Kebijakan DELETE (Pengguna terautentikasi dapat menghapus data)
DROP POLICY IF EXISTS "Allow authenticated delete access to wisata_locations" ON public.wisata_locations;
CREATE POLICY "Allow authenticated delete access to wisata_locations"
ON public.wisata_locations
FOR DELETE
TO authenticated
USING (true);
