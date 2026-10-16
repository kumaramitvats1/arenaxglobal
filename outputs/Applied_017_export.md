# Applied Migration 017 — database export

Applied to arenax-dev as 20260920200524. This is an export for review; do not rerun on the existing database.

```sql

create schema arenax_private;
revoke all on schema arenax_private from public, anon;
grant usage on schema arenax_private to authenticated;

create table public.event_check_ins (
 id uuid primary key default gen_random_uuid(),
 event_id uuid not null references public.events(id),
 participant_user_id uuid not null references public.profiles(id),
 registration_id uuid not null references public.registrations(id),
 team_member_id uuid references public.team_members(id),
 attendance_status text not null default 'PRESENT' check (attendance_status = 'PRESENT'),
 check_in_method text not null check (check_in_method in ('MANUAL','QR')),
 checked_in_by uuid not null references public.profiles(id),
 checked_in_at timestamptz not null default clock_timestamp(),
 unique (event_id, participant_user_id)
);
create index event_check_ins_participant_idx on public.event_check_ins(participant_user_id);
create index event_check_ins_registration_idx on public.event_check_ins(registration_id);
create index event_check_ins_member_idx on public.event_check_ins(team_member_id);
create index event_check_ins_operator_idx on public.event_check_ins(checked_in_by);
alter table public.event_check_ins enable row level security;
revoke all on public.event_check_ins from public, anon, authenticated;
grant select on public.event_check_ins to authenticated;

create table arenax_private.check_in_tokens (
 event_id uuid not null references public.events(id),
 participant_user_id uuid not null references public.profiles(id),
 token_hash bytea not null unique,
 issued_by uuid not null references public.profiles(id),
 issued_at timestamptz not null,
 expires_at timestamptz not null,
 consumed_at timestamptz,
 primary key(event_id,participant_user_id),
 check (expires_at > issued_at)
);
create index check_in_tokens_participant_idx on arenax_private.check_in_tokens(participant_user_id);
create index check_in_tokens_issuer_idx on arenax_private.check_in_tokens(issued_by);
alter table arenax_private.check_in_tokens enable row level security;
revoke all on arenax_private.check_in_tokens from public, anon, authenticated;

create function arenax_private.can_check_in(p_event_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
 select auth.uid() is not null
 and exists(select 1 from public.profiles where id = auth.uid() and account_status = 'ACTIVE')
 and exists(select 1 from public.events where id = p_event_id)
 and (public.can_manage_event(p_event_id) or public.has_event_staff_role(p_event_id,'CHECK_IN'));
$$;

-- Internal resolver: called only by the authorized operations below.
-- Locks the event and selected registration/roster rows for this transaction.
create function arenax_private.check_in_eligibility(p_event_id uuid, p_user_id uuid)
returns table(registration_id uuid, team_member_id uuid)
language plpgsql security definer set search_path = ''
as $$
declare v_status text; v_reg public.registrations%rowtype; v_member public.team_members%rowtype;
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
 select status into v_status from public.events where id=p_event_id for share;
 if not found or v_status in ('DRAFT','CANCELLED','COMPLETED') then
   raise exception 'Event is not open for check-in' using errcode='22023';
 end if;
 perform 1 from public.profiles where id=p_user_id and account_status='ACTIVE' for share;
 if not found then raise exception 'Participant is not active' using errcode='22023'; end if;
 -- An approved, settled individual registration, or approved team registration
 -- with an active, accepted roster membership in the SAME event.
 select r.* into v_reg from public.registrations r
 where r.event_id=p_event_id and r.registration_status='APPROVED'
 and r.payment_status in ('PAID','NOT_REQUIRED')
 and r.waiver_status in ('ACCEPTED','NOT_REQUIRED')
 and (
   (r.registration_type='INDIVIDUAL' and r.user_id=p_user_id and r.team_id is null)
   or (r.registration_type='TEAM' and exists(
      select 1 from public.teams t join public.team_members tm on tm.team_id=t.id
      where t.id=r.team_id and t.event_id=p_event_id
        and t.approval_status='APPROVED' and t.registration_status='APPROVED'
        and tm.user_id=p_user_id and tm.status='ACTIVE' and tm.invitation_status='ACCEPTED'
   ))
 )
 order by r.created_at,r.id limit 1 for share of r;
 if not found then raise exception 'Approved registration, payment and roster eligibility required' using errcode='22023'; end if;
 if v_reg.registration_type='TEAM' then
   perform 1 from public.teams where id=v_reg.team_id and event_id=p_event_id
    and approval_status='APPROVED' and registration_status='APPROVED' for share;
   if not found then raise exception 'Team is not approved' using errcode='22023'; end if;
   select * into v_member from public.team_members
    where team_id=v_reg.team_id and user_id=p_user_id
     and status='ACTIVE' and invitation_status='ACCEPTED'
    order by created_at,id limit 1 for share;
   if not found then raise exception 'Active accepted roster membership required' using errcode='22023'; end if;
 end if;
 -- Check actual versioned acceptance records, not a client-supplied flag.
 if exists (
   select 1 from public.waivers w where w.event_id=p_event_id and w.active
    and w.effective_at <= statement_timestamp()
    and not exists(select 1 from public.waiver_acceptances wa
      where wa.waiver_id=w.id and wa.user_id=p_user_id)
 ) then raise exception 'Participant must accept the active event waiver' using errcode='22023'; end if;
 return query select v_reg.id,v_member.id;
end;
$$;

create function arenax_private.issue_check_in_qr(p_event_id uuid,p_user_id uuid)
returns table(qr_token text,expires_at timestamptz)
language plpgsql security definer set search_path = ''
as $$
declare v_token text; v_now timestamptz := clock_timestamp();
begin
 if auth.uid() is null or not exists(
   select 1 from public.profiles where id=auth.uid() and account_status='ACTIVE'
 ) or (auth.uid() <> p_user_id and not arenax_private.can_check_in(p_event_id)) then
   raise exception 'Not authorized to issue this QR' using errcode='42501';
 end if;
 perform pg_advisory_xact_lock(hashtextextended(p_event_id::text || ':' || p_user_id::text,0));
 perform * from arenax_private.check_in_eligibility(p_event_id,p_user_id);
 if exists(select 1 from public.event_check_ins where event_id=p_event_id and participant_user_id=p_user_id) then
   raise exception 'Participant is already checked in' using errcode='22023';
 end if;
 v_token := encode(extensions.gen_random_bytes(32),'hex');
 insert into arenax_private.check_in_tokens
   (event_id,participant_user_id,token_hash,issued_by,issued_at,expires_at)
 values(p_event_id,p_user_id,extensions.digest(v_token,'sha256'),auth.uid(),v_now,v_now+interval '24 hours')
 on conflict(event_id,participant_user_id) do update
 set token_hash=excluded.token_hash,issued_by=excluded.issued_by,
 issued_at=excluded.issued_at,expires_at=excluded.expires_at,consumed_at=null;
 return query select v_token,v_now+interval '24 hours';
end;
$$;

create function arenax_private.check_in_participant(
 p_event_id uuid,p_user_id uuid,p_method text,p_qr_token text)
returns public.event_check_ins
language plpgsql security definer set search_path = ''
as $$
declare v_eligible record; v_result public.event_check_ins%rowtype; v_token arenax_private.check_in_tokens%rowtype;
begin
 if not arenax_private.can_check_in(p_event_id) then
   raise exception 'Only event organizers or CHECK_IN staff can check in participants' using errcode='42501';
 end if;
 if p_method is null or p_method not in ('MANUAL','QR') or p_user_id is null then
   raise exception 'Valid participant and MANUAL or QR method required' using errcode='22023';
 end if;
 if p_method='MANUAL' and p_qr_token is not null then
   raise exception 'Manual check-in does not accept a QR token' using errcode='22023';
 end if;
 perform pg_advisory_xact_lock(hashtextextended(p_event_id::text || ':' || p_user_id::text,0));
 select * into v_eligible from arenax_private.check_in_eligibility(p_event_id,p_user_id);
 if p_method='QR' then
   if p_qr_token is null or length(p_qr_token)<>64 then
     raise exception 'Invalid or expired QR' using errcode='22023';
   end if;
   select * into v_token from arenax_private.check_in_tokens
   where event_id=p_event_id and participant_user_id=p_user_id
    and token_hash=extensions.digest(p_qr_token,'sha256') for update;
   if not found or v_token.expires_at <= clock_timestamp() then
     raise exception 'Invalid or expired QR' using errcode='22023';
   end if;
 end if;
 select * into v_result from public.event_check_ins
 where event_id=p_event_id and participant_user_id=p_user_id;
 if found then return v_result; end if; -- retries preserve the original audit fields
 if p_method='QR' and v_token.consumed_at is not null then
   raise exception 'QR has already been consumed' using errcode='22023';
 end if;
 insert into public.event_check_ins
   (event_id,participant_user_id,registration_id,team_member_id,check_in_method,checked_in_by)
 values(p_event_id,p_user_id,v_eligible.registration_id,v_eligible.team_member_id,p_method,auth.uid())
 returning * into v_result;
 update arenax_private.check_in_tokens set consumed_at=v_result.checked_in_at
 where event_id=p_event_id and participant_user_id=p_user_id;
 return v_result;
end;
$$;

-- Public API functions are invokers; privileged implementations are private.
create function public.can_check_in_event(p_event_id uuid)
returns boolean language sql stable security invoker set search_path = ''
as $$ select arenax_private.can_check_in(p_event_id); $$;
create function public.issue_event_check_in_qr(p_event_id uuid,p_participant_user_id uuid)
returns table(qr_token text,expires_at timestamptz)
language sql security invoker set search_path = ''
as $$ select * from arenax_private.issue_check_in_qr(p_event_id,p_participant_user_id); $$;
create function public.check_in_event_participant(
 p_event_id uuid,p_participant_user_id uuid,p_method text default 'MANUAL',p_qr_token text default null)
returns public.event_check_ins language sql security invoker set search_path = ''
as $$ select arenax_private.check_in_participant(p_event_id,p_participant_user_id,p_method,p_qr_token); $$;

revoke all on all functions in schema arenax_private from public,anon,authenticated;
grant execute on function arenax_private.can_check_in(uuid) to authenticated;
grant execute on function arenax_private.issue_check_in_qr(uuid,uuid) to authenticated;
grant execute on function arenax_private.check_in_participant(uuid,uuid,text,text) to authenticated;
revoke all on function public.can_check_in_event(uuid) from public,anon,authenticated;
revoke all on function public.issue_event_check_in_qr(uuid,uuid) from public,anon,authenticated;
revoke all on function public.check_in_event_participant(uuid,uuid,text,text) from public,anon,authenticated;
grant execute on function public.can_check_in_event(uuid) to authenticated;
grant execute on function public.issue_event_check_in_qr(uuid,uuid) to authenticated;
grant execute on function public.check_in_event_participant(uuid,uuid,text,text) to authenticated;

create policy "Participants and check-in operators can read attendance"
 on public.event_check_ins for select to authenticated
 using(participant_user_id=(select auth.uid()) or arenax_private.can_check_in(event_id));

comment on table public.event_check_ins is
 'One immutable presence record per participant/event. No row means not checked in, not an asserted absence. Writes only through the authorized check-in function.';

```

## 017B — explicit token isolation

Applied as 20260920200825.

```sql
create policy "No direct client access to QR token storage"
on arenax_private.check_in_tokens as restrictive for all to anon, authenticated
using (false) with check (false);
```
