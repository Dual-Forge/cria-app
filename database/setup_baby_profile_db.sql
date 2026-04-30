-- Create baby_profile table with all required fields for the baby card refactor
-- This table stores baby-specific information including profile photo, BPM, kick count, and expected due date

CREATE TABLE IF NOT EXISTS public.baby_profile (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    family_id UUID NOT NULL REFERENCES public.families(id) ON DELETE CASCADE,
    
    -- Profile photo URL (nullable - fallback to icon if not provided)
    profile_photo_url TEXT,
    
    -- Frequência cardíaca (BPM) - nullable, updated periodically
    last_bpm INTEGER CHECK (last_bpm IS NULL OR (last_bpm >= 40 AND last_bpm <= 200)),
    
    -- Contador de chutes - default 0, incremented by user interaction
    kick_count INTEGER DEFAULT 0 CHECK (kick_count >= 0),
    
    -- Data prevista do parto (expected due date)
    expected_due_date DATE,
    
    -- Timestamps for audit trail
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure one baby_profile per family
    UNIQUE(family_id)
);

-- Create index for faster queries by family_id
CREATE INDEX IF NOT EXISTS idx_baby_profile_family_id ON public.baby_profile(family_id);

-- Create index for faster queries by expected_due_date (for zodiac calculations)
CREATE INDEX IF NOT EXISTS idx_baby_profile_expected_due_date ON public.baby_profile(expected_due_date);

-- Enable RLS (Row Level Security)
ALTER TABLE public.baby_profile ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can read baby_profile if they belong to the family
CREATE POLICY "Users can read baby_profile of their family"
    ON public.baby_profile
    FOR SELECT
    USING (
        family_id IN (
            SELECT family_id FROM public.profiles 
            WHERE id = auth.uid()
        )
    );

-- RLS Policy: Users can update baby_profile if they belong to the family
CREATE POLICY "Users can update baby_profile of their family"
    ON public.baby_profile
    FOR UPDATE
    USING (
        family_id IN (
            SELECT family_id FROM public.profiles 
            WHERE id = auth.uid()
        )
    );

-- RLS Policy: Users can insert baby_profile if they belong to the family
CREATE POLICY "Users can insert baby_profile for their family"
    ON public.baby_profile
    FOR INSERT
    WITH CHECK (
        family_id IN (
            SELECT family_id FROM public.profiles 
            WHERE id = auth.uid()
        )
    );

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_baby_profile_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_baby_profile_updated_at
    BEFORE UPDATE ON public.baby_profile
    FOR EACH ROW
    EXECUTE FUNCTION public.update_baby_profile_updated_at();
