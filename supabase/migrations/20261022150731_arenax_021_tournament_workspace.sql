-- ArenaX 021: tournament workspace. Existing records and scoring rules are preserved.
-- Serialize tournament operations on the event before locking individual matches.
-- Application writes must use guarded RPCs; direct score/fixture edits are revoked.
revoke insert,update,delete on public.matches,public.match_results,public.cricket_innings,public.standings from authenticated;
create trigger tournament_schedule_guard before insert or update of scheduled_start,scheduled_end,playing_area_id,home_team_id,away_team_id
on public.matches for each row execute function public.validate_match_schedule();
CREATE OR REPLACE FUNCTION arenax_private.record_cricket_result(p_match_id uuid, p_home_runs integer, p_home_wickets integer, p_home_balls integer, p_away_runs integer, p_away_wickets integer, p_away_balls integer, p_max_balls integer DEFAULT 48)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
    v_match public.matches%rowtype;
    p_event_id uuid;
    v_winner uuid;
    v_loser uuid;
    v_result_type text;
    v_result_summary text;
begin
    select event_id into p_event_id from public.matches where id=p_match_id;
    if auth.uid() is null or not arenax_private.is_active_user() then
      raise exception 'Active account required' using errcode='42501';
    end if;
    perform 1 from public.events where id=p_event_id for update;
    if not exists(select 1 from public.events e join public.sports s on s.id=e.sport_id
      where e.id=p_event_id and e.status='IN_PROGRESS' and lower(s.name)='cricket') then
      raise exception 'An in-progress cricket tournament is required' using errcode='22023';
    end if;
    select *
    into v_match
    from public.matches
    where id = p_match_id for update;
    if not found then
        raise exception 'Match not found';
    end if;
    if not (public.can_manage_event(v_match.event_id) or public.has_event_staff_role(v_match.event_id,'SCORER')) then
        raise exception
            'Not authorized to record this match result';
    end if;
    if v_match.status not in ('DRAFT','SCHEDULED','READY','IN_PROGRESS') or v_match.result_status<>'PENDING' then
      raise exception 'This result is locked or the match is unavailable' using errcode='22023';
    end if;
    if p_home_runs is null or p_home_wickets is null or p_home_balls is null or
       p_away_runs is null or p_away_wickets is null or p_away_balls is null or p_max_balls is null then
      raise exception 'Every score field is required' using errcode='22023';
    end if;
    if p_home_runs>100000 or p_away_runs>100000 or p_max_balls>600 then
      raise exception 'Score exceeds supported limits' using errcode='22023';
    end if;
    if not exists(select 1 from public.teams where id=v_match.home_team_id and event_id=p_event_id) or
       not exists(select 1 from public.teams where id=v_match.away_team_id and event_id=p_event_id) then
      raise exception 'Both teams must belong to this event' using errcode='22023';
    end if;
    if v_match.stage not in (
        'GROUP',
        'SEMIFINAL',
        'FINAL',
        'THIRD_PLACE'
    ) then
        raise exception
            'Cricket result entry is not supported for stage %',
            v_match.stage;
    end if;
    if v_match.home_team_id is null
       or v_match.away_team_id is null then
        raise exception
            'Match participants have not been resolved';
    end if;
    if p_home_runs < 0
       or p_away_runs < 0 then
        raise exception 'Runs cannot be negative';
    end if;
    if p_home_wickets < 0
       or p_home_wickets > 10
       or p_away_wickets < 0
       or p_away_wickets > 10 then
        raise exception
            'Wickets must be between 0 and 10';
    end if;
    if p_home_balls <= 0
       or p_away_balls <= 0
       or p_max_balls <= 0 then
        raise exception
            'Ball counts must be greater than zero';
    end if;
    if p_home_balls > p_max_balls
       or p_away_balls > p_max_balls then
        raise exception
            'Balls faced cannot exceed maximum balls';
    end if;
    if p_home_runs > p_away_runs then
        v_winner := v_match.home_team_id;
        v_loser  := v_match.away_team_id;
        v_result_type := 'WIN';
        v_result_summary :=
            format(
                'Home team won by %s runs',
                p_home_runs - p_away_runs
            );
    elsif p_away_runs > p_home_runs then
        v_winner := v_match.away_team_id;
        v_loser  := v_match.home_team_id;
        v_result_type := 'WIN';
        v_result_summary :=
            format(
                'Away team won with %s wickets remaining',
                10 - p_away_wickets
            );
    else
        if v_match.stage <> 'GROUP' then
            raise exception
                'Knockout match cannot end in an unresolved tie';
        end if;
        v_winner := null;
        v_loser  := null;
        v_result_type := 'TIE';
        v_result_summary := 'Match tied';
    end if;
    insert into public.cricket_innings (
        match_id,
        team_id,
        innings_number,
        runs,
        wickets,
        balls_faced,
        max_balls,
        all_out
    )
    values (
        p_match_id,
        v_match.home_team_id,
        1,
        p_home_runs,
        p_home_wickets,
        p_home_balls,
        p_max_balls,
        p_home_wickets = 10
    )
    on conflict (match_id, innings_number)
    do update set
        team_id = excluded.team_id,
        runs = excluded.runs,
        wickets = excluded.wickets,
        balls_faced = excluded.balls_faced,
        max_balls = excluded.max_balls,
        all_out = excluded.all_out,
        updated_at = now();
    insert into public.cricket_innings (
        match_id,
        team_id,
        innings_number,
        runs,
        wickets,
        balls_faced,
        max_balls,
        all_out
    )
    values (
        p_match_id,
        v_match.away_team_id,
        2,
        p_away_runs,
        p_away_wickets,
        p_away_balls,
        p_max_balls,
        p_away_wickets = 10
    )
    on conflict (match_id, innings_number)
    do update set
        team_id = excluded.team_id,
        runs = excluded.runs,
        wickets = excluded.wickets,
        balls_faced = excluded.balls_faced,
        max_balls = excluded.max_balls,
        all_out = excluded.all_out,
        updated_at = now();
    insert into public.match_results (
        match_id,
        winner_team_id,
        loser_team_id,
        result_type,
        result_summary,
        home_points,
        away_points,
        verified,
        verified_by,
        verified_at
    )
    values (
        p_match_id,
        v_winner,
        v_loser,
        v_result_type,
        v_result_summary,
        p_home_runs,
        p_away_runs,
        true,
        auth.uid(),
        now()
    )
    on conflict (match_id)
    do update set
        winner_team_id = excluded.winner_team_id,
        loser_team_id = excluded.loser_team_id,
        result_type = excluded.result_type,
        result_summary = excluded.result_summary,
        home_points = excluded.home_points,
        away_points = excluded.away_points,
        verified = true,
        verified_by = auth.uid(),
        verified_at = now(),
        updated_at = now();
    update public.matches
    set
        status = 'COMPLETED',
        result_status = 'CONFIRMED',
        winner_team_id = v_winner,
        actual_end = now(),
        updated_at = now()
    where id = p_match_id;
    if v_match.stage = 'GROUP'
       and v_match.group_id is not null then
        perform public.recalculate_cricket_standings(
            v_match.group_id
        );
    end if;
end;
$function$;

create or replace function public.record_cricket_result(p_match_id uuid, p_home_runs integer, p_home_wickets integer, p_home_balls integer, p_away_runs integer, p_away_wickets integer, p_away_balls integer, p_max_balls integer DEFAULT 48) returns void language sql security invoker set search_path='' as $$ select arenax_private.record_cricket_result(p_match_id,p_home_runs,p_home_wickets,p_home_balls,p_away_runs,p_away_wickets,p_away_balls,p_max_balls); $$;
revoke all on function public.record_cricket_result(uuid,integer,integer,integer,integer,integer,integer,integer),arenax_private.record_cricket_result(uuid,integer,integer,integer,integer,integer,integer,integer) from public,anon,authenticated;
grant execute on function public.record_cricket_result(uuid,integer,integer,integer,integer,integer,integer,integer),arenax_private.record_cricket_result(uuid,integer,integer,integer,integer,integer,integer,integer) to authenticated;
CREATE OR REPLACE FUNCTION arenax_private.resolve_semifinalists(p_event_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
    v_group_a uuid;
    v_group_b uuid;
    v_a1 uuid;
    v_a2 uuid;
    v_b1 uuid;
    v_b2 uuid;
    v_sf1 uuid;
    v_sf2 uuid;
    v_incomplete_count integer;
begin
    if auth.uid() is null or not arenax_private.is_active_user() then
      raise exception 'Active account required' using errcode='42501';
    end if;
    perform 1 from public.events where id=p_event_id for update;
    if not exists(select 1 from public.events e join public.sports s on s.id=e.sport_id
      where e.id=p_event_id and e.status='IN_PROGRESS' and lower(s.name)='cricket') then
      raise exception 'An in-progress cricket tournament is required' using errcode='22023';
    end if;
    if not public.can_manage_event(p_event_id) then
        raise exception
            'Not authorized to resolve semifinalists';
    end if;
    if exists(select 1 from public.matches where event_id=p_event_id and stage<>'GROUP'
      and (status in ('IN_PROGRESS','COMPLETED','FORFEITED') or result_status<>'PENDING' or home_team_id is not null or away_team_id is not null)) then
      raise exception 'Knockout participants are already resolved or locked' using errcode='22023';
    end if;
    select g.id
    into v_group_a
    from public.groups g
    join public.divisions d
        on d.id = g.division_id
    where d.event_id = p_event_id
      and g.name = 'Group A';
    select g.id
    into v_group_b
    from public.groups g
    join public.divisions d
        on d.id = g.division_id
    where d.event_id = p_event_id
      and g.name = 'Group B';
    if v_group_a is null
       or v_group_b is null then
        raise exception
            'Group A or Group B not found';
    end if;
    select count(*)
    into v_incomplete_count
    from public.matches m
    where m.event_id = p_event_id
      and m.stage = 'GROUP'
      and (
            m.status <> 'COMPLETED'
            or
            m.result_status <> 'CONFIRMED'
          );
    if v_incomplete_count > 0 then
        raise exception
            'Cannot resolve semifinalists: % group matches are incomplete',
            v_incomplete_count;
    end if;
    select s.team_id
    into v_a1
    from public.standings s
    where s.group_id = v_group_a
      and s.rank = 1;
    select s.team_id
    into v_a2
    from public.standings s
    where s.group_id = v_group_a
      and s.rank = 2;
    select s.team_id
    into v_b1
    from public.standings s
    where s.group_id = v_group_b
      and s.rank = 1;
    select s.team_id
    into v_b2
    from public.standings s
    where s.group_id = v_group_b
      and s.rank = 2;
    if v_a1 is null
       or v_a2 is null
       or v_b1 is null
       or v_b2 is null then
        raise exception
            'Final group rankings are incomplete';
    end if;
    select id
    into v_sf1
    from public.matches
    where event_id = p_event_id
      and match_code = 'SF1';
    select id
    into v_sf2
    from public.matches
    where event_id = p_event_id
      and match_code = 'SF2';
    if v_sf1 is null
       or v_sf2 is null then
        raise exception
            'Semifinal fixtures not found';
    end if;
    update public.matches
    set
        home_team_id = v_a1,
        away_team_id = v_b2,
        status = 'DRAFT',
        result_status = 'PENDING',
        updated_at = now()
    where id = v_sf1;
    update public.matches
    set
        home_team_id = v_b1,
        away_team_id = v_a2,
        status = 'DRAFT',
        result_status = 'PENDING',
        updated_at = now()
    where id = v_sf2;
end;
$function$;

create or replace function public.resolve_semifinalists(p_event_id uuid) returns void language sql security invoker set search_path='' as $$ select arenax_private.resolve_semifinalists(p_event_id); $$;
revoke all on function public.resolve_semifinalists(uuid),arenax_private.resolve_semifinalists(uuid) from public,anon,authenticated;
grant execute on function public.resolve_semifinalists(uuid),arenax_private.resolve_semifinalists(uuid) to authenticated;
CREATE OR REPLACE FUNCTION arenax_private.resolve_finalists(p_event_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
    v_sf1_id uuid;
    v_sf2_id uuid;
    v_final_id uuid;
    v_sf1_winner uuid;
    v_sf2_winner uuid;
begin
    if auth.uid() is null or not arenax_private.is_active_user() then
      raise exception 'Active account required' using errcode='42501';
    end if;
    perform 1 from public.events where id=p_event_id for update;
    if not exists(select 1 from public.events e join public.sports s on s.id=e.sport_id
      where e.id=p_event_id and e.status='IN_PROGRESS' and lower(s.name)='cricket') then
      raise exception 'An in-progress cricket tournament is required' using errcode='22023';
    end if;
    if exists(select 1 from public.matches where event_id=p_event_id and stage='FINAL'
      and (status in ('IN_PROGRESS','COMPLETED','FORFEITED','CANCELLED') or result_status<>'PENDING' or home_team_id is not null or away_team_id is not null)) then
      raise exception 'Final participants are already resolved or locked' using errcode='22023';
    end if;
    if not (public.can_manage_event(p_event_id) or public.has_event_staff_role(p_event_id,'SCORER')) then
        raise exception
            'Not authorized to resolve finalists';
    end if;
    select
        id,
        winner_team_id
    into
        v_sf1_id,
        v_sf1_winner
    from public.matches
    where event_id = p_event_id
      and match_code = 'SF1'
      and stage = 'SEMIFINAL';
    select
        id,
        winner_team_id
    into
        v_sf2_id,
        v_sf2_winner
    from public.matches
    where event_id = p_event_id
      and match_code = 'SF2'
      and stage = 'SEMIFINAL';
    if v_sf1_id is null
       or v_sf2_id is null then
        raise exception
            'Semifinal matches not found';
    end if;
    if not exists (
        select 1
        from public.matches
        where id = v_sf1_id
          and status = 'COMPLETED'
          and result_status = 'CONFIRMED'
    ) then
        raise exception
            'SF1 is not completed and confirmed';
    end if;
    if not exists (
        select 1
        from public.matches
        where id = v_sf2_id
          and status = 'COMPLETED'
          and result_status = 'CONFIRMED'
    ) then
        raise exception
            'SF2 is not completed and confirmed';
    end if;
    if v_sf1_winner is null
       or v_sf2_winner is null then
        raise exception
            'Both semifinals must have a winner';
    end if;
    if v_sf1_winner = v_sf2_winner then
        raise exception
            'Invalid knockout state: same team won both semifinals';
    end if;
    select id
    into v_final_id
    from public.matches
    where event_id = p_event_id
      and match_code = 'FINAL'
      and stage = 'FINAL';
    if v_final_id is null then
        raise exception
            'Final match not found';
    end if;
    if exists (
        select 1
        from public.matches
        where id = v_final_id
          and status = 'COMPLETED'
    ) then
        raise exception
            'Final is already completed';
    end if;
    update public.matches
    set
        home_team_id = v_sf1_winner,
        away_team_id = v_sf2_winner,
        home_source_type = 'MATCH_WINNER',
        home_source_ref = 'SF1',
        away_source_type = 'MATCH_WINNER',
        away_source_ref = 'SF2',
        status = 'DRAFT',
        result_status = 'PENDING',
        updated_at = now()
    where id = v_final_id;
end;
$function$;

create or replace function public.resolve_finalists(p_event_id uuid) returns void language sql security invoker set search_path='' as $$ select arenax_private.resolve_finalists(p_event_id); $$;
revoke all on function public.resolve_finalists(uuid),arenax_private.resolve_finalists(uuid) from public,anon,authenticated;
grant execute on function public.resolve_finalists(uuid),arenax_private.resolve_finalists(uuid) to authenticated;
CREATE OR REPLACE FUNCTION arenax_private.complete_tournament(p_event_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
    v_final public.matches%rowtype;
    v_unfinished_matches integer;
begin
    if auth.uid() is null or not arenax_private.is_active_user() then
      raise exception 'Active account required' using errcode='42501';
    end if;
    perform 1 from public.events where id=p_event_id for update;
    if not exists(select 1 from public.events e join public.sports s on s.id=e.sport_id
      where e.id=p_event_id and e.status='IN_PROGRESS' and lower(s.name)='cricket') then
      raise exception 'An in-progress cricket tournament is required' using errcode='22023';
    end if;
    if not public.can_manage_event(p_event_id) then
        raise exception
            'Not authorized to complete this tournament';
    end if;
    select *
    into v_final
    from public.matches
    where event_id = p_event_id
      and stage = 'FINAL';
    if not found then
        raise exception
            'Tournament Final not found';
    end if;
    if v_final.status <> 'COMPLETED'
       or v_final.result_status <> 'CONFIRMED'
       or v_final.winner_team_id is null then
        raise exception
            'Tournament cannot be completed until the Final has a confirmed winner';
    end if;
    select count(*)
    into v_unfinished_matches
    from public.matches
    where event_id = p_event_id
      and stage in (
          'GROUP',
          'ROUND_OF_32',
          'ROUND_OF_16',
          'QUARTERFINAL',
          'SEMIFINAL',
          'FINAL',
          'THIRD_PLACE'
      )
      and status not in (
          'COMPLETED',
          'CANCELLED',
          'FORFEITED'
      );
    if v_unfinished_matches > 0 then
        raise exception
            'Tournament still has % unfinished competition matches',
            v_unfinished_matches;
    end if;
    update public.events
    set
        status = 'COMPLETED',
        updated_at = now()
    where id = p_event_id;
end;
$function$;

create or replace function public.complete_tournament(p_event_id uuid) returns void language sql security invoker set search_path='' as $$ select arenax_private.complete_tournament(p_event_id); $$;
revoke all on function public.complete_tournament(uuid),arenax_private.complete_tournament(uuid) from public,anon,authenticated;
grant execute on function public.complete_tournament(uuid),arenax_private.complete_tournament(uuid) to authenticated;

create function arenax_private.tournament_control(p_event uuid,p_action text,p_data jsonb default '{}')
returns void language plpgsql security definer set search_path='' as $$
declare e public.events; m public.matches; start_at timestamptz; end_at timestamptz;
begin
 if auth.uid() is null or not public.can_manage_event(p_event) then raise exception 'Event organizer permission required' using errcode='42501'; end if;
 select * into strict e from public.events where id=p_event for update;
 if p_action='start' then
   if e.status<>'REGISTRATION_CLOSED' then raise exception 'Close registration before starting the tournament' using errcode='22023'; end if;
   if not exists(select 1 from public.matches where event_id=p_event) then raise exception 'Prepare fixtures before starting' using errcode='22023'; end if;
   update public.events set status='IN_PROGRESS',updated_at=clock_timestamp() where id=p_event;
 elsif p_action='schedule' then
   if e.status not in ('REGISTRATION_CLOSED','IN_PROGRESS') then raise exception 'Schedule matches after registration closes' using errcode='22023'; end if;
   select * into m from public.matches where id=(p_data->>'match_id')::uuid and event_id=p_event for update;
   if not found or m.status not in ('DRAFT','READY','SCHEDULED','POSTPONED') or m.result_status<>'PENDING' then raise exception 'Match cannot be scheduled' using errcode='22023'; end if;
   if m.updated_at is distinct from (p_data->>'expected_updated_at')::timestamptz then raise exception 'Match changed. Refresh before scheduling' using errcode='40001'; end if;
   -- Shared venue schedules can span events; serialize schedule changes across them.
   perform pg_advisory_xact_lock(21021,1);
   start_at:=(p_data->>'start')::timestamptz; end_at:=(p_data->>'end')::timestamptz;
   if start_at is null or end_at is null or not isfinite(start_at) or not isfinite(end_at) or end_at<=start_at then raise exception 'Valid start and end times required' using errcode='22023'; end if;
   -- Existing schedule trigger enforces playing-area overlap and team rest rules.
   update public.matches set scheduled_start=start_at,scheduled_end=end_at,status='SCHEDULED',updated_at=clock_timestamp() where id=m.id;
 else raise exception 'Unknown tournament action' using errcode='22023'; end if;
end; $$;
create function public.tournament_control(p_event uuid,p_action text,p_data jsonb default '{}') returns void language sql security invoker set search_path='' as $$ select arenax_private.tournament_control(p_event,p_action,p_data); $$;
revoke all on function public.tournament_control(uuid,text,jsonb),arenax_private.tournament_control(uuid,text,jsonb) from public,anon,authenticated;
grant execute on function public.tournament_control(uuid,text,jsonb),arenax_private.tournament_control(uuid,text,jsonb) to authenticated;
notify pgrst,'reload schema';
