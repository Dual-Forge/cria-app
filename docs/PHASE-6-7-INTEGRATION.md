# Baby Card Refactor - Phase 6-7 Integration Summary

## Phase 6: HomeScreen Integration - COMPLETED ✅

### Task 6.1: Refactor lib/screens/home_screen.dart - COMPLETED ✅
- ✅ Removed `_babyMonthAssetPath()` function (line 104-107)
- ✅ Removed fixed baby image code from the old card
- ✅ Imported `BabyCardWidget` from `../widgets/baby_card/baby_card_widget.dart`
- ✅ Replaced old card with new `BabyCardWidget`

### Task 6.2: Update Stream builders to include new fields - COMPLETED ✅
- ✅ Added nested `StreamBuilder` for `baby_profile` table
- ✅ Fetches `profile_photo_url` field
- ✅ Fetches `last_bpm` field
- ✅ Fetches `kick_count` field
- ✅ Fetches `expected_due_date` field
- ✅ Properly handles null values with fallbacks

### Task 6.3: Pass correct data to BabyCardWidget - COMPLETED ✅
- ✅ `profilePhotoUrl` → `profile_photo_url` from baby_profile
- ✅ `lastBpm` → `last_bpm` from baby_profile
- ✅ `expectedDueDate` → `expected_due_date` from baby_profile
- ✅ `dumDate` → `actualDumDate` from profiles table
- ✅ `kickCount` → `kick_count` from baby_profile
- ✅ `babyName` → `widget.babyName`
- ✅ `familyId` → `widget.familyId`
- ✅ `themeColor` → `widget.themeColor`
- ✅ Error callbacks properly configured

### Task 6.4: Test integration with real Supabase data - PENDING
- Status: Requires manual testing with real Supabase data
- Prerequisites: Database schema must be created (Phase 7)

## Phase 7: Database - IN PROGRESS

### Task 7.1: Verify/create fields in baby_profile table - IN PROGRESS
Created migration file: `database/setup_baby_profile_db.sql`

**Required Fields:**
- `id` (UUID, PRIMARY KEY)
- `family_id` (UUID, FOREIGN KEY to families)
- `profile_photo_url` (TEXT, nullable)
- `last_bpm` (INTEGER, nullable, range 40-200)
- `kick_count` (INTEGER, default 0)
- `expected_due_date` (DATE)
- `created_at` (TIMESTAMP)
- `updated_at` (TIMESTAMP)

**Constraints:**
- UNIQUE constraint on family_id (one baby_profile per family)
- CHECK constraint on last_bpm (40-200 range)
- CHECK constraint on kick_count (>= 0)

**Indexes:**
- `idx_baby_profile_family_id` on family_id
- `idx_baby_profile_expected_due_date` on expected_due_date

### Task 7.2: Create migration if necessary - COMPLETED ✅
- ✅ Created `database/setup_baby_profile_db.sql`
- ✅ Includes table creation with all required fields
- ✅ Includes indexes for performance
- ✅ Includes RLS policies for security

### Task 7.3: Update RLS policies for read/write access - COMPLETED ✅
**Policies Created:**
1. `Users can read baby_profile of their family` - SELECT
2. `Users can update baby_profile of their family` - UPDATE
3. `Users can insert baby_profile for their family` - INSERT

**Policy Logic:**
- Users can only access baby_profile if they belong to the family
- Checks `family_id` against user's family in profiles table
- Prevents cross-family data access

### Task 7.4: Test data access via Supabase - PENDING
- Status: Requires manual testing after migration is applied
- Test cases:
  1. Insert new baby_profile record
  2. Read baby_profile data via StreamBuilder
  3. Update kick_count field
  4. Update last_bpm field
  5. Verify RLS policies prevent unauthorized access

## Implementation Details

### Code Changes Made

#### 1. home_screen.dart (Lines 369-890)
**Before:**
- Used `_babyMonthAssetPath()` to load AI-generated baby images
- Displayed fixed baby card with gradient background
- No integration with baby_profile table

**After:**
- Removed `_babyMonthAssetPath()` function
- Added nested StreamBuilder for baby_profile table
- Integrated BabyCardWidget with real data
- Maintains hero section and AI insights sections

#### 2. New StreamBuilder Structure
```dart
StreamBuilder<List<Map<String, dynamic>>>(
  stream: Supabase.instance.client
      .from('baby_profile')
      .stream(primaryKey: ['id'])
      .eq('family_id', widget.familyId!),
  builder: (context, babySnapshot) {
    // Extract fields from baby_profile
    // Pass to BabyCardWidget
  }
)
```

### Database Schema

**baby_profile Table:**
```sql
CREATE TABLE public.baby_profile (
    id UUID PRIMARY KEY,
    family_id UUID UNIQUE NOT NULL,
    profile_photo_url TEXT,
    last_bpm INTEGER (40-200),
    kick_count INTEGER (default 0),
    expected_due_date DATE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

## Next Steps

### Phase 8: Testing and Refinement
1. Run all unit tests
2. Run all widget tests
3. End-to-end testing with real data
4. Test fallbacks for missing data
5. Performance testing
6. Accessibility testing

### Phase 9: UI/UX Refinement
1. Adjust pastel colors based on feedback
2. Refine spacing and alignment
3. Add transition animations
4. Test on different screen sizes
5. Test light/dark mode
6. Optimize animation performance

### Phase 10: Documentation and Deploy
1. Document components in README
2. Add code comments
3. Create usage guide
4. Code review with team
5. Merge to main
6. Deploy to production

## Testing Checklist

### Unit Tests
- [x] zodiac_calculator_test.dart
- [x] trimestre_calculator_test.dart

### Widget Tests
- [x] profile_photo_widget_test.dart
- [x] bpm_display_widget_test.dart
- [x] kick_counter_button_test.dart
- [x] trimestre_progress_bar_test.dart
- [x] zodiac_badge_widget_test.dart
- [x] baby_card_widget_test.dart

### Integration Tests (Pending)
- [ ] Load profile photo from Supabase
- [ ] Play audio with different BPMs
- [ ] Register kicks and persist to database
- [ ] Verify trimestre progress calculation
- [ ] Display correct zodiac sign
- [ ] Test fallbacks for missing data

## Files Modified

1. `cria_app/lib/screens/home_screen.dart`
   - Removed `_babyMonthAssetPath()` function
   - Added BabyCardWidget import
   - Added nested StreamBuilder for baby_profile
   - Replaced old baby card with BabyCardWidget

2. `database/setup_baby_profile_db.sql` (NEW)
   - Complete baby_profile table schema
   - Indexes and RLS policies
   - Trigger for updated_at timestamp

## Files Not Modified (Already Complete)

1. `cria_app/lib/widgets/baby_card/baby_card_widget.dart`
2. `cria_app/lib/widgets/baby_card/profile_photo_widget.dart`
3. `cria_app/lib/widgets/baby_card/bpm_display_widget.dart`
4. `cria_app/lib/widgets/baby_card/zodiac_badge_widget.dart`
5. `cria_app/lib/widgets/baby_card/trimestre_progress_bar.dart`
6. `cria_app/lib/widgets/baby_card/kick_counter_button.dart`
7. `cria_app/lib/utils/zodiac_calculator.dart`
8. `cria_app/lib/utils/trimestre_calculator.dart`

## Verification Status

### Code Compilation
- ✅ home_screen.dart - No diagnostics
- ✅ baby_card_widget.dart - No diagnostics
- ✅ All sub-widgets - No diagnostics

### Database Schema
- ✅ Migration file created
- ⏳ Migration needs to be applied to Supabase
- ⏳ RLS policies need to be verified

### Integration
- ✅ BabyCardWidget properly integrated
- ✅ StreamBuilder fetches baby_profile data
- ✅ Data passed correctly to widget
- ⏳ Real data testing pending

## Known Issues / Considerations

1. **Database Migration**: The migration file needs to be applied to the Supabase database. This should be done through the Supabase dashboard or CLI.

2. **Existing Data**: If baby_profile table already exists, the migration should be adjusted to add missing columns using ALTER TABLE instead of CREATE TABLE.

3. **RLS Policies**: The RLS policies assume the profiles table has a family_id column. Verify this exists before applying the migration.

4. **Fallback Handling**: The BabyCardWidget properly handles null values for all fields, so missing data won't cause crashes.

5. **Performance**: The nested StreamBuilder may cause rebuilds when either profiles or baby_profile data changes. Consider using a combined query if performance becomes an issue.

## Deployment Checklist

- [ ] Apply database migration to Supabase
- [ ] Verify RLS policies are working correctly
- [ ] Test with real Supabase data
- [ ] Run all tests (unit, widget, integration)
- [ ] Code review with team
- [ ] Merge to main branch
- [ ] Deploy to production
- [ ] Monitor for errors in production
- [ ] Gather user feedback on UI/UX
