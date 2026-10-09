# VORTEX — Volunteer Community Management Platform

A production-quality Flutter mobile application built for volunteer and disaster relief management with **zero-cost infrastructure**, featuring a **real-time OpenStreetMap live radar**, battery-conscious location streaming, multi-community scoping, RBAC permissions, and QR-enabled workflows.

---

## 🌟 Key Features

- **Community Live Map (Primary Experience)**:
  - Powered by **OpenStreetMap / CartoDB** tile servers via an abstracted `MapService` layer (100% Free, Zero Google Maps API fees).
  - **Dynamic Presence Markers**:
    - 🟢 **Online (0–5 min)**: Emerald active marker with telemetry indicator.
    - ⚪ **Stale (5–15 min)**: Grey marker indicating inactive/stationary responder.
    - **Offline (15+ min)**: Automatically categorized or hidden.
  - Interactive bottom sheet displaying responder name, role, assigned team, GPS accuracy, volunteer ID, and contact options.
  - Instant recentering, bounds fitting, and search filters (All, Online, Stale, Offline, Role).
- **Zero-Compromise Location Privacy**:
  - Educational privacy explanation screen before any OS location prompt is shown.
  - Dedicated **Location Sharing ON / OFF** toggle on the live map and profile.
  - Battery-conscious distance filtering (>30m movement or 30-60s throttle).
  - Ephemeral live coordinate table (`locations_live`) separate from 5-minute periodic archive snapshots (`location_snapshots`).
- **Multi-Community Scoping**:
  - Users can join multiple communities and toggle seamlessly using the Community Switcher.
  - Strict data isolation: Members of Community A **never** receive telemetry or messages from Community B.
- **Unique Community Invite Codes & QR**:
  - Auto-generated human-readable codes (e.g., `AVX-7K29P`).
  - QR Code generation for one-tap volunteer onboarding.
  - Optional admin approval workflow.
- **Role-Based Access Control (RBAC)**:
  - `Owner` → Complete administrative authority & code invalidation.
  - `Admin` → Member management, teams, announcements, and visibility controls.
  - `Coordinator` → Team operations, events, and field volunteer guidance.
  - `Volunteer` → Live coordinate sharing, event check-ins, and team communication.
- **Events & Attendance**:
  - Event discovery with venue and schedule breakdown.
  - QR Code digital pass generation and geolocation check-in verification.
- **Announcements & Broadcasts**:
  - Priority alert tags (`Normal`, `Urgent`, `Emergency SOS`).

---

## 🏗️ Zero-Cost Architecture Stack

```
               MOBILE USERS (Flutter Mobile Client)
                               │
               ┌───────────────┴───────────────┐
               │                               │
             HTTPS                         REALTIME
         (PostgREST)                      (WebSockets)
               │                               │
               └───────────────┬───────────────┘
                               ▼
                   SUPABASE (Free Tier)
          ┌────────────────────┼────────────────────┐
          ▼                    ▼                    ▼
     PostgreSQL 15+        Realtime Engine       Storage Buckets
     (RLS Protected)    (Ephemeral Presence)     (Avatars/Assets)
          │
          ▼
   OpenStreetMap / CartoDB
     (Map Tile Provider)
```

---

## 🚀 Quick Start Guide

### 1. Database Setup (Supabase)
Your project is configured with:
- **Project URL**: `https://rdomnnaaaafdczzmwryi.supabase.co`
- **Anon Public Key**: Active in [`lib/core/config/supabase_config.dart`](lib/core/config/supabase_config.dart)

Next, in your Supabase dashboard:
1. Open the **SQL Editor** at `https://supabase.com/dashboard/project/rdomnnaaaafdczzmwryi/sql`.
2. Paste the contents of [`supabase/schema.sql`](supabase/schema.sql) and click **Run**.
3. Under **Authentication** > **Providers**, ensure **Email** provider is enabled with password sign-in (social providers disabled as requested).

### 2. Launch the Application
Because your credentials are now baked into [`lib/core/config/supabase_config.dart`](lib/core/config/supabase_config.dart), you can run directly without flags:

```bash
flutter run
```

*Note: The application includes instant mock fallbacks, allowing you to run, explore, and test the full application and simulated responders out of the box even before configuring cloud keys!*

### 3. Run Tests
Execute the comprehensive unit and security test suite:

```bash
flutter test
```

Test coverage includes:
- Role & RBAC permissions (verifying volunteers cannot access admin tools).
- Multi-community code generation uniqueness.
- Live map presence threshold calculations (0-5m Online, 5-15m Stale, 15m+ Offline).
- Location visibility policy mappings.

---

## 🔒 Security Model & Row Level Security (RLS)

All security checks are verified at the **PostgreSQL database level**, ensuring the Flutter app cannot be exploited to bypass permissions:
- `locations_live`: Protected by RLS policies that evaluate `is_community_member()` and the community's `location_visibility` setting (`all_members`, `admins_coordinators_only`, or `team_members_only`).
- Passwords are encrypted through Supabase Auth (Argon2/bcrypt); passwords are never stored in plaintext.
- The `service_role` secret key is **never** embedded in the client application.
