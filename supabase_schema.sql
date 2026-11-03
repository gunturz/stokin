-- ==============================================================================
-- SCHEMA DATABASE SUPABASE UNTUK STOKIN PWA
-- ==============================================================================
-- Jalankan skrip ini di: Supabase Dashboard -> SQL Editor -> New Query -> Run
-- ==============================================================================

-- 1. Buat Tabel Kategori (categories)
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Buat Tabel Barang (items)
CREATE TABLE IF NOT EXISTS public.items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    cat TEXT NOT NULL,
    qty INTEGER NOT NULL DEFAULT 0 CHECK (qty >= 0),
    unit TEXT NOT NULL DEFAULT 'pcs',
    min INTEGER NOT NULL DEFAULT 0 CHECK (min >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_item_name_per_cat UNIQUE (name, cat)
);

-- 3. Trigger otomatis update timestamp 'updated_at' saat barang diedit
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_items_updated_at ON public.items;
CREATE TRIGGER trigger_items_updated_at
    BEFORE UPDATE ON public.items
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- 4. Konfigurasi Row Level Security (RLS)
-- Mengizinkan akses publik/anonim untuk membaca dan mengelola data
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.items ENABLE ROW LEVEL SECURITY;

-- Kebijakan untuk categories
DROP POLICY IF EXISTS "Akses penuh categories untuk publik" ON public.categories;
CREATE POLICY "Akses penuh categories untuk publik"
    ON public.categories
    FOR ALL
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

-- Kebijakan untuk items
DROP POLICY IF EXISTS "Akses penuh items untuk publik" ON public.items;
CREATE POLICY "Akses penuh items untuk publik"
    ON public.items
    FOR ALL
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

-- 5. Aktifkan Realtime (Perubahan langsung sinkron di Android & iPhone tanpa refresh)
ALTER PUBLICATION supabase_realtime ADD TABLE public.categories;
ALTER PUBLICATION supabase_realtime ADD TABLE public.items;

-- 6. Masukkan Data Awal (Seed Data) jika tabel masih kosong
INSERT INTO public.categories (name)
VALUES 
    ('Sembako'),
    ('Minuman'),
    ('Alat Tulis'),
    ('Snack')
ON CONFLICT (name) DO NOTHING;

INSERT INTO public.items (name, cat, qty, unit, min)
VALUES 
    ('Beras 5 kg', 'Sembako', 12, 'pak', 5),
    ('Minyak Goreng 1 L', 'Sembako', 30, 'pcs', 10),
    ('Air Mineral 600 ml', 'Minuman', 4, 'dus', 5),
    ('Buku Tulis 38 lembar', 'Alat Tulis', 48, 'pcs', 20),
    ('Biskuit Cokelat', 'Snack', 2, 'bungkus', 10)
ON CONFLICT (name, cat) DO NOTHING;

