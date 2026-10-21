# ArenaX web portal

Static JavaScript portal with a bundled, pinned Supabase client. Uses the existing arenax-dev project and a publishable key only. No service-role credentials are present. Real user data stays behind Supabase Auth and existing RLS; sample tour data is separate and never written to the database.

Run npm ci, npm run build, npm test, then npm run dev in this directory. Preview: http://127.0.0.1:4173. Routing uses URL fragments so deployment does not need server route rewrites. Build emits dist/app.js; HTML/CSS are authored directly in dist/. The Sites manifest points to dist/.

Implemented: password sign-in, sign-up/confirmation/resend, password recovery, profile names, assignment-based workspaces, event search/detail, and read-only match results. Sample tour supports visual inspection without an account. Scoring, registration, checkout and check-in controls are intentionally not included in this milestone.

## Auth deployment configuration

Add the exact deployment origin root and origin/?recovery=1 to Supabase Auth's redirect URL allowlist. For local development use http://127.0.0.1:4173/ and http://127.0.0.1:4173/?recovery=1. Preserve any existing mobile redirect entries. PKCE email links must be opened in the browser that initiated the request. Configure a production email sender before onboarding external users. Enable leaked-password protection before launch.

Private Sites hosting adds an owner-access gate around this preview. It is not a public participant launch. Do not change its audience without an explicit request.

## Data access review

Only first_name and last_name are updated, on the authenticated user's profile; migration 018 independently protects identity/status fields. Own roles, staff assignments, accepted memberships and own registrations are filtered by user ID and subject to existing RLS. Events/teams/matches use the existing authenticated read policies; only required columns are requested. Captain navigation uses captain_user_id or active CAPTAIN membership, matching the existing helper's actual captain branches. Organizer navigation uses active ORGANIZER membership; Super Admin receives a separate internal workspace.

The UI re-fetches account status/assignments on protected navigation and focus. Hiding navigation is not a permission mechanism. No membership, role, payment, waiver or tournament writes are added. Existing broad authenticated event/team read policies are preserved; public browsing remains closed. Later roster/waiver/scoring write audits remain separate work.

## Verification limits

Unit tests cover revoked/suspended/multiple-role navigation, safe return routes, HTML escaping and date handling. The root database suite verifies server authorization. A real email confirmation/recovery round trip requires the redirect allowlist and the user's mailbox; a sample tour is not proof of live authentication.

Official API references: https://supabase.com/docs/reference/javascript/auth-signinwithpassword and https://supabase.com/docs/guides/auth/redirect-urls.
