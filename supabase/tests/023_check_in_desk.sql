begin;
create temporary table arenax_test_results (test text, passed boolean);
grant select,insert on arenax_test_results to authenticated,anon;
do $$
declare v_org uuid; v_event uuid; v_other uuid; v_sport uuid; v_team uuid; v_reg uuid; v_member uuid;
begin
 select sport_id into strict v_sport from public.events where event_name='ArenaX India States Cricket Cup 2027';
 insert into public.organizations(name,slug,country,timezone)
 values('Texas check-in desk test','check-in-test-'||gen_random_uuid(),'USA','America/Chicago') returning id into v_org;
 insert into public.events(organization_id,sport_id,event_name,start_date,end_date,registration_type,status)
 values(v_org,v_sport,'Austin Check-In Test',current_date,current_date,'BOTH','IN_PROGRESS') returning id into v_event;
 insert into public.events(organization_id,sport_id,event_name,start_date,end_date,registration_type,status)
 values(v_org,v_sport,'Dallas Isolation Test',current_date,current_date,'BOTH','IN_PROGRESS') returning id into v_other;
 insert into public.teams(event_id,team_name,registration_status,approval_status)
 values(v_event,'Austin Aces','APPROVED','APPROVED') returning id into v_team;
 insert into public.team_members(team_id,user_id,team_role,status,invitation_status,waiver_status)
 values(v_team,'a289ed2b-99c9-4aad-affc-d3ca89ebcfbb','PLAYER','ACTIVE','ACCEPTED','ACCEPTED') returning id into v_member;
 insert into public.registrations(event_id,team_id,registration_type,registration_status,waiver_status,payment_status)
 values(v_event,v_team,'TEAM','APPROVED','NOT_REQUIRED','NOT_REQUIRED') returning id into v_reg;
 insert into public.registrations(event_id,user_id,registration_type,registration_status,waiver_status,payment_status)
 values(v_event,'3514e1cc-fca6-478b-a760-cb83eefac27e','INDIVIDUAL','APPROVED','NOT_REQUIRED','NOT_REQUIRED');
 perform set_config('arenax.test_event',v_event::text,true);
 perform set_config('arenax.other_event',v_other::text,true);
 perform set_config('arenax.test_org',v_org::text,true);
 perform set_config('arenax.test_reg',v_reg::text,true);
 perform set_config('arenax.test_member',v_member::text,true);
end; $$;

create function pg_temp.desk_assert(label text,ok boolean) returns void language plpgsql as $$ begin if ok is distinct from true then raise exception 'Failed: %',label; end if; insert into arenax_test_results values(label,true); end; $$;
create function pg_temp.desk_denied(label text,statement text) returns void language plpgsql as $$ begin begin execute statement; exception when insufficient_privilege or invalid_parameter_value then insert into arenax_test_results values(label,true); return; end; raise exception 'Unexpected success: %',label; end; $$;
grant execute on function pg_temp.desk_assert(text,boolean),pg_temp.desk_denied(text,text) to authenticated,anon;
select set_config('request.jwt.claim.sub','a289ed2b-99c9-4aad-affc-d3ca89ebcfbb',true);
set local role authenticated;
select pg_temp.desk_denied('player cannot read directory',format('select public.get_event_check_in_desk(%L)',current_setting('arenax.test_event')));
select pg_temp.desk_denied('private entry checks permission',format('select arenax_private.get_check_in_desk(%L)',current_setting('arenax.test_event')));
reset role;
insert into public.event_staff_assignments(event_id,user_id,staff_role,status) values(current_setting('arenax.test_event')::uuid,'a289ed2b-99c9-4aad-affc-d3ca89ebcfbb','SCORER','CONFIRMED');
set local role authenticated;
select pg_temp.desk_denied('SCORER cannot read directory',format('select public.get_event_check_in_desk(%L)',current_setting('arenax.test_event')));
reset role;
insert into public.event_staff_assignments(event_id,user_id,staff_role,status) values(current_setting('arenax.test_event')::uuid,'a289ed2b-99c9-4aad-affc-d3ca89ebcfbb','CHECK_IN','CONFIRMED');
set local role authenticated;
select pg_temp.desk_assert('staff sees only registered event participants',jsonb_array_length(public.get_event_check_in_desk(current_setting('arenax.test_event')::uuid)->'rows')=2);
select pg_temp.desk_assert('team search works',jsonb_array_length(public.get_event_check_in_desk(current_setting('arenax.test_event')::uuid,'Austin')->'rows')=1);
select pg_temp.desk_assert('UUID lookup works',jsonb_array_length(public.get_event_check_in_desk(current_setting('arenax.test_event')::uuid,'3514e1cc-fca6-478b-a760-cb83eefac27e')->'rows')=1);
select pg_temp.desk_assert('wildcard search is literal',jsonb_array_length(public.get_event_check_in_desk(current_setting('arenax.test_event')::uuid,'%')->'rows')=0);
select pg_temp.desk_assert('pagination offset works',jsonb_array_length(public.get_event_check_in_desk(current_setting('arenax.test_event')::uuid,'',1)->'rows')=1);
select pg_temp.desk_denied('other event denied',format('select public.get_event_check_in_desk(%L)',current_setting('arenax.other_event')));
select pg_temp.desk_denied('negative offset denied',format('select public.get_event_check_in_desk(%L,%L,-1)',current_setting('arenax.test_event'),''));
select pg_temp.desk_denied('invalid filter denied',format('select public.get_event_check_in_desk(%L,%L,0,%L)',current_setting('arenax.test_event'),'','UNKNOWN'));
select public.check_in_event_participant(current_setting('arenax.test_event')::uuid,'3514e1cc-fca6-478b-a760-cb83eefac27e');
select pg_temp.desk_assert('present filter works',jsonb_array_length(public.get_event_check_in_desk(current_setting('arenax.test_event')::uuid,'',0,'PRESENT')->'rows')=1);
select pg_temp.desk_assert('pending filter works',jsonb_array_length(public.get_event_check_in_desk(current_setting('arenax.test_event')::uuid,'',0,'PENDING')->'rows')=1);
select pg_temp.desk_assert('operator and timestamp retained',(public.get_event_check_in_desk(current_setting('arenax.test_event')::uuid,'',0,'PRESENT')->'rows'->0->>'checked_in_by')='a289ed2b-99c9-4aad-affc-d3ca89ebcfbb' and (public.get_event_check_in_desk(current_setting('arenax.test_event')::uuid)->>'checked_in_count')::integer=1);
reset role;
update public.registrations set registration_status='CANCELLED' where event_id=current_setting('arenax.test_event')::uuid;
set local role authenticated;
select pg_temp.desk_assert('attendance history survives cancellation but pending cancelled registration excluded',jsonb_array_length(public.get_event_check_in_desk(current_setting('arenax.test_event')::uuid)->'rows')=1);
reset role;
update public.event_staff_assignments set status='CANCELLED' where event_id=current_setting('arenax.test_event')::uuid and staff_role='CHECK_IN';
set local role authenticated;
select pg_temp.desk_denied('revocation immediately blocks directory',format('select public.get_event_check_in_desk(%L)',current_setting('arenax.test_event')));
reset role;
select set_config('request.jwt.claim.sub','3514e1cc-fca6-478b-a760-cb83eefac27e',true);
set local role authenticated;
select pg_temp.desk_assert('admin can read attendance',jsonb_array_length(public.get_event_check_in_desk(current_setting('arenax.test_event')::uuid)->'rows')=1);
reset role;
select set_config('request.jwt.claim.sub','',true);
set local role anon;
select pg_temp.desk_denied('anonymous cannot execute',format('select public.get_event_check_in_desk(%L)',current_setting('arenax.test_event')));
reset role;
select jsonb_build_object('passed',count(*),'tests',jsonb_agg(test order by test)) as verification from arenax_test_results;
rollback;
