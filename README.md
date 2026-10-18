# ArenaX Global

Shared Supabase backend for the web and mobile MVP. No frontend is included yet.

## Current status

Migration 018 is applied to arenax-dev. On October 18, 2026, all 76 database checks passed locally and live: 35 check-in tests and 41 sensitive-field/authorization tests. Existing application data checksums were unchanged. The completed tournament, 15 matches and Bihar championship remain intact.

- 016B: Hotmail development account converted from captain to event SCORER.
- 017/017B: authorized manual/QR check-in, attendance audit and private hashed tokens.
- 018: server-enforced registration/payment/profile/team field protection, active-account permission helpers, reduced anonymous and maintenance privileges.

## Test locally

Use Node.js 22 or later: run `npm ci`, then `npm test`.

Tests restore the legacy schema and replay all migrations in isolated PGlite PostgreSQL, then run both rollback-only SQL suites. No cloud credentials are needed. Tests simulate database roles and JWT claims; they do not test Supabase Auth sign-in, HTTP transport, browser UI or concurrent connections.

## Database bootstrap

`supabase/baselines/legacy_through_016.sql` reconstructs the legacy application schema from metadata captured October 18, 2026: 22 tables, 15 functions and 50 policies. It is a schema snapshot, not the original historical migrations 001–016A. Regenerate with `node scripts/generate-baseline.mjs supabase/baselines/catalog_before_018.json`.

For a fresh Supabase database only, apply the baseline first, then files in `supabase/migrations/` in filename order. The baseline assumes Supabase provides Auth and database roles. It contains no user/business records, Auth settings, secrets or storage configuration. A plain `supabase db reset` does not include this separate baseline automatically.

Do not apply the baseline or replay already-applied migrations on arenax-dev. Recorded migration versions match the live database; original 017 files are preserved. Automated cloud deployment is not configured.

## Documentation

- [Security verification and website roadmap](outputs/018_security_and_website_roadmap.md)
- [Check-in API and original backend handoff](outputs/ArenaX_backend_handoff.md)
- [Original applied migration export](outputs/Applied_017_export.md)

One identity system serves web and mobile. Everyday roles remain Organizer/Admin, Captain/Team Manager, Event Staff/Official and Player/Participant. Super Admin is internal; SCORER and CHECK_IN are event staff assignments. Examples use Indian states and international teams.
