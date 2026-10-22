# Tournament workspace — October 22, 2026

Stripe connection and checkout are deferred at the user's request. No payment migration or secrets were deployed. The next delivered slice is the tournament workspace, available at /#/tournament.

## Delivered

- Event selector, fixtures with stage/status filters, innings totals, confirmed results, group standings and champion banner.
- America/Chicago display times; schedule inputs explicitly use the device timezone.
- Organizers can schedule existing pending fixtures, start an event after registration closes, resolve semifinalists and complete an eligible cricket tournament.
- Active event SCORER staff and organizers can confirm pending cricket results. Home bats first, away bats second; existing scoring and net-run-rate rules are preserved. Semifinal results automatically resolve the final.
- Confirmed results cannot be overwritten through the application. Direct authenticated writes to matches, innings, results and standings are revoked. Guarded functions serialize changes on the event row. Scheduling also has a stale-edit check and a shared scheduling lock.
- Migration 021 attaches the previously unattached schedule-validation trigger for venue overlaps and 60-minute team rest. Previous migrations are untouched.
- Public tournament RPCs use SECURITY INVOKER wrappers and checked privileged implementations in arenax_private.

## Verification

152 rollback-only database checks passed locally and on arenax-dev (35 check-in, 41 field security, 15 event setup, 36 enrollment, 25 tournament). The new suite covers scorer authorization/revocation/suspension, invalid/repeated scores, standings, semifinal/final progression, schedule conflicts and completion. Twenty web unit tests pass; build succeeds.

Before/after checksums match for live events, matches and standings. Test fixtures roll back. No historical result was changed. Security advisor warnings for exposed privileged functions dropped from 11 to 7 existing identity/permission helpers. The private audit table's intentional default-deny informational finding and the existing leaked-password protection launch task remain.

Browser checks cover sample navigation and completed results; live read-only verification follows deployment. Active scoring is exercised in database tests; real multi-account browser scoring and concurrent-client tests remain outstanding.

## Remaining

1. Fixture creation/bracket setup UI for new events. Current controls schedule existing fixtures; new Dallas volleyball has none yet.
2. Volleyball and other sport-specific scoring. Cricket tie-break entry and result corrections are not implemented.
3. Participant QR passes and authorized check-in screens over the existing backend.
4. Stripe checkout/webhooks/receipts/refunds when connection setup resumes.
5. Multi-role browser tests, email round trips, production Auth hardening, monitoring/backups and launch access decisions.

The Site remains owner-private, not a public participant launch.
