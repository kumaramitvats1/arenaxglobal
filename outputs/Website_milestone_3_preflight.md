# Registration milestone preflight — October 21, 2026

Historical preflight. Implementation and verification are now recorded in [milestone 3](Website_milestone_3.md). No live rows or schema were changed during this preflight itself.

## Current application

The live database contains the completed legacy cricket event and the newly published Dallas community Volleyball event. Dallas uses per-team pricing and USD. Publishing does not open registration; the next workflow needs an authorized registration-open/close action.

The existing 91 database regression tests and 11 website unit tests passed again locally. These tests do not prove the unaudited roster and waiver write paths are secure.

## Findings confirmed against live policies

1. Captains/event managers can insert and update roster rows, including invitation_status and waiver_status. There is no roster protection trigger. The website must not rely on its buttons to prevent a captain from accepting another person's invitation or waiver.
2. Waiver acceptance INSERT policy checks the signed-in user and active waiver only. It does not bind registration_id to that user/team or the waiver's event, or enforce a server-generated acceptance timestamp. No acceptance protection trigger exists.
3. Organizers can modify waiver rows. No immutability trigger preserves accepted waiver text/version. New versions should preserve the text already accepted.
4. Registration amounts are calculated on insertion. Changing an accepted roster afterward can make per-player totals stale. The saved roadmap explicitly leaves this product rule unresolved.

These are findings from schema/policy inspection, not exploit tests. Existing migrations must remain unchanged; fixes need additive migrations and allow/deny regression tests.

## Implementation sequence

1. Protect roster consent, registration ownership/event linkage, server timestamps and accepted waiver versions. Test direct table calls as well as RPCs, including anonymous, suspended, unrelated users, captains and organizers.
2. Add team creation and roster invitation/response screens. Each invited player accepts or declines for themselves; captains cannot accept waivers for players.
3. Add organizer registration opening/closing, individual/team submission and versioned waiver reading/acceptance. Preserve existing fee models and calculate amounts on the server. Display payment as pending; do not collect money yet.
4. Add organizer review and participant status screens. Approval must verify actual roster/waiver state and leave payment verification separate.
5. Run local and rollback-only live database checks, browser role journeys, production build, publish and push source to GitHub.

## Product decision — resolved

The user chose: lock the roster after submission; the organizer handles changes. The implemented flow reopens unpaid entries for changes and recalculates the fee on resubmission.

Payment checkout, payment reconciliation, scoring and attendance screens remain separate later milestones. Continue Texas/USA samples and USD defaults; preserve existing live records.
