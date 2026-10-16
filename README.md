# ArenaX Global

Backend work for the ArenaX Global sports events MVP, shared by the future mobile and web applications.

## Included

- `supabase/migrations/`: exact SQL exports of applied migrations 017 and 017B, using their recorded database versions.
- `outputs/016B_assign_and_validate_scorer.sql`: development account conversion and permission assertions.
- `outputs/017_verification.sql`: 35 transactional check-in tests; fixtures and temporary permissions roll back.
- [Backend handoff](outputs/ArenaX_backend_handoff.md): API usage, security rules, verification results, and follow-up items.
- [Applied migration export](outputs/Applied_017_export.md): reviewable record of the deployed SQL.

## Current milestone

Migration 016B validated the event scorer's permissions. Migration 017 added server-authorized manual and QR participant check-in, attendance auditing, and RLS. Migration 017B made private QR-token isolation explicit.

Last database verification: September 20, 2026. All 35 check-in tests passed. The original tournament remained completed with 15 completed matches and Bihar as champion. Publishing this repository does not rerun or change the database.

## Database baseline

This repository is an incremental handoff, not yet a complete database bootstrap. Migrations 001 through 016A were previously run through Supabase SQL Editor and are not captured here as migration files. The included migrations depend on that existing schema and authorization helpers.

The two timestamped migrations are already applied to `arenax-dev`. Do not rerun them there or reset the database from this incomplete migration set. Capture and reconcile the earlier baseline before configuring automated database deployment or creating a fresh database from this repository.

The verification script is for the development database and references its existing test users and event. It runs in a transaction that ends in rollback. Do not treat it as a production seed script.

## Preserved product decisions

One backend and identity system serves mobile and web. The four everyday roles are Organizer/Admin, Captain/Team Manager, Event Staff/Official, and Player/Participant. Super Admin is an internal permission; SCORER and CHECK_IN are event staff assignments. Examples use Indian states and international teams.

No frontend application is included yet. See the handoff for existing security findings and the check-in API contract.
