-- 20260308000000_fix_auth_role_syntax.sql
-- Drop any potentially malformed policies that might use auth.role() 
-- and re-create them with proper role extraction or uid checks.

-- Profiles
DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile." ON profiles;
DROP POLICY IF EXISTS "Users can update own profile." ON profiles;

CREATE POLICY "Public profiles are viewable by everyone." ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile." ON profiles
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = id);

CREATE POLICY "Users can update own profile." ON profiles
  FOR UPDATE USING ((SELECT auth.uid()) = id);

-- Families
DROP POLICY IF EXISTS "Users can view their family." ON families;
DROP POLICY IF EXISTS "Users can create a family." ON families;
DROP POLICY IF EXISTS "Users can update their family." ON families;

CREATE POLICY "Users can view their family." ON families
  FOR SELECT USING (
    id IN (SELECT family_id FROM profiles WHERE id = (SELECT auth.uid()))
  );

CREATE POLICY "Users can create a family." ON families
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = created_by);

CREATE POLICY "Users can update their family." ON families
  FOR UPDATE USING (
    id IN (SELECT family_id FROM profiles WHERE id = (SELECT auth.uid()))
  );

-- Chat Messages
DROP POLICY IF EXISTS "Users can view their family's chat." ON chat_messages;
DROP POLICY IF EXISTS "Users can insert chat messages." ON chat_messages;

CREATE POLICY "Users can view their family's chat." ON chat_messages
  FOR SELECT USING (
    family_id IN (SELECT family_id FROM profiles WHERE id = (SELECT auth.uid()))
  );

CREATE POLICY "Users can insert chat messages." ON chat_messages
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = user_id);

-- Gift Contributions (Public to insert during MP flow, but usually done via Service Role)
-- Allow anyone to view gifts (if the page is public per family)
DROP POLICY IF EXISTS "Gift contributions viewable by public." ON gift_contributions;
CREATE POLICY "Gift contributions viewable by public." ON gift_contributions
  FOR SELECT USING (true);

-- Allow families to update the 'thanked' status
DROP POLICY IF EXISTS "Families can update their gift contributions." ON gift_contributions;
CREATE POLICY "Families can update their gift contributions." ON gift_contributions
  FOR UPDATE USING (
    family_id IN (SELECT family_id FROM profiles WHERE id = (SELECT auth.uid()))
  );
