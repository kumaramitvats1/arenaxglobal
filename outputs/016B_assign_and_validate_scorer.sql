-- ArenaX Global: 016B. Run in the project's Supabase SQL Editor.
-- Atomic: any missing fixture or failed assertion rolls back the assignment.
-- User-approved conversion: Hotmail test captain becomes a scorer.
-- Existing migrations, tournament results and roster membership are preserved.
begin;

do $$
declare
  v_event uuid;
  v_bihar uuid;
  v_jharkhand uuid;
begin
  select id into strict v_event from public.events
  where event_name = 'ArenaX India States Cricket Cup 2027';
  select id into strict v_bihar from public.teams
  where event_id = v_event and team_name = 'Bihar';
  select id into strict v_jharkhand from public.teams
  where event_id = v_event and team_name = 'Jharkhand';

  if not exists (
    select 1 from auth.users u join public.profiles p on p.id = u.id
    where u.id = 'a289ed2b-99c9-4aad-affc-d3ca89ebcfbb'
      and u.email = 'kumaramitvats@hotmail.com'
      and p.account_status = 'ACTIVE'
  ) then
    raise exception 'Expected active Hotmail auth user and profile not found';
  end if;

  update public.teams set captain_user_id = null, updated_at = now()
  where id = v_bihar and captain_user_id = 'a289ed2b-99c9-4aad-affc-d3ca89ebcfbb';
  update public.user_roles set status = 'INACTIVE'
  where user_id = 'a289ed2b-99c9-4aad-affc-d3ca89ebcfbb'
    and team_id = v_bihar and role = 'CAPTAIN' and status = 'ACTIVE';
  update public.team_members set team_role = 'PLAYER', updated_at = now()
  where user_id = 'a289ed2b-99c9-4aad-affc-d3ca89ebcfbb'
    and team_id = v_bihar and team_role = 'CAPTAIN';

  insert into public.event_staff_assignments
    (event_id, user_id, staff_role, status, notes)
  values
    (v_event, 'a289ed2b-99c9-4aad-affc-d3ca89ebcfbb',
     'SCORER', 'CONFIRMED', 'ArenaX development test scorer')
  on conflict (event_id, user_id, staff_role)
  do update set status = 'CONFIRMED', updated_at = now();

  perform set_config('arenax.test_event', v_event::text, true);
  perform set_config('arenax.test_bihar', v_bihar::text, true);
  perform set_config('arenax.test_jharkhand', v_jharkhand::text, true);
end;
$$;

select set_config('request.jwt.claim.sub', 'a289ed2b-99c9-4aad-affc-d3ca89ebcfbb', true);
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config('request.jwt.claims', '{"sub":"a289ed2b-99c9-4aad-affc-d3ca89ebcfbb","role":"authenticated"}', true);
set local role authenticated;

do $$
declare
  v_event uuid := current_setting('arenax.test_event')::uuid;
begin
  if auth.uid() is distinct from 'a289ed2b-99c9-4aad-affc-d3ca89ebcfbb'::uuid
     or public.is_event_staff(v_event) is distinct from true
     or public.has_event_staff_role(v_event, 'SCORER') is distinct from true
     or public.can_manage_event(v_event) is distinct from false
     or public.is_super_admin() is distinct from false
     or public.has_event_staff_role(v_event, 'CHECK_IN') is distinct from false
     or public.is_team_captain(current_setting('arenax.test_bihar')::uuid) is distinct from false
     or public.is_team_captain(current_setting('arenax.test_jharkhand')::uuid) is distinct from false
  then
    raise exception '016B permission validation failed; assignment rolled back. Inspect existing roles before retrying.';
  end if;

  if (select count(*) from public.event_staff_assignments
      where event_id = v_event and user_id = auth.uid()
        and staff_role = 'SCORER' and status = 'CONFIRMED') <> 1 then
    raise exception '016B own assignment RLS visibility failed';
  end if;
end;
$$;

select
  auth.uid() as test_user,
  public.is_event_staff(current_setting('arenax.test_event')::uuid) as is_event_staff,
  public.has_event_staff_role(current_setting('arenax.test_event')::uuid, 'SCORER') as is_scorer,
  public.can_manage_event(current_setting('arenax.test_event')::uuid) as can_manage_event,
  public.is_super_admin() as is_super_admin,
  public.has_event_staff_role(current_setting('arenax.test_event')::uuid, 'CHECK_IN') as is_check_in_staff,
  public.is_team_captain(current_setting('arenax.test_bihar')::uuid) as is_bihar_captain,
  public.is_team_captain(current_setting('arenax.test_jharkhand')::uuid) as is_jharkhand_captain;

commit;
