-- Cricket-only setup for the established two-group tournament engine.
create table arenax_private.cricket_fixture_setups (
 event_id uuid primary key references public.events(id),
 group_a uuid[] not null,
 group_b uuid[] not null,
 match_count integer not null,
 created_by uuid not null references public.profiles(id),
 created_at timestamptz not null default now()
);
alter table arenax_private.cricket_fixture_setups enable row level security;
revoke all on arenax_private.cricket_fixture_setups from public,anon,authenticated;
grant all on arenax_private.cricket_fixture_setups to service_role;
-- Group composition and standings must stay consistent with generated fixtures.
revoke insert,update,delete on public.divisions,public.groups,public.group_members from authenticated;

create function arenax_private.generate_cricket_fixtures(p_event uuid,p_group_a uuid[],p_group_b uuid[])
returns integer language plpgsql security definer set search_path='' as $$
declare e public.events; previous arenax_private.cricket_fixture_setups; all_teams uuid[];
 approved uuid[]; d uuid; g uuid; roster uuid[]; group_index integer; i integer; j integer; n integer:=0; t uuid;
begin
 if auth.uid() is null or not public.can_manage_event(p_event) then
  raise exception 'Event organizer permission required' using errcode='42501';
 end if;
 select * into e from public.events where id=p_event for update;
 if not found or e.status<>'REGISTRATION_CLOSED' or e.registration_type not in ('TEAM','BOTH') or
   not exists(select 1 from public.sports where id=e.sport_id and lower(name)='cricket') then
  raise exception 'Close registration on a team cricket event before creating fixtures' using errcode='22023';
 end if;
 if coalesce(array_ndims(p_group_a),0)<>1 or coalesce(array_ndims(p_group_b),0)<>1 or
    array_lower(p_group_a,1)<>1 or array_lower(p_group_b,1)<>1 or
    cardinality(p_group_a) not between 2 and 8 or cardinality(p_group_b) not between 2 and 8 or
    abs(cardinality(p_group_a)-cardinality(p_group_b))>1 then
  raise exception 'Use two balanced groups of 2 to 8 teams each' using errcode='22023';
 end if;
 all_teams:=p_group_a||p_group_b;
 if (select count(distinct x) from unnest(all_teams) x)<>cardinality(all_teams) then
  raise exception 'Every team must appear exactly once; empty team entries are invalid' using errcode='22023';
 end if;
 select * into previous from arenax_private.cricket_fixture_setups where event_id=p_event;
 if found then
  if previous.group_a=p_group_a and previous.group_b=p_group_b then return previous.match_count; end if;
  raise exception 'Fixtures already exist. Group assignments are locked' using errcode='22023';
 end if;
 if exists(select 1 from public.matches where event_id=p_event) or exists(select 1 from public.divisions where event_id=p_event) then
  raise exception 'This event already has competition setup; existing fixtures will not be replaced' using errcode='22023';
 end if;
 -- Lock approvals while taking the eligibility snapshot. Enrollment operations also lock the event first.
 perform 1 from public.registrations where event_id=p_event order by id for share;
 select array_agg(distinct r.team_id order by r.team_id) into approved
 from public.registrations r join public.teams t on t.id=r.team_id and t.event_id=r.event_id
 where r.event_id=p_event and r.registration_type='TEAM' and r.registration_status='APPROVED';
 if approved is null or cardinality(approved)<>cardinality(all_teams) or not approved @> all_teams then
  raise exception 'Assign every approved registered team exactly once; refresh if approvals changed' using errcode='22023';
 end if;
 insert into public.divisions(event_id,name,competition_type) values(p_event,'Open','TEAM') returning id into d;
 for group_index in 1..2 loop
  roster:=case when group_index=1 then p_group_a else p_group_b end;
  insert into public.groups(division_id,name,sort_order) values(d,case when group_index=1 then 'Group A' else 'Group B' end,group_index) returning id into g;
  for i in 1..cardinality(roster) loop
   t:=roster[i];
   insert into public.group_members(group_id,team_id,seed_number) values(g,t,i);
   insert into public.standings(group_id,team_id) values(g,t);
   for j in i+1..cardinality(roster) loop
    n:=n+1;
    insert into public.matches(event_id,division_id,group_id,match_number,match_code,stage,home_team_id,away_team_id,status)
    values(p_event,d,g,n,'M'||lpad(n::text,2,'0'),'GROUP',t,roster[j],'DRAFT');
   end loop;
  end loop;
 end loop;
 insert into public.matches(event_id,division_id,match_number,match_code,stage,status,home_source_type,home_source_ref,away_source_type,away_source_ref)
 values(p_event,d,n+1,'SF1','SEMIFINAL','DRAFT','GROUP_POSITION','A1','GROUP_POSITION','B2'),
       (p_event,d,n+2,'SF2','SEMIFINAL','DRAFT','GROUP_POSITION','B1','GROUP_POSITION','A2'),
       (p_event,d,n+3,'FINAL','FINAL','DRAFT','MATCH_WINNER','SF1','MATCH_WINNER','SF2');
 insert into arenax_private.cricket_fixture_setups(event_id,group_a,group_b,match_count,created_by)
 values(p_event,p_group_a,p_group_b,n+3,auth.uid());
 return n+3;
end; $$;
create function public.generate_cricket_fixtures(p_event uuid,p_group_a uuid[],p_group_b uuid[])
returns integer language sql security invoker set search_path='' as $$
 select arenax_private.generate_cricket_fixtures(p_event,p_group_a,p_group_b);
$$;
revoke all on function public.generate_cricket_fixtures(uuid,uuid[],uuid[]),arenax_private.generate_cricket_fixtures(uuid,uuid[],uuid[]) from public,anon,authenticated;
grant execute on function public.generate_cricket_fixtures(uuid,uuid[],uuid[]),arenax_private.generate_cricket_fixtures(uuid,uuid[],uuid[]) to authenticated;
notify pgrst,'reload schema';
