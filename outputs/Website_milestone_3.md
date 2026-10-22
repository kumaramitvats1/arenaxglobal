# Teams and registration — October 22, 2026

The Teams & registration navigation and event-detail link open the new enrollment workspace. Organizer controls open/close registration, publish an approved waiver version before submissions, review entries, and reopen unpaid registrations for roster changes. Participants can create teams, invite existing accounts by member code, respond to their own invitations, accept their own waivers, and submit individual/team entries. Invitations are in-app; no email is sent.

## Accepted roster rule

The user chose to lock the roster after submission, with organizers handling changes. Submitted team rosters are locked, including rejected/waitlisted entries. An organizer can reopen an unpaid entry while registration is open; the captain then resubmits, and the server recalculates the fee from the accepted active roster. Paid, partially paid and refunded entries cannot be reopened through this API. Approval does not mark a payment paid. Payment collection remains unavailable.

## Server enforcement

Migration 020 adds public security-invoker wrappers over identity/ownership-checked private transactional implementations. Event-row locking serializes enrollment and waiver operations. Direct authenticated roster/waiver writes are revoked; ordinary users cannot forge another player's invitation or waiver consent. Roster reads are limited to the member, captain or event manager. Server-stamped waiver acceptances reference the exact immutable waiver row/version, independently of any registration; submission checks every accepted participant against all effective active event waivers.

A new trigger protects legacy direct registration submissions as well as RPC submissions. Existing migrations and legitimate organizer financial-administration paths remain intact. The new enrollment API does not expose payment-setting operations. Private audit rows record enrollment actions, actor, subject and time. The audit table has no client grants or RLS policies (intentional default deny); privileged server code writes it.

New waiver publication retains old text and acceptance rows and deactivates earlier versions. The current API disallows publication while submitted registrations exist. It does not draft legal terms for the organizer. No-waiver events retain the existing NOT_REQUIRED behavior.

## Verification

- 127 database checks pass locally and on arenax-dev: 35 attendance, 41 sensitive-field security, 15 event setup/catalog and 36 enrollment checks.
- All live suites run in transactions and roll back. Before/after hashes match for events, teams, registrations, members, waivers and acceptances.
- Fourteen website unit tests and the production build pass.
- Browser sample checks cover team creation, submission with USD fees, locked roster and organizer reopening. Sample data stays in memory.
- Live multi-account browser acceptance/invitation and email confirmation/recovery round trips remain user acceptance checks. Database role tests verify the associated enrollment authorization. Concurrent sessions are not exercised by the test harness.

Security advisors retain the 11 legacy authenticated SECURITY DEFINER warnings and disabled leaked-password protection. There is one informational default-deny audit-table notice. See [function guidance](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable), [password protection](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection) and [RLS policy notice](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).

## Next steps

1. User acceptance: configure a real event's approved waiver, open registration, invite a second account, accept its invitation/waiver and submit/review the team.
2. Payment provider selection, checkout, verified webhooks, reconciliation, receipts and refund handling. Never trust a client-side payment-success flag.
3. Authorized scoring/fixtures and participant QR/manual check-in screens.
4. Public launch preparation: hosting audience/domain, production email, leaked-password protection, monitoring and backups.

Hosting remains owner-private. Texas/USA samples and USD defaults remain in place. Existing live events were not renamed or opened by this release.
