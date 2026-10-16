# ArenaX Global backend handoff — 20 September 2026

Project: [arenax-dev](https://supabase.com/dashboard/project/uzuiagwfmbbjztqvrsxn)

## Completed

016B converted kumaramitvats@hotmail.com (a289ed2b-99c9-4aad-affc-d3ca89ebcfbb) from the Bihar test captain to a confirmed SCORER for ArenaX India States Cricket Cup 2027, as explicitly approved. The captain role record remains INACTIVE, the team captain link is cleared, and the roster member remains ACTIVE as PLAYER.

Verified under the authenticated database role, then checked again after commit:

| Permission | Result |
|---|---|
| is_event_staff | true |
| has_event_staff_role(SCORER) | true |
| can_manage_event | false |
| is_super_admin | false |
| is_team_captain(Bihar) | false |
| is_team_captain(Jharkhand) | false |
| can_check_in_event | false |

Applied migrations:
- 20260920200524 — arenax_017_event_check_in
- 20260920200825 — arenax_017b_explicit_qr_token_isolation

Existing schema/function definitions were not replaced. The project's migration history was empty before this work: the earlier numbered migrations were executed in SQL Editor, rather than registered in Supabase migration history. They have not been replayed or reconstructed.

## Check-in behavior

One immutable event_check_ins row per event and participant records PRESENT, MANUAL or QR, registration, optional roster membership, operator, and server timestamp. No row means not yet checked in; it is not an absence declaration. This release is event-level attendance, not per-match or per-day attendance.

Only active-profile organizers/Super Admins and active CHECK_IN assignees can perform check-in. Existing ASSIGNED and CONFIRMED staff semantics are retained. Players cannot check themselves or others in. SCORER alone provides no check-in access. Participants can read their own attendance; check-in operators can read their event's attendance. All client table writes are revoked. Public functions are security invokers that call authorized private implementations.

Eligibility requires:
- Event exists and is neither DRAFT, CANCELLED nor COMPLETED.
- Active participant profile.
- APPROVED registration, PAID or NOT_REQUIRED payment, ACCEPTED or NOT_REQUIRED waiver status.
- For team registrations: an approved team in the same event and ACTIVE, ACCEPTED roster membership.
- Acceptance records for all currently effective active event waivers.

The existing completed tournament is not reopened for check-in.

QR tokens are 32 random bytes represented as 64 hexadecimal characters. Store/display them as QR payloads in the app. Tokens are event/participant-bound, valid for 24 hours, rotated upon reissue, and stored only as hashes in a private table. Issuance is allowed for the eligible participant themselves or an authorized check-in operator. A valid token identifies a participant; it never grants the scanner check-in permission. Do not log raw tokens or put them in public URLs.

Repeated successful requests return the original attendance row, preserving the first operator, timestamp and method. Concurrent requests for the same event/participant serialize through a transaction lock and the unique constraint. Expired or rotated tokens are rejected. Current eligibility is rechecked even for retries.

## Client API

Use the signed-in user's normal Supabase session.

```ts
const { data: allowed, error: permissionError } = await supabase.rpc(
  'can_check_in_event', { p_event_id: eventId }
);

const { data: tokenRows, error: tokenError } = await supabase.rpc(
  'issue_event_check_in_qr',
  { p_event_id: eventId, p_participant_user_id: participantId }
);
// tokenRows[0]: { qr_token, expires_at }. Render qr_token as a QR code.

const { data: attendance, error: checkInError } = await supabase.rpc(
  'check_in_event_participant',
  {
    p_event_id: eventId,
    p_participant_user_id: participantId,
    p_method: 'QR',
    p_qr_token: scannedToken
  }
);
// For MANUAL, use p_method: 'MANUAL' and p_qr_token: null.
// Handle every error before displaying success.
// SQLSTATE 42501: unauthorized; 22023: invalid input or ineligible participant.

const { data: rows, error: readError } = await supabase
  .from('event_check_ins')
  .select('*')
  .eq('event_id', eventId);
```

No frontend scanner or QR image renderer was built in this backend task. Issue and check-in endpoints are ready for that integration.

## Verification

35 transactional tests passed on the actual development database. Covered ordinary players, SCORER, CHECK_IN, Organizer and Super Admin; cross-event access; direct insert/update/delete denial; private token access denial; individual/team registration; manual and QR audit values; duplicate requests; rotation, wrong-user, malformed and expired tokens; revoked staff; cancelled registration; pending payment; removed roster; missing waiver acceptance; completed events; anonymous execution.

All fixtures and temporary permissions rolled back. Post-test state:
- One original event, still COMPLETED.
- 15 completed matches; Bihar remains champion.
- Zero attendance rows and zero QR tokens.
- Hotmail remains only a SCORER at event level.
- New tables have RLS; anonymous API execution and authenticated direct attendance writes are denied.

Tests exercised database authorization using simulated JWT claims under actual database roles. They did not exercise browser camera scanning, Supabase Auth sign-in, HTTP transport or a multi-connection load test.

## Existing security follow-up

No new advisor warnings remain for this module. Pre-existing findings remain:
- 15 public security-definer functions callable by anon; 15 callable by authenticated. These are exposure warnings requiring function-by-function authorization review, not proof that all calls can modify data. [Supabase guidance](https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable)
- Leaked-password protection is disabled. [Supabase guidance](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection)

The existing registration/profile update policies also deserve a separate column-permission audit before production. This task did not rewrite those older policies.

## Preserved product baseline

One Supabase backend/database for mobile and web; four everyday roles (Organizer/Admin, Captain/Team Manager, Event Staff/Official, Player/Participant), with Super Admin an internal permission. Staff types are assignments, not new account roles. The generic sports model, existing cricket results and champion flow, per-team/per-player registration model, versioned waivers and shared identity remain intact. Examples use Indian states and international teams.
