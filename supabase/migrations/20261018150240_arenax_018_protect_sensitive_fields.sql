-- ArenaX 018: database-enforced protection of administrative fields.
-- No role model, tournament result, or existing migration is removed.
create function arenax_private.is_active_user()
returns boolean language sql stable security definer set search_path = ''
as $$ select auth.uid() is not null and exists(
 select 1 from public.profiles where id=auth.uid() and account_status='ACTIVE'
); $$;
revoke all on function arenax_private.is_active_user() from public,anon,authenticated;
grant execute on function arenax_private.is_active_user() to authenticated;

CREATE OR REPLACE FUNCTION public.is_super_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select arenax_private.is_active_user() and (exists (
        select 1
        from public.user_roles ur
        where ur.user_id = auth.uid()
          and ur.role = 'SUPER_ADMIN'
          and ur.status = 'ACTIVE'
    ));
$function$
;

CREATE OR REPLACE FUNCTION public.is_organizer(p_organization_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select arenax_private.is_active_user() and (public.is_super_admin()
        or exists (
            select 1
            from public.user_roles ur
            where ur.user_id = auth.uid()
              and ur.organization_id = p_organization_id
              and ur.role = 'ORGANIZER'
              and ur.status = 'ACTIVE'
        ));
$function$
;

CREATE OR REPLACE FUNCTION public.has_event_role(p_event_id uuid, p_role text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select arenax_private.is_active_user() and (public.is_super_admin()
        or exists (
            select 1
            from public.user_roles ur
            where ur.user_id = auth.uid()
              and ur.event_id = p_event_id
              and ur.role = p_role
              and ur.status = 'ACTIVE'
        ));
$function$
;

CREATE OR REPLACE FUNCTION public.can_manage_event(p_event_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select arenax_private.is_active_user() and (public.is_super_admin()
        or exists (
            select 1
            from public.events e
            join public.user_roles ur
              on ur.organization_id = e.organization_id
            where e.id = p_event_id
              and ur.user_id = auth.uid()
              and ur.role = 'ORGANIZER'
              and ur.status = 'ACTIVE'
        ));
$function$
;

CREATE OR REPLACE FUNCTION public.is_team_captain(p_team_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select arenax_private.is_active_user() and (public.is_super_admin()
        or exists (
            select 1
            from public.teams t
            where t.id = p_team_id
              and t.captain_user_id = auth.uid()
        )
        or exists (
            select 1
            from public.user_roles ur
            where ur.user_id = auth.uid()
              and ur.team_id = p_team_id
              and ur.role = 'CAPTAIN'
              and ur.status = 'ACTIVE'
        ));
$function$
;

CREATE OR REPLACE FUNCTION public.is_event_staff(p_event_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select arenax_private.is_active_user() and (public.is_super_admin()

        or exists (

            select 1

            from public.event_staff_assignments esa

            where esa.event_id = p_event_id

              and esa.user_id = auth.uid()

              and esa.status in (
                  'ASSIGNED',
                  'CONFIRMED'
              )
        ));
$function$
;

CREATE OR REPLACE FUNCTION public.has_event_staff_role(p_event_id uuid, p_staff_role text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
 select arenax_private.is_active_user() and (public.is_super_admin()

        or exists (

            select 1

            from public.event_staff_assignments esa

            where esa.event_id = p_event_id

              and esa.user_id = auth.uid()

              and esa.staff_role = p_staff_role

              and esa.status in (
                  'ASSIGNED',
                  'CONFIRMED'
              )
        ));
$function$
;


-- Invoker triggers see the actual database role. Trusted server SQL and
-- authorization-checked SECURITY DEFINER operations retain maintenance access.
-- An ordinary JWT cannot change current_user to postgres/service_role.
create function arenax_private.protect_profile_fields()
returns trigger language plpgsql security invoker set search_path = ''
as $$
begin
 if current_user in ('postgres','service_role','supabase_admin') then return new; end if;
 if auth.uid() is null or not arenax_private.is_active_user() then
  raise exception 'Active account required' using errcode='42501';
 end if;
 if new.id is distinct from old.id or new.created_at is distinct from old.created_at then
  raise exception 'Profile identity and creation time are immutable' using errcode='42501';
 end if;
 if new.account_status is distinct from old.account_status and not public.is_super_admin() then
  raise exception 'Only Super Admin can change account status' using errcode='42501';
 end if;
 new.updated_at := clock_timestamp();
 return new;
end; $$;
create trigger protect_profile_fields before update on public.profiles
for each row execute function arenax_private.protect_profile_fields();

create function arenax_private.protect_registration_fields()
returns trigger language plpgsql security invoker set search_path = ''
as $$
declare v_event public.events%rowtype; v_players integer; v_due numeric;
begin
 if current_user in ('postgres','service_role','supabase_admin') then return new; end if;
 if auth.uid() is null or not arenax_private.is_active_user() then
  raise exception 'Active account required' using errcode='42501';
 end if;
 if tg_op='UPDATE' and
  (new.id,new.event_id,new.user_id,new.team_id,new.registration_type,new.created_at)
  is distinct from
  (old.id,old.event_id,old.user_id,old.team_id,old.registration_type,old.created_at) then
  raise exception 'Registration identity is immutable' using errcode='42501';
 end if;
 -- Organizers are authorized on the unchanged event. RLS still applies.
 if public.can_manage_event(new.event_id) then
  new.updated_at := clock_timestamp();
  return new;
 end if;
 if tg_op='INSERT' then
  if new.registration_status not in ('DRAFT','SUBMITTED')
    or new.payment_status not in ('PENDING','NOT_REQUIRED')
    or new.waiver_status not in ('PENDING','NOT_REQUIRED')
    or new.amount_paid <> 0 then
   raise exception 'Cannot create an approved or paid registration' using errcode='42501';
  end if;
  select * into strict v_event from public.events where id=new.event_id;
  v_due := v_event.registration_fee;
  if v_event.pricing_model='FREE' then v_due:=0;
  elsif new.registration_type='TEAM' and v_event.pricing_model='PER_PLAYER' then
   select count(*) into v_players from public.team_members
    where team_id=new.team_id and status='ACTIVE' and invitation_status='ACCEPTED';
   if v_players=0 then raise exception 'Accepted roster required for per-player team pricing' using errcode='22023'; end if;
   v_due:=v_due*v_players;
  end if;
  new.amount_due:=v_due;
  new.amount_paid:=0;
  new.payment_status:=case when v_due=0 then 'NOT_REQUIRED' else 'PENDING' end;
  -- A registration summary cannot substitute for versioned acceptance.
  new.waiver_status:='PENDING';
  new.created_at:=clock_timestamp();
  new.registered_at:=case when new.registration_status='SUBMITTED' then clock_timestamp() else null end;
 else
  if (new.payment_status,new.waiver_status,new.amount_due,new.amount_paid,new.registered_at)
    is distinct from
    (old.payment_status,old.waiver_status,old.amount_due,old.amount_paid,old.registered_at) then
   raise exception 'Only event managers can update registration financial and verification fields' using errcode='42501';
  end if;
  if new.registration_status is distinct from old.registration_status then
   if not ((old.registration_status='DRAFT' and new.registration_status='SUBMITTED')
      or (old.registration_status in ('DRAFT','SUBMITTED','WAITLISTED','APPROVED') and new.registration_status='CANCELLED')) then
    raise exception 'Only event managers can approve, reject, waitlist or reopen registrations' using errcode='42501';
   end if;
   if new.registration_status='SUBMITTED' then new.registered_at:=clock_timestamp(); end if;
  end if;
 end if;
 new.updated_at:=clock_timestamp();
 return new;
end; $$;
create trigger protect_registration_fields before insert or update on public.registrations
for each row execute function arenax_private.protect_registration_fields();

-- Prevent captains from bypassing registration approval through the team row.
create function arenax_private.protect_team_fields()
returns trigger language plpgsql security invoker set search_path = ''
as $$
begin
 if current_user in ('postgres','service_role','supabase_admin') then return new; end if;
 if auth.uid() is null or not arenax_private.is_active_user() then
  raise exception 'Active account required' using errcode='42501';
 end if;
 if (new.id,new.event_id,new.created_at) is distinct from (old.id,old.event_id,old.created_at) then
  raise exception 'Team identity is immutable' using errcode='42501';
 end if;
 if not public.can_manage_event(old.event_id) then
  if (new.captain_user_id,new.manager_user_id,new.approval_status,new.payment_status)
    is distinct from (old.captain_user_id,old.manager_user_id,old.approval_status,old.payment_status) then
   raise exception 'Only event managers can change team leadership, approval or payment' using errcode='42501';
  end if;
  if new.registration_status is distinct from old.registration_status and
    not (old.registration_status='DRAFT' and new.registration_status='SUBMITTED') then
   raise exception 'Only event managers can review team registration' using errcode='42501';
  end if;
 end if;
 new.updated_at:=clock_timestamp();
 return new;
end; $$;
create trigger protect_team_fields before update on public.teams
for each row execute function arenax_private.protect_team_fields();

revoke all on function arenax_private.protect_profile_fields() from public,anon,authenticated;
revoke all on function arenax_private.protect_registration_fields() from public,anon,authenticated;
revoke all on function arenax_private.protect_team_fields() from public,anon,authenticated;

-- Super Admin needs a legitimate path to administer accounts.
create policy "Super Admin can view profiles" on public.profiles for select to authenticated
using(public.is_super_admin());
create policy "Super Admin can update profiles" on public.profiles for update to authenticated
using(public.is_super_admin()) with check(public.is_super_admin());

-- No unrestricted SQL maintenance privileges for application users.
revoke all on table public.group_members from public, anon;
revoke truncate, references, trigger, maintain on table public.group_members from authenticated;
revoke all on table public.match_results from public, anon;
revoke truncate, references, trigger, maintain on table public.match_results from authenticated;
revoke all on table public.venues from public, anon;
revoke truncate, references, trigger, maintain on table public.venues from authenticated;
revoke all on table public.standings from public, anon;
revoke truncate, references, trigger, maintain on table public.standings from authenticated;
revoke all on table public.sports from public, anon;
revoke truncate, references, trigger, maintain on table public.sports from authenticated;
revoke all on table public.profiles from public, anon;
revoke truncate, references, trigger, maintain on table public.profiles from authenticated;
revoke all on table public.playing_areas from public, anon;
revoke truncate, references, trigger, maintain on table public.playing_areas from authenticated;
revoke all on table public.organizations from public, anon;
revoke truncate, references, trigger, maintain on table public.organizations from authenticated;
revoke all on table public.cricket_innings from public, anon;
revoke truncate, references, trigger, maintain on table public.cricket_innings from authenticated;
revoke all on table public.waiver_acceptances from public, anon;
revoke truncate, references, trigger, maintain on table public.waiver_acceptances from authenticated;
revoke all on table public.team_members from public, anon;
revoke truncate, references, trigger, maintain on table public.team_members from authenticated;
revoke all on table public.matches from public, anon;
revoke truncate, references, trigger, maintain on table public.matches from authenticated;
revoke all on table public.event_check_ins from public, anon;
revoke truncate, references, trigger, maintain on table public.event_check_ins from authenticated;
revoke all on table public.groups from public, anon;
revoke truncate, references, trigger, maintain on table public.groups from authenticated;
revoke all on table public.user_roles from public, anon;
revoke truncate, references, trigger, maintain on table public.user_roles from authenticated;
revoke all on table public.match_assignments from public, anon;
revoke truncate, references, trigger, maintain on table public.match_assignments from authenticated;
revoke all on table public.registrations from public, anon;
revoke truncate, references, trigger, maintain on table public.registrations from authenticated;
revoke all on table public.event_staff_assignments from public, anon;
revoke truncate, references, trigger, maintain on table public.event_staff_assignments from authenticated;
revoke all on table public.teams from public, anon;
revoke truncate, references, trigger, maintain on table public.teams from authenticated;
revoke all on table public.events from public, anon;
revoke truncate, references, trigger, maintain on table public.events from authenticated;
revoke all on table public.divisions from public, anon;
revoke truncate, references, trigger, maintain on table public.divisions from authenticated;
revoke all on table public.waivers from public, anon;
revoke truncate, references, trigger, maintain on table public.waivers from authenticated;
revoke all on table public.payments from public, anon;
revoke truncate, references, trigger, maintain on table public.payments from authenticated;

-- Explicitly remove grants inherited from the old Supabase defaults.
revoke all on function public.is_super_admin() from public, anon;
revoke all on function public.is_organizer(p_organization_id uuid) from public, anon;
revoke all on function public.has_event_role(p_event_id uuid, p_role text) from public, anon;
revoke all on function public.can_manage_event(p_event_id uuid) from public, anon;
revoke all on function public.is_team_captain(p_team_id uuid) from public, anon;
revoke all on function public.handle_new_user() from public, anon;
revoke all on function public.handle_new_user() from authenticated;
revoke all on function public.validate_match_schedule() from public, anon;
revoke all on function public.validate_match_schedule() from authenticated;
revoke all on function public.recalculate_cricket_standings(p_group_id uuid) from public, anon;
revoke all on function public.recalculate_cricket_standings(p_group_id uuid) from authenticated;
revoke all on function public.record_cricket_result(p_match_id uuid, p_home_runs integer, p_home_wickets integer, p_home_balls integer, p_away_runs integer, p_away_wickets integer, p_away_balls integer, p_max_balls integer) from public, anon;
revoke all on function public.resolve_semifinalists(p_event_id uuid) from public, anon;
revoke all on function public.resolve_finalists(p_event_id uuid) from public, anon;
revoke all on function public.handle_knockout_advancement() from public, anon;
revoke all on function public.handle_knockout_advancement() from authenticated;
revoke all on function public.complete_tournament(p_event_id uuid) from public, anon;
revoke all on function public.is_event_staff(p_event_id uuid) from public, anon;
revoke all on function public.has_event_staff_role(p_event_id uuid, p_staff_role text) from public, anon;
revoke all on function public.can_check_in_event(p_event_id uuid) from public, anon;
revoke all on function public.issue_event_check_in_qr(p_event_id uuid, p_participant_user_id uuid) from public, anon;
revoke all on function public.check_in_event_participant(p_event_id uuid, p_participant_user_id uuid, p_method text, p_qr_token text) from public, anon;

-- New RPCs must explicitly grant access rather than inheriting public execution.
alter default privileges for role postgres revoke execute on functions from public;
alter default privileges for role postgres in schema public revoke execute on functions from anon, authenticated;
notify pgrst, 'reload schema';
