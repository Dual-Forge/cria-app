# PLAN - Resolve Infinite Loading Bug & Verify Connectivities

This plan maps the steps to debug the infinite loading screen in the Cria mobile app and verify connectivity settings on Vercel and Supabase.

---

## 📋 Success Criteria
1. The Flutter application compiles and opens successfully without hanging on a blank loading screen.
2. The user is redirected to either the `LoginScreen`, `ProfileSetupScreen`, or `SplashScreen` -> `MainScreen` based on their session/profile state.
3. Supabase integration is verified (schema queries work and tables are accessible).
4. Vercel deployment configurations and environment variables are checked and aligned with the correct values.

---

## 🛠️ Tech Stack
- **Frontend/Mobile**: Flutter (Dart) with `supabase_flutter` for DB/Auth, `go_router` for navigation, and `flutter_dotenv` for local environment.
- **Backend**: FastAPI (Python) hosting core APIs (pregnancy advice, product scrapers).
- **Hosting/Infra**: Vercel (for frontend web deploy) and Supabase (for database/auth backend).

---

## 🗂️ Proposed File Changes
We will verify and modify files across the Flutter app feature layers:
- `cria_app/lib/features/parents/ui/profile_setup_screen.dart` (Add missing `import 'dart:typed_data';` for compiling).
- `cria_app/lib/features/splash/ui/splash_screen.dart` (Add error/timeout handling to prevent infinite spinner in case of Supabase offline states).
- `cria_app/lib/features/parents/ui/auth_flow_screens.dart` (Verify FutureBuilder / StreamBuilder routing flows to prevent loading deadlocks).

---

## 🤖 Specialist Agent Allocations
We will invoke the following specialist agents:
1. `mobile-developer` - Lead agent for debugging the Flutter navigation, state machines, and Supabase integration.
2. `backend-specialist` - Validate the FastAPI backend connectivity and response payloads.
3. `devops-engineer` - Inspect and synchronize environmental configuration keys across Vercel and Supabase.
4. `test-engineer` - Run checks, compile builds, and verify flows.

---

## 📝 Task Breakdown

### Phase 1: Exploration & Diagnostics
- **Task 1**: Compile the Flutter web application locally to identify any current syntax or compilation blockers.
  - **Agent**: `test-engineer`
  - **Input**: `cria_app` codebase
  - **Output**: Build compiler output logs
  - **Verify**: Clean build or compilation errors highlighted
- **Task 2**: Diagnose the Supabase remote connectivity using CLI/Curl.
  - **Agent**: `devops-engineer`
  - **Input**: `.env` and `.env.local` configs
  - **Output**: REST endpoint responses
  - **Verify**: HTTP 200 OK from REST queries to `profiles` table

### Phase 2: Fix Implementation
- **Task 3**: Add missing imports and fix any compiling/syntax issues in `profile_setup_screen.dart`.
  - **Agent**: `mobile-developer`
  - **Input**: `profile_setup_screen.dart`
  - **Output**: Clean compilation unit
  - **Verify**: Code builds successfully
- **Task 4**: Implement fallback timeout/error handlers in `SplashScreen` and `AuthGateScreen` loading processes.
  - **Agent**: `mobile-developer`
  - **Input**: `splash_screen.dart`, `auth_flow_screens.dart`
  - **Output**: User gets error screen/retry options if Supabase requests hang or fail.
  - **Verify**: Loading state terminates after timeout.

### Phase 3: DevOps & Deployment Sync
- **Task 5**: Verify Vercel deployment variables (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GROQ_API_KEY`) and link/sync them.
  - **Agent**: `devops-engineer`
  - **Input**: Local `.env` vs Vercel environment
  - **Output**: Production config alignment
  - **Verify**: Vercel variables match local variables

---

## 🏁 Phase X: Verification
- [ ] Run `flutter build web` successfully.
- [ ] Execute security scanner on codebase.
- [ ] Perform manual test of the web app launch.
