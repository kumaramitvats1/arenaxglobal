# ArenaX Global

Shared Supabase backend for the web and mobile MVP. The portal in web/ includes Auth, profiles, dashboards, event discovery/setup and team/registration workflows. See [web setup and verification limits](web/README.md).

## Current status

Migration 021 is applied to arenax-dev. On October 22, 2026, all 152 database checks passed locally and live: 35 check-in, 41 sensitive-field/authorization, 15 event setup/catalog 36 enrollment and 25 tournament tests. Existing application data checksums were unchanged. The completed tournament remains intact.

- 016B: Hotmail development account converted from captain to event SCORER.
- 017/017B: authorized manual/QR check-in, attendance audit and private hashed tokens.
- 018: server-enforced registration/payment/profile/team field protection, active-account permission helpers, reduced anonymous and maintenance privileges.
- 019: limited public event catalog and authorized organizer draft setup/publication.
- 020: teams/invitations, player-owned consent, submission fees, roster locks and organizer review/reopening.

- 021: guarded cricket scoring, confirmed-result locks, schedule validation and organizer tournament progression.

## Test locally

Use Node.js 22 or later: run `npm ci`, then `npm test`.

Tests restore the legacy schema and replay all migrations in isolated PGlite PostgreSQL, then run five rollback-only SQL suites. No cloud credentials are needed. Tests simulate database roles and JWT claims; they do not test Supabase Auth sign-in, HTTP transport, browser UI or concurrent connections.

## Database bootstrap

`supabase/baselines/legacy_through_016.sql` reconstructs the legacy application schema from metadata captured October 18, 2026: 22 tables, 15 functions and 50 policies. It is a schema snapshot, not the original historical migrations 001–016A. Regenerate with `node scripts/generate-baseline.mjs supabase/baselines/catalog_before_018.json`.

For a fresh Supabase database only, apply the baseline first, then files in `supabase/migrations/` in filename order. The baseline assumes Supabase provides Auth and database roles. It contains no user/business records, Auth settings, secrets or storage configuration. A plain `supabase db reset` does not include this separate baseline automatically.

Do not apply the baseline or replay already-applied migrations on arenax-dev. Recorded migration versions match the live database; original 017 files are preserved. Automated cloud deployment is not configured.

## Documentation

- [Tournament release and remaining work](outputs/Website_tournament_release.md)

- [Website page map and first-release brief](outputs/Website_plan.md)
- [Teams/registration release and next steps](outputs/Website_milestone_3.md)

- [Security verification and website roadmap](outputs/018_security_and_website_roadmap.md)
- [Check-in API and original backend handoff](outputs/ArenaX_backend_handoff.md)
- [Original applied migration export](outputs/Applied_017_export.md)

One identity system serves web and mobile. Everyday roles remain Organizer/Admin, Captain/Team Manager, Event Staff/Official and Player/Participant. Super Admin is internal; SCORER and CHECK_IN are event staff assignments. New examples use Texas, USA and USD; historical fixtures and live records are preserved.
