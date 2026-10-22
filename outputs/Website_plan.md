# ArenaX Global website plan

Proposed website brief. Existing product decisions remain authoritative. This plan does not imply a website is implemented or deployed.

## First milestone

Deliver a connected journey: sign in → complete profile → see authorized dashboard → open an event. Keep website source in web/ within the existing repository and retain the database test workflow. Choose and pin the framework and hosting target against current official documentation during implementation.

## Fixed product boundaries

One Supabase identity/backend serves web and mobile. Everyday workspaces are Organizer/Admin, Captain/Team Manager, Event Staff/Official and Player/Participant. Super Admin is internal. SCORER and CHECK_IN remain event assignments. Workspace selection changes the view, never permissions. Preserve the existing migrations, completed tournament, fee model and versioned waivers. Per the October 21 update, website sample data uses Texas, USA and USD. Existing live event records retain their stored location and currency.

## Page map

| Area | Proposed pages | Milestone |
|---|---|---|
| Account | /sign-in, /sign-up, /forgot-password, /reset-password, confirmation/callback states | 1 |
| Profile | /onboarding/profile, /app/profile | 1 |
| Dashboard | /app with authorized workspace selector | 1 |
| Signed-in event | /app/events/:eventId | 1 |
| Public | /, /events, /events/:eventId | 2 |
| Organizer | /app/organizer; event setup, registration review, teams, staff, schedules | Overview in 1; actions later |
| Captain | /app/captain; teams, roster invitations, team registration | Overview in 1; actions in 3 |
| Staff | /app/staff; assignments, scorer workspace, check-in desk | Overview in 1; actions in 5–6 |
| Player | /app/player; registrations, team memberships, waivers, payments, QR pass | Overview in 1; actions later |
| Internal | /app/admin; organization/account administration | Authorized entry in 1; tools later |
| Support | Access denied, not found, session expired, account unavailable, service error | 1 |

Public browsing needs a deliberately limited data contract. Current anonymous application-table access is denied. Do not restore broad anonymous grants to implement public pages.

## Dashboard content

| Workspace | Content | Later primary actions |
|---|---|---|
| Organizer | Managed events and authorized review counts | Manage event, review registration, assign staff |
| Captain | Managed teams and registration/roster status | Manage roster, submit registration |
| Staff | Assigned events with explicit SCORER/CHECK_IN labels | Score or check in according to assignment |
| Player | Own registrations, memberships and event details | Register, accept waiver, pay, show QR |
| Super Admin | Internal organization/account overview | Manage organizations/accounts |

Use real query results and truthful empty states. Hide unfinished actions rather than show buttons that do nothing. Accounts may have several workspaces: show all permitted choices, remember the selected view, and recheck permissions on navigation/actions. New users without assignments receive a player view with an empty state; do not invent role records.

## First journey

1. Open sign-in or an event link. Preserve a safe internal return path.
2. Sign up using the configured email-confirmation flow. Handle confirmation pending, resend, invalid and expired links.
3. Complete required profile fields. Proposed minimum is first and last name using existing fields; reconcile any additional requirements before adding fields.
4. Resolve active account status, memberships and assignments from the backend. Sign-up cannot grant organizer or staff permissions.
5. Show the appropriate dashboard and available workspaces.
6. Open an event showing name, sport, location, dates/timezone, status and available schedule/results.
7. Sign-out removes protected content. Session expiry leads to sign-in; unavailable accounts receive a neutral support state.

Password recovery covers valid, expired and reused links. Forms prevent duplicate submissions, preserve safe input on recoverable errors and avoid revealing whether an email belongs to an account.

## Proposed visual direction

Organized competitive sport, suitable for community and international events. Use navy #10243A navigation/headings, white cards, light #F5F7FA backgrounds, dark slate #334155 body text and dark orange #B9470B primary actions. Verify contrast during implementation. Start with a system sans-serif font and text wordmark until approved branding is available.

Desktop layout: compact left navigation; workspace/event selector and account controls at the top; welcome message, next available action and event cards in the content area. Mobile layout: menu drawer, clearly labeled workspace and stacked cards. Use single-column forms and readable schedule tables.

Event cards prioritize name, sport, location, dates and status. Avoid invented statistics. Status badges use text/icons as well as color. Show actual event currency and explicit timezones. Include visible focus, keyboard operation, usable touch targets and reduced-motion support; aim for WCAG 2.2 AA and verify against current guidance during implementation.

## Backend integration boundaries

Use the user's Supabase session for data access. Browser configuration contains only the project URL and publishable key. Keep service-role credentials out of frontend bundles. Route guards improve usability; RLS/functions remain authoritative.

Finish the relevant profile/membership permission audit before wiring dashboards. Audit roster, waiver and scoring writes before enabling those later workflows. Use narrowly scoped APIs when current access is insufficient. Separate development/production configuration and allowlist Auth redirects. Never reset or seed the live database automatically.

The existing tournament remains completed. Create separate development fixtures for active-event journeys. Attendance remains event-level: no attendance row means not checked in, not absent. A participant QR identifies its holder; the scanner still needs CHECK_IN permission.

## Milestone 1 acceptance criteria

- Real Supabase sign-up, confirmation, sign-in, sign-out and recovery work through HTTP.
- Profile onboarding persists permitted fields and cannot modify account status.
- Dashboards use actual assignments, including accounts with multiple or no workspaces.
- The Hotmail scorer has no captain, organizer, Super Admin or CHECK_IN access.
- Direct URLs and unauthorized requests fail safely; suspended/revoked permissions are enforced.
- The completed event displays accurate status and offers no registration/check-in action.
- Loading, empty, error and expired-session states work.
- Browser verification covers keyboard use and mobile layouts.
- Existing 76 database tests still pass; add meaningful Auth/browser tests for this journey.
- Build succeeds, configuration is documented and secrets remain uncommitted.

## Delivery sequence

1. Foundation: permission audit, responsive components, Auth, profile onboarding, workspace dashboards and signed-in event detail.
2. Public event discovery and organizer event setup with reviewed public-data exposure.
3. Teams/rosters, registration, versioned waivers and organizer review. Resolve roster-change fee repricing before charging.
4. Payment checkout, verified server webhooks, receipts, reconciliation and failure/refund handling.
5. Fixtures, standings, authorized scoring and tournament completion UI.
6. Participant QR pass, authorized scanning/manual check-in and attendance lists.
7. Launch: multi-role end-to-end tests, production Auth settings including leaked-password protection, backups, monitoring and deployment.

Next implementation deliverable: a reviewable preview of milestone 1. Payment provider, production domain and production hosting are not selected by this plan.

## October 22 progress

Milestones 1–3 are implemented. Stripe payments (milestone 4) are deferred by the user. The first milestone 5 slice adds fixtures/standings, cricket scoring, scheduling existing fixtures and organizer progression. Fixture creation, other sport scoring and check-in screens are still pending. See Website_tournament_release.md.

Cricket-only scope confirmed by the user. Cricket fixture assignment/preview/generation is implemented by migration 022. Volleyball scoring and Stripe remain deferred. Next cricket milestone: participant QR passes and check-in screens. See Website_cricket_fixtures.md.
