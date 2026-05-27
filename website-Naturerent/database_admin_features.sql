-- Policies pendukung fitur admin Flutter:
-- 1. Admin mengelola destinasi wisata di tabel wisata_locations.
-- 2. User membaca destinasi wisata dari tabel yang sama.
-- 3. Admin upload gambar destinasi ke bucket destinasi_wisata.

GRANT SELECT ON TABLE public.wisata_locations TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.wisata_locations TO authenticated;

ALTER TABLE public.wisata_locations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can view wisata locations" ON public.wisata_locations;
CREATE POLICY "Public can view wisata locations"
ON public.wisata_locations
FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Admin can manage wisata locations" ON public.wisata_locations;
CREATE POLICY "Admin can manage wisata locations"
ON public.wisata_locations
FOR ALL
USING (
  EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = auth.uid()
      AND u.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = auth.uid()
      AND u.role = 'admin'
  )
);

INSERT INTO storage.buckets (id, name, public)
VALUES ('destinasi_wisata', 'destinasi_wisata', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Public can view destination images" ON storage.objects;
CREATE POLICY "Public can view destination images"
ON storage.objects
FOR SELECT
USING (bucket_id = 'destinasi_wisata');

DROP POLICY IF EXISTS "Admin can upload destination images" ON storage.objects;
CREATE POLICY "Admin can upload destination images"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'destinasi_wisata'
  AND EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = auth.uid()
      AND u.role = 'admin'
  )
);

DROP POLICY IF EXISTS "Admin can update destination images" ON storage.objects;
CREATE POLICY "Admin can update destination images"
ON storage.objects
FOR UPDATE
USING (
  bucket_id = 'destinasi_wisata'
  AND EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = auth.uid()
      AND u.role = 'admin'
  )
)
WITH CHECK (
  bucket_id = 'destinasi_wisata'
  AND EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = auth.uid()
      AND u.role = 'admin'
  )
);

DROP POLICY IF EXISTS "Admin can delete destination images" ON storage.objects;
CREATE POLICY "Admin can delete destination images"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'destinasi_wisata'
  AND EXISTS (
    SELECT 1
    FROM public.users u
    WHERE u.id = auth.uid()
      AND u.role = 'admin'
  )
);
