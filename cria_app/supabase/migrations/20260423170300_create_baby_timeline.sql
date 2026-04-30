-- Add baby_photo_url to families if it doesn't exist
ALTER TABLE families ADD COLUMN IF NOT EXISTS baby_photo_url TEXT;

-- Create baby_timeline table
CREATE TABLE IF NOT EXISTS baby_timeline (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  title TEXT NOT NULL,
  date DATE NOT NULL,
  description TEXT,
  age_text TEXT NOT NULL,
  is_profile_photo BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS Policies
ALTER TABLE baby_timeline ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Families can manage their own baby timeline"
ON baby_timeline
FOR ALL
USING (
  family_id IN (
    SELECT family_id FROM profiles WHERE id = auth.uid()
  )
)
WITH CHECK (
  family_id IN (
    SELECT family_id FROM profiles WHERE id = auth.uid()
  )
);
