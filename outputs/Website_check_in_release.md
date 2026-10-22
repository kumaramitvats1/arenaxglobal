# Website check-in release — 2026-10-22

Adds Passes & check-in navigation and event entry points. Eligible participants explicitly generate a private QR pass; replacing a pass rotates the backend token. Operators can decode camera frames or QR image files locally, paste a pass code, or search the event participant list for manual check-in. Every attendance write requires a review and confirmation.

Migration 023 adds a bounded event-scoped directory for organizers and CHECK_IN staff without widening profile or roster policies. Players and SCORER-only accounts cannot read the directory or check in other players. Existing 017 functions enforce approved registration, payment, waivers, token expiry/rotation, event state and immutable first-check-in audit. Attendance is once per event. UI times use America/Chicago.

Verification: 192 local transactional database checks; 26 website tests including actual QR encode/decode round trip; 53 check-in checks rerun on Supabase and rolled back. Live attendance remains empty. Browser sample manual review/confirmation recorded operator, method and timestamp; scorer sample had no desk. Physical camera and two-device signed-in QR flow remain to be tested. Stripe and volleyball scoring remain deferred.

Next: run a free Texas cricket pilot with separate participant and CHECK_IN staff accounts, test phone-camera scanning and a full enrollment-to-champion rehearsal. Hosting remains owner-private until audience expansion is explicitly requested.
