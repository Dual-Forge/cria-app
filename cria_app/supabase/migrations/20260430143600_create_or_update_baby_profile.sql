-- Cria/atualiza a tabela baby_profile com os campos usados pelo baby card.
-- Mantém comportamento idempotente para ambientes já provisionados.

CREATE TABLE IF NOT EXISTS public.baby_profile (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    profile_photo_url TEXT,
    last_bpm INTEGER CHECK (last_bpm IS NULL OR (last_bpm >= 40 AND last_bpm <= 200)),
    kick_count INTEGER DEFAULT 0 CHECK (kick_count >= 0),
    expected_due_date DATE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(family_id)
);

ALTER TABLE public.baby_profile
    ADD COLUMN IF NOT EXISTS profile_photo_url TEXT,
    ADD COLUMN IF NOT EXISTS last_bpm INTEGER,
    ADD COLUMN IF NOT EXISTS kick_count INTEGER DEFAULT 0,
    ADD COLUMN IF NOT EXISTS expected_due_date DATE,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

-- Garante constraints mesmo em tabelas já existentes.
ALTER TABLE public.baby_profile DROP CONSTRAINT IF EXISTS baby_profile_last_bpm_check;
ALTER TABLE public.baby_profile
    ADD CONSTRAINT baby_profile_last_bpm_check
    CHECK (last_bpm IS NULL OR (last_bpm >= 40 AND last_bpm <= 200));

ALTER TABLE public.baby_profile DROP CONSTRAINT IF EXISTS baby_profile_kick_count_check;
ALTER TABLE public.baby_profile
    ADD CONSTRAINT baby_profile_kick_count_check
    CHECK (kick_count >= 0);

ALTER TABLE public.baby_profile
    ALTER COLUMN kick_count SET DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_baby_profile_family_id
    ON public.baby_profile(family_id);
CREATE INDEX IF NOT EXISTS idx_baby_profile_expected_due_date
    ON public.baby_profile(expected_due_date);

ALTER TABLE public.baby_profile ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read baby_profile of their family" ON public.baby_profile;
CREATE POLICY "Users can read baby_profile of their family"
    ON public.baby_profile
    FOR SELECT
    USING (
        family_id IN (
            SELECT family_id FROM public.profiles WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update baby_profile of their family" ON public.baby_profile;
CREATE POLICY "Users can update baby_profile of their family"
    ON public.baby_profile
    FOR UPDATE
    USING (
        family_id IN (
            SELECT family_id FROM public.profiles WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can insert baby_profile for their family" ON public.baby_profile;
CREATE POLICY "Users can insert baby_profile for their family"
    ON public.baby_profile
    FOR INSERT
    WITH CHECK (
        family_id IN (
            SELECT family_id FROM public.profiles WHERE id = auth.uid()
        )
    );

CREATE OR REPLACE FUNCTION public.update_baby_profile_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_baby_profile_updated_at ON public.baby_profile;
CREATE TRIGGER trigger_baby_profile_updated_at
    BEFORE UPDATE ON public.baby_profile
    FOR EACH ROW
    EXECUTE FUNCTION public.update_baby_profile_updated_at();
