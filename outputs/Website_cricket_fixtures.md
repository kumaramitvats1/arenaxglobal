# Cricket fixture setup — October 22, 2026

Cricket is the active sport scope. Volleyball scoring and Stripe checkout remain deferred.

Organizers can open **Fixtures & standings → an event → Set up cricket fixtures** after registration closes. Every approved team registration must be included exactly once. The supported format has 4–16 teams in two balanced groups of 2–8 teams. Assign groups, review all matchups, then generate the bracket.

Generation creates one Open division, Group A/Group B, group members, blank standings, one match per pair in each group, SF1 (A1/B2), SF2 (B1/A2), and FINAL. Eight teams produce 15 matches. Dates remain unset and can be scheduled using the existing match controls. The existing score-entry model treats home as first innings; toss/batting-order changes and cricket tie-break entry are not added here.

Migration 022 locks the event during setup, validates actual approved registrations, rejects non-cricket/open/completed events and existing competition setup, and returns the existing match count on an identical retry. Different group submissions cannot overwrite a bracket. An internal RLS-protected record stores the group arrays, creator and timestamp. Direct authenticated changes to divisions/groups/group members are revoked; backend functions manage composition. No automatic payment settlement is introduced.

Validation: 174 database checks passed locally and live, including 22 new setup checks and a generated eight-team tournament played through to champion/completion. All 23 web tests and the build passed. Browser sample checks covered assignment, preview and generation. The Frisco Cricket Invitational sample uses four Texas teams and saves only in memory. Existing live events/matches/standings checksums are unchanged; no live fixture setup was created.

Limitations: no real multi-account browser generation or concurrent-client stress test; no bracket reset/regeneration, alternate formats, toss support or third-place match. Remaining cricket work includes QR passes/check-in screens, tie-break/result correction design, and final multi-role launch testing. Hosting remains owner-private.
