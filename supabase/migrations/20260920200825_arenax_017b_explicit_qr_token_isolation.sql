create policy "No direct client access to QR token storage"
on arenax_private.check_in_tokens as restrictive for all to anon, authenticated
using (false) with check (false);
