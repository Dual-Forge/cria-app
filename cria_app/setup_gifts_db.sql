-- 1. Updates to items
ALTER TABLE public.items 
ADD COLUMN IF NOT EXISTS is_gift BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS gift_status TEXT DEFAULT 'available' CHECK (gift_status IN ('available', 'reserved', 'received'));

-- 2. Pix Key for families
ALTER TABLE public.families
ADD COLUMN IF NOT EXISTS pix_key TEXT;

-- 3. Create gift_contributions table
CREATE TABLE IF NOT EXISTS public.gift_contributions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    family_id UUID REFERENCES public.families(id) ON DELETE CASCADE,
    item_id UUID REFERENCES public.items(id) ON DELETE SET NULL,
    giver_name TEXT NOT NULL,
    giver_nickname TEXT,
    giver_phone TEXT,
    message_to_parents TEXT,
    thanked BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Enable RLS on gift_contributions
ALTER TABLE public.gift_contributions ENABLE ROW LEVEL SECURITY;

-- 5. Policies for gift_contributions
-- Allow anyone (public/anon) to insert a gift contribution
CREATE POLICY "Allow public insert on gift_contributions" 
ON public.gift_contributions 
FOR INSERT 
WITH CHECK (true);

-- Allow authenticated users to view gift contributions for their family
CREATE POLICY "Allow members to read gift_contributions" 
ON public.gift_contributions 
FOR SELECT 
USING (family_id IN (
    SELECT family_id FROM public.profiles WHERE id = auth.uid()
));

-- Allow members to update gift_contributions (e.g. mark as thanked)
CREATE POLICY "Allow members to update gift_contributions" 
ON public.gift_contributions 
FOR UPDATE 
USING (family_id IN (
    SELECT family_id FROM public.profiles WHERE id = auth.uid()
));

-- 6. Update Policies on items (Allow public SELECT for items marked as gifts)
-- This assumes you already have RLS on items. We'll add a policy for public read if is_gift is true.
CREATE POLICY "Allow public select for gifts" 
ON public.items 
FOR SELECT 
USING (is_gift = true);
