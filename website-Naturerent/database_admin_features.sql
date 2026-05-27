-- Policies pendukung fitur admin Flutter:
-- 1. Admin mengelola destinasi wisata di tabel wisata_locations.
-- 2. User membaca destinasi wisata dari tabel yang sama.
-- 3. Admin upload gambar destinasi ke bucket destinasi_wisata.

GRANT SELECT ON TABLE public.wisata_locations TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.wisata_locations TO authenticated;

ALTER TABLE public.wisata_locations ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.sync_wisata_geom_from_lat_lng()
RETURNS trigger AS $$
BEGIN
  IF NEW.lat IS NOT NULL AND NEW.lng IS NOT NULL THEN
    NEW.geom := ST_SetSRID(ST_MakePoint(NEW.lng, NEW.lat), 4326);
  ELSE
    NEW.geom := NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_wisata_geom_from_lat_lng ON public.wisata_locations;
CREATE TRIGGER trg_sync_wisata_geom_from_lat_lng
BEFORE INSERT OR UPDATE OF lat, lng
ON public.wisata_locations
FOR EACH ROW
EXECUTE FUNCTION public.sync_wisata_geom_from_lat_lng();

UPDATE public.wisata_locations
SET geom = ST_SetSRID(ST_MakePoint(lng, lat), 4326)
WHERE lat IS NOT NULL
  AND lng IS NOT NULL;

UPDATE public.wisata_locations
SET geom = NULL
WHERE lat IS NULL
   OR lng IS NULL;

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
DROP POLICY IF EXISTS "Authenticated can upload destination images" ON storage.objects;
CREATE POLICY "Authenticated can upload destination images"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'destinasi_wisata'
  AND auth.role() = 'authenticated'
);

DROP POLICY IF EXISTS "Admin can update destination images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated can update destination images" ON storage.objects;
CREATE POLICY "Authenticated can update destination images"
ON storage.objects
FOR UPDATE
USING (
  bucket_id = 'destinasi_wisata'
  AND auth.role() = 'authenticated'
)
WITH CHECK (
  bucket_id = 'destinasi_wisata'
  AND auth.role() = 'authenticated'
);

DROP POLICY IF EXISTS "Admin can delete destination images" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated can delete destination images" ON storage.objects;
CREATE POLICY "Authenticated can delete destination images"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'destinasi_wisata'
  AND auth.role() = 'authenticated'
);
