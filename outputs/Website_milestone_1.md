# Website milestone 1 — October 21, 2026

Private preview: https://arenax-global-portal.trueraven12.chatgpt.site

Source: web/ in kumaramitvats1/arenaxglobal. Sites publishes an isolated release copy so its repository does not replace the existing GitHub repository.

## Implemented

- Responsive navy/white/orange sign-in and dashboard design.
- Supabase password sign-in, sign-up, confirmation resend, recovery and reset forms.
- First/last name onboarding with server-protected profile updates.
- Active membership/assignment workspace resolution and truthful empty states.
- Searchable authenticated event directory, event details and read-only match results.
- Explicit sample tour with Texas, USA examples and USD pricing; no database writes.
- Pinned dependencies, build scripts and GitHub website checks.

## Verified

- Website build and seven unit tests passed.
- All 76 existing backend tests passed after restoring the baseline and migrations locally.
- Browser checks: sign-in layout, sample dashboard, event navigation/detail, empty event search, 390-pixel sign-in/dashboard layouts.
- Live Supabase Auth settings returned HTTP 200: email Auth enabled, sign-up enabled, email confirmation required. Anonymous event access returned HTTP 401.
- Live scorer role query: own profile visible, one active staff assignment, no active privileged role, one visible event and 15 visible matches. Super Admin, event management and Bihar captain checks remained false.
- No application data or migrations were changed during this website milestone.
- Sites deployment succeeded with owner-private access. The hosted URL has a ChatGPT gate before the ArenaX application login.

## Still pending

The browser is not signed into the Supabase dashboard. Verify/add these exact allowed redirect URLs under Authentication → URL Configuration, preserving existing entries:

- https://arenax-global-portal.trueraven12.chatgpt.site/
- https://arenax-global-portal.trueraven12.chatgpt.site/?recovery=1
- http://127.0.0.1:4173/
- http://127.0.0.1:4173/?recovery=1

The connected Supabase tools do not expose Auth URL settings. Real sign-in, email confirmation, recovery and profile-write browser round trips have not been completed with a user's account. These remain acceptance checks, not claimed passes. Do not share passwords in chat; enter credentials directly in the app. Open PKCE email links in the browser that initiated them.

Before public onboarding: configure email delivery and leaked-password protection, complete the remaining write-permission audits, and explicitly choose a public deployment audience. This release does not implement registration, payment, scoring writes or check-in screens.

Deployment ID: appgdep_6ad8bb994db081918a4169ce205a23b1.
Site source commit: c0778e5d600a9ac62d990048f6508ceb7089b1c9.
