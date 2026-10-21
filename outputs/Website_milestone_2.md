# Event discovery and organizer setup — October 21, 2026

The portal now includes a signed-out event directory at #/discover and an organizer workspace at #/setup. The Sites hosting audience remains owner-private; signed-out browsing refers to the ArenaX account layer, not a change to hosting access.

Organizers and Super Admins can create draft events, edit their own organization’s empty drafts, review publication details, and publish. New events default to USD; the sample organizer and venue use Texas, USA. Existing database records retain their original currency and location. Publishing does not open registration or collect payment.

Migration 019 adds a limited public catalog RPC and an authenticated, security-invoker event setup RPC. Catalog results include published event descriptions, dates, sport, venue name/city/state/country, registration type and advertised fee. They exclude organization/user identifiers, registration records, rosters and staff. Drafts and cancelled events are omitted. Pages contain at most 50 events; the interface supports loading additional pages and filters the loaded events.

Setup validates organizer authority, organization ownership, active sports and organization venues, dates, currency/fees and registration model. Updates lock the row and require its expected update timestamp. The new API rejects edits to non-drafts and drafts already containing teams, registrations or matches. Existing direct-table policies and tournament APIs are preserved; the setup restrictions are not a comprehensive rewrite of every legacy event write path.

A scoped SELECT policy also fixes INSERT ... RETURNING for organizers creating drafts: the new row’s organization is checked directly, instead of asking a stable function to find an inserted row it cannot yet see.

## Verification

- All 91 database tests pass locally: 35 check-in, 41 existing security and 15 event setup/catalog tests.
- All 15 new tests pass on arenax-dev in a rollback-only transaction.
- The existing event row count and checksum match before and after migration/tests.
- Eleven website unit tests and the production bundle build pass.
- Browser sample checks cover creating a Texas/USD draft, reopening it, reviewing publication and publishing in memory. These sample actions do not create database records.
- Live authenticated organizer browser submission is still a user acceptance step; database role tests cover its server authorization.

The security advisor reports the same 11 legacy authenticated SECURITY DEFINER warnings and disabled leaked-password protection, with no new warning category. See [function guidance](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable) and [password protection](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection).

## Next milestone

Team creation/rosters and individual/team registration, including versioned waiver acceptance and organizer review. Audit those write paths before enabling controls. Venue creation, post-publication event changes, registration opening, payments, scoring writes and check-in screens remain later workflows.
