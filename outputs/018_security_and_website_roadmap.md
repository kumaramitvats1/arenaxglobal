# Migration 018 and website roadmap

Verified October 18, 2026. Applied version: 20261018150240_arenax_018_protect_sensitive_fields.

## Delivered

Captured the existing legacy schema without rewriting prior migrations. Added a repeatable PostgreSQL test runner and GitHub test workflow.

Database triggers protect registration approval, payment summaries, amounts, waiver summaries, record identity and team leadership/approval fields. Ordinary users can submit drafts or cancel eligible registrations, but cannot reopen cancelled registrations. Fees are derived server-side at insertion, including accepted-roster counts for per-player team fees. Organizers can review their own event registrations; only Super Admin can change account status through the client. Active-account checks gate existing role helpers.

Removed anonymous access to current application tables/functions, authenticated table-maintenance privileges, and direct client access to internal standings/scheduling/trigger functions. Existing authenticated tournament RPCs remain available with authorization checks. Trusted database/service-role operations retain administrative access. Future APIs need explicit grants.

## Evidence

- Fresh isolated PostgreSQL restore: baseline plus 017, 017B and 018 passed.
- Local and live: all 35 check-in tests and all 41 new security tests passed.
- Tests cover protected inserts/updates/upserts, forged JWT role claims, suspension, cross-user isolation, organizer/admin permissions and server-derived fees.
- Live public application-table counts and checksums matched before and after migration/tests. Fixtures rolled back; original tournament records remain unchanged.
- Tests simulate JWT claims under database roles. Browser, Auth HTTP flows and concurrency remain integration-test work.

## Remaining security work

Anonymous security-definer exposure warnings are cleared. The advisor still reports 11 authenticated security-definer functions: existing role helpers and tournament APIs. Continue function-by-function review and consider private implementations/public invoker wrappers. This milestone is not a comprehensive security certification. See [advisor guidance](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable).

Leaked-password protection remains disabled in Supabase Auth; enable and verify before launch. See [password security guidance](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).

Before frontend integration, finish the write-permission audit for roster membership, waiver acceptance and privileged tournament operations. Public event browsing needs deliberately limited public views/APIs; migration 018 does not expose anonymous application data. Define fee repricing if roster membership changes after registration; this migration prices at insertion only. Payment-provider verification/webhooks and immutable payment audit are needed before accepting money.

## Website delivery order

1. Initial web application: Supabase sign-up/sign-in, password reset, profile completion and role-aware navigation. Test real HTTP sessions and protected routes.
2. Event listing/detail pages and organizer event setup using the frozen sports/event model. Expose only intended public fields.
3. Captain team/roster management, participant registration, versioned waiver acceptance, fees and organizer review.
4. Payment checkout, verified server webhooks, reconciliation, receipts and failure/refund handling.
5. Schedules, fixtures, standings, authorized scorer workflows and tournament completion displays.
6. Participant QR display and organizer/CHECK_IN scanner/manual attendance screens using existing RPCs.
7. Responsive/accessibility/error states, multi-role end-to-end tests, production Auth settings, backups, monitoring and deployment.

Next frontend milestone: sign-in, profile completion and role-aware dashboards after the remaining write-permission audit. Mobile uses the same backend; frozen roles remain unchanged.
