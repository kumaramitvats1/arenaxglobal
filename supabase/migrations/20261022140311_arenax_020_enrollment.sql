-- Enrollment operations serialize on the event row. Private implementation is
-- privileged for atomic team bootstrap and cross-member consent checks; every
-- entry point independently checks active identity and resource ownership.
create table arenax_private.enrollment_audit (
 id bigint generated always as identity primary key,
 event_id uuid not null, actor_id uuid not null, action text not null,
 subject_id uuid, occurred_at timestamptz not null default clock_timestamp()
);
alter table arenax_private.enrollment_audit enable row level security;
revoke all on arenax_private.enrollment_audit from public,anon,authenticated;
grant all on arenax_private.enrollment_audit to service_role;

-- Consent writes now go through identity-checked atomic operations. Existing
-- records remain intact. A captain cannot forge another member's acceptance.
revoke insert,update,delete on public.team_members,public.waiver_acceptances,public.waivers from authenticated;
alter policy "Users can view team members" on public.team_members
using (arenax_private.is_active_user() and (user_id=auth.uid() or public.is_team_captain(team_id) or exists(select 1 from public.teams t where t.id=team_id and public.can_manage_event(t.event_id))));

create function arenax_private.enrollment_ready(p_event uuid,p_user uuid,p_team uuid)
returns numeric language plpgsql security definer set search_path='' as $$
declare e public.events; n integer; begin
 if not arenax_private.is_active_user() or
  (public.can_manage_event(p_event) or (p_team is null and p_user=auth.uid()) or
   (p_team is not null and public.is_team_captain(p_team))) is not true then
  raise exception 'Registration access denied' using errcode='42501'; end if;
 select * into strict e from public.events where id=p_event for update;
 if p_team is not null then
  if not exists(select 1 from public.teams where id=p_team and event_id=p_event) then
   raise exception 'Team belongs to another event' using errcode='22023'; end if;
  select count(*) into n from public.team_members m join public.profiles p on p.id=m.user_id
   where m.team_id=p_team and m.status='ACTIVE' and m.invitation_status='ACCEPTED' and p.account_status='ACTIVE';
  if n=0 or exists(select 1 from public.team_members m join public.profiles p on p.id=m.user_id
   where m.team_id=p_team and m.status='ACTIVE' and m.invitation_status='ACCEPTED' and p.account_status<>'ACTIVE') then
   raise exception 'An active accepted roster is required' using errcode='22023'; end if;
 else n:=1; end if;
 if exists(select 1 from public.waivers w where w.event_id=p_event and w.active and w.effective_at<=now()
  and exists(select 1 from (
   select p_user as uid where p_team is null
   union all select user_id from public.team_members where team_id=p_team and status='ACTIVE' and invitation_status='ACCEPTED'
  ) u where not exists(select 1 from public.waiver_acceptances a where a.waiver_id=w.id and a.user_id=u.uid))) then
  raise exception 'Every participant must accept the current event waivers' using errcode='22023'; end if;
 return case when e.pricing_model='FREE' then 0 when p_team is not null and e.pricing_model='PER_PLAYER' then e.registration_fee*n else e.registration_fee end;
end; $$;
revoke all on function arenax_private.enrollment_ready(uuid,uuid,uuid) from public,anon;
grant execute on function arenax_private.enrollment_ready(uuid,uuid,uuid) to authenticated;

-- Protect legacy direct registration submission too, not just the new UI/RPC.
create function arenax_private.enrollment_submission_guard()
returns trigger language plpgsql security invoker set search_path='' as $$
declare e public.events; due numeric; begin
 if current_user in ('postgres','service_role','supabase_admin') then return new; end if;
 if new.registration_status in ('SUBMITTED','APPROVED') and
  (tg_op='INSERT' or old.registration_status is distinct from new.registration_status) then
  due:=arenax_private.enrollment_ready(new.event_id,new.user_id,new.team_id);
  select * into strict e from public.events where id=new.event_id;
  if new.registration_status='SUBMITTED' and e.status<>'REGISTRATION_OPEN' then
   raise exception 'Registration is not open' using errcode='22023'; end if;
  if new.registration_status='SUBMITTED' then
   if new.amount_paid<>0 then raise exception 'Paid registration requires organizer reconciliation' using errcode='22023'; end if;
   new.amount_due:=due;
   new.payment_status:=case when due=0 then 'NOT_REQUIRED' else 'PENDING' end;
   new.registered_at:=clock_timestamp();
  end if;
  new.waiver_status:=case when exists(select 1 from public.waivers where event_id=new.event_id and active and effective_at<=now()) then 'ACCEPTED' else 'NOT_REQUIRED' end;
 end if;
 return new;
end; $$;
create trigger z_enrollment_submission_guard before insert or update on public.registrations
for each row execute function arenax_private.enrollment_submission_guard();
revoke all on function arenax_private.enrollment_submission_guard() from public,anon,authenticated;

create function arenax_private.enrollment_action(p_event uuid,p_action text,p_data jsonb)
returns uuid language plpgsql security definer set search_path='' as $$
declare e public.events; t public.teams; m public.team_members; r public.registrations;
 w public.waivers; uid uuid:=auth.uid(); tid uuid; rid uuid; target uuid; manager boolean;
 result uuid; due numeric; choice text; version_num integer;
begin
 if uid is null or not arenax_private.is_active_user() then raise exception 'Active account required' using errcode='42501'; end if;
 select * into e from public.events where id=p_event for update;
 if not found then raise exception 'Event unavailable' using errcode='42501'; end if;
 manager:=public.can_manage_event(p_event);
 if e.status not in ('PUBLISHED','REGISTRATION_OPEN','REGISTRATION_CLOSED') then
  raise exception 'Enrollment is unavailable for this event status' using errcode='22023'; end if;
 tid:=nullif(p_data->>'team_id','')::uuid; rid:=nullif(p_data->>'registration_id','')::uuid;
 if tid is not null then
  select * into t from public.teams where id=tid and event_id=p_event;
  if not found then raise exception 'Team unavailable' using errcode='42501'; end if;
 end if;
 if rid is not null then
  select * into r from public.registrations where id=rid and event_id=p_event;
  if not found then raise exception 'Registration unavailable' using errcode='42501'; end if;
 end if;
 if p_action='window' then
  if not manager then raise exception 'Organizer access required' using errcode='42501'; end if;
  choice:=p_data->>'status';
  if choice not in ('REGISTRATION_OPEN','REGISTRATION_CLOSED') or choice is null then raise exception 'Invalid registration status' using errcode='22023'; end if;
  if e.status='PUBLISHED' and choice<>'REGISTRATION_OPEN' then raise exception 'Open registration first' using errcode='22023'; end if;
  update public.events set status=choice,updated_at=clock_timestamp() where id=p_event; result:=p_event;
 elsif p_action='create_team' then
  if e.status<>'REGISTRATION_OPEN' or e.registration_type not in ('TEAM','BOTH') then raise exception 'Team registration is not open' using errcode='22023'; end if;
  if length(trim(coalesce(p_data->>'name','')))<2 or length(p_data->>'name')>100 then raise exception 'Team name must be 2–100 characters' using errcode='22023'; end if;
  insert into public.teams(event_id,team_name,captain_user_id) values(p_event,trim(p_data->>'name'),uid) returning id into result;
  insert into public.team_members(team_id,user_id,team_role,invitation_status,joined_at) values(result,uid,'CAPTAIN','ACCEPTED',clock_timestamp());
 elsif p_action in ('invite','respond','remove') then
  if tid is null then raise exception 'Team required' using errcode='22023'; end if;
  if e.status<>'REGISTRATION_OPEN' then raise exception 'Registration is not open' using errcode='22023'; end if;
  if exists(select 1 from public.registrations where team_id=tid and registered_at is not null) then
   raise exception 'Roster locked after submission. Ask the organizer to reopen it.' using errcode='22023'; end if;
  target:=nullif(p_data->>'user_id','')::uuid;
  if p_action='invite' then
   if not (manager or public.is_team_captain(tid)) then raise exception 'Captain access required' using errcode='42501'; end if;
   if target is null or not exists(select 1 from public.profiles where id=target and account_status='ACTIVE') then raise exception 'Active ArenaX member code required' using errcode='22023'; end if;
   insert into public.team_members(team_id,user_id,invitation_status) values(tid,target,'PENDING')
    on conflict(team_id,user_id) do update set invitation_status='PENDING',status='ACTIVE',joined_at=null,updated_at=clock_timestamp()
    where team_members.invitation_status in ('DECLINED','CANCELLED') or team_members.status<>'ACTIVE'
    returning id into result;
   if result is null then raise exception 'Player is already invited or on the roster' using errcode='22023'; end if;
  elsif p_action='respond' then
   choice:=p_data->>'status';
   if choice not in ('ACCEPTED','DECLINED') or choice is null then raise exception 'Invalid response' using errcode='22023'; end if;
   update public.team_members set invitation_status=choice,joined_at=case when choice='ACCEPTED' then clock_timestamp() else null end,updated_at=clock_timestamp()
    where team_id=tid and user_id=uid and invitation_status='PENDING' and status='ACTIVE' returning id into result;
   if result is null then raise exception 'No pending invitation for your account' using errcode='42501'; end if;
  else
   if not (manager or public.is_team_captain(tid) or target=uid) then raise exception 'Roster access denied' using errcode='42501'; end if;
   if target=t.captain_user_id then raise exception 'The captain cannot be removed here' using errcode='22023'; end if;
   update public.team_members set status='REMOVED',invitation_status='CANCELLED',updated_at=clock_timestamp() where team_id=tid and user_id=target returning id into result;
   if result is null then raise exception 'Member unavailable' using errcode='22023'; end if;
  end if;
 elsif p_action='accept_waiver' then
  if (p_data->>'accepted') is distinct from 'true' then raise exception 'Explicit acceptance required' using errcode='22023'; end if;
  select * into w from public.waivers where id=(p_data->>'waiver_id')::uuid and event_id=p_event and active and effective_at<=now();
  if not found or w.version is distinct from (p_data->>'version')::integer then raise exception 'Waiver changed. Read the current version.' using errcode='22023'; end if;
  insert into public.waiver_acceptances(waiver_id,user_id,accepted_at) values(w.id,uid,clock_timestamp())
   on conflict(waiver_id,user_id) do nothing returning id into result;
  if result is null then select id into result from public.waiver_acceptances where waiver_id=w.id and user_id=uid; end if;
 elsif p_action='publish_waiver' then
  if not manager then raise exception 'Organizer access required' using errcode='42501'; end if;
  if length(trim(coalesce(p_data->>'title','')))<3 or length(p_data->>'title')>160 or length(trim(coalesce(p_data->>'text','')))<20 or length(p_data->>'text')>50000 then raise exception 'Enter a title and the approved waiver text' using errcode='22023'; end if;
  if exists(select 1 from public.registrations where event_id=p_event and registered_at is not null) then raise exception 'Waiver versions cannot change after submissions in this release' using errcode='22023'; end if;
  select coalesce(max(version),0)+1 into version_num from public.waivers where event_id=p_event;
  update public.waivers set active=false where event_id=p_event;
  insert into public.waivers(event_id,version,title,waiver_text,created_by) values(p_event,version_num,trim(p_data->>'title'),p_data->>'text',uid) returning id into result;
 elsif p_action='submit' then
  if e.status<>'REGISTRATION_OPEN' then raise exception 'Registration is not open' using errcode='22023'; end if;
  if tid is not null then
   if not public.is_team_captain(tid) then raise exception 'Captain access required' using errcode='42501'; end if;
   if e.registration_type not in ('TEAM','BOTH') then raise exception 'Individual registration required' using errcode='22023'; end if;
  elsif e.registration_type not in ('INDIVIDUAL','BOTH') then raise exception 'Team registration required' using errcode='22023'; end if;
  select * into r from public.registrations where event_id=p_event and registration_status<>'CANCELLED'
   and ((tid is null and registration_type='INDIVIDUAL' and user_id=uid) or (tid is not null and team_id=tid));
  if found and r.registration_status<>'DRAFT' then raise exception 'Registration already submitted' using errcode='22023'; end if;
  if r.id is not null and (r.amount_paid<>0 or r.payment_status in ('PAID','PARTIALLY_PAID','REFUNDED')) then raise exception 'Payment reconciliation required' using errcode='22023'; end if;
  due:=arenax_private.enrollment_ready(p_event,uid,tid);
  choice:=case when exists(select 1 from public.waivers where event_id=p_event and active and effective_at<=now()) then 'ACCEPTED' else 'NOT_REQUIRED' end;
  if r.id is null then
   insert into public.registrations(event_id,user_id,team_id,registration_type,registration_status,amount_due,payment_status,waiver_status,registered_at)
    values(p_event,case when tid is null then uid else null end,tid,case when tid is null then 'INDIVIDUAL' else 'TEAM' end,'SUBMITTED',due,case when due=0 then 'NOT_REQUIRED' else 'PENDING' end,choice,clock_timestamp()) returning id into result;
  else
   update public.registrations set registration_status='SUBMITTED',amount_due=due,payment_status=case when due=0 then 'NOT_REQUIRED' else 'PENDING' end,waiver_status=choice,registered_at=clock_timestamp(),updated_at=clock_timestamp() where id=r.id returning id into result;
  end if;
  if tid is not null then update public.teams set registration_status='SUBMITTED',approval_status='PENDING',updated_at=clock_timestamp() where id=tid; end if;
 elsif p_action='review' then
  if not manager then raise exception 'Organizer access required' using errcode='42501'; end if;
  if rid is null then raise exception 'Registration required' using errcode='22023'; end if;
  if r.updated_at is distinct from (p_data->>'expected_updated_at')::timestamptz then raise exception 'Registration changed. Refresh before reviewing.' using errcode='40001'; end if;
  choice:=p_data->>'status';
  if choice='DRAFT' then
   if e.status<>'REGISTRATION_OPEN' or r.amount_paid<>0 or r.payment_status in ('PAID','PARTIALLY_PAID','REFUNDED') then raise exception 'Reopen only during registration and before payment' using errcode='22023'; end if;
   if r.registration_status not in ('SUBMITTED','WAITLISTED','REJECTED','APPROVED') then raise exception 'Cannot reopen this registration' using errcode='22023'; end if;
   update public.registrations set registration_status='DRAFT',registered_at=null,waiver_status='PENDING',updated_at=clock_timestamp() where id=rid;
   if r.team_id is not null then update public.teams set registration_status='DRAFT',approval_status='PENDING',updated_at=clock_timestamp() where id=r.team_id; end if;
  else
   if choice is null or choice not in ('APPROVED','REJECTED','WAITLISTED') or r.registration_status not in ('SUBMITTED','WAITLISTED') then raise exception 'Invalid review transition' using errcode='22023'; end if;
   if choice='APPROVED' then perform arenax_private.enrollment_ready(p_event,r.user_id,r.team_id); end if;
   update public.registrations set registration_status=choice,updated_at=clock_timestamp() where id=rid;
   if r.team_id is not null then update public.teams set registration_status=choice,approval_status=case when choice='APPROVED' then 'APPROVED' when choice='REJECTED' then 'REJECTED' else 'PENDING' end,updated_at=clock_timestamp() where id=r.team_id; end if;
  end if;
  result:=rid;
 else raise exception 'Unknown enrollment action' using errcode='22023';
 end if;
 insert into arenax_private.enrollment_audit(event_id,actor_id,action,subject_id) values(p_event,uid,p_action||coalesce(':'||(p_data->>'status'),''),result);
 return result;
end; $$;
revoke all on function arenax_private.enrollment_action(uuid,text,jsonb) from public,anon;
grant execute on function arenax_private.enrollment_action(uuid,text,jsonb) to authenticated;
create function public.enrollment_action(p_event uuid,p_action text,p_data jsonb default '{}')
returns uuid language sql security invoker set search_path='' as $$ select arenax_private.enrollment_action(p_event,p_action,p_data); $$;
revoke all on function public.enrollment_action(uuid,text,jsonb) from public,anon;
grant execute on function public.enrollment_action(uuid,text,jsonb) to authenticated;

create function arenax_private.enrollment_view(p_event uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare manager boolean; begin
 if not arenax_private.is_active_user() then raise exception 'Active account required' using errcode='42501'; end if;
 manager:=public.can_manage_event(p_event);
 if not exists(select 1 from public.events where id=p_event and (manager or status in ('PUBLISHED','REGISTRATION_OPEN','REGISTRATION_CLOSED','IN_PROGRESS','COMPLETED'))) then raise exception 'Event unavailable' using errcode='42501'; end if;
 return jsonb_build_object('can_manage',manager,'event_status',(select status from public.events where id=p_event),
 'teams',coalesce((select jsonb_agg(jsonb_build_object('id',t.id,'name',t.team_name,'captain',t.captain_user_id=auth.uid() or public.is_team_captain(t.id),'locked',exists(select 1 from public.registrations r where r.team_id=t.id and r.registered_at is not null),
 'members',(select coalesce(jsonb_agg(jsonb_build_object('user_id',m.user_id,'name',trim(coalesce(p.first_name,'')||' '||coalesce(p.last_name,'')),'role',m.team_role,'status',m.status,'invitation',m.invitation_status,'waivers_complete',not exists(select 1 from public.waivers w where w.event_id=p_event and w.active and w.effective_at<=now() and not exists(select 1 from public.waiver_acceptances a where a.waiver_id=w.id and a.user_id=m.user_id)))),'[]') from public.team_members m join public.profiles p on p.id=m.user_id where m.team_id=t.id and (manager or public.is_team_captain(t.id) or m.user_id=auth.uid())))) from public.teams t where t.event_id=p_event and (manager or public.is_team_captain(t.id) or exists(select 1 from public.team_members m where m.team_id=t.id and m.user_id=auth.uid() and m.status='ACTIVE'))),'[]'),
 'registrations',coalesce((select jsonb_agg(to_jsonb(r)||jsonb_build_object('display_name',coalesce(t.team_name,nullif(trim(coalesce(p.first_name,'')||' '||coalesce(p.last_name,'')),''),'Participant'))) from public.registrations r left join public.teams t on t.id=r.team_id left join public.profiles p on p.id=r.user_id where r.event_id=p_event and (manager or r.user_id=auth.uid() or public.is_team_captain(r.team_id))),'[]'),
 'waivers',coalesce((select jsonb_agg(jsonb_build_object('id',w.id,'title',w.title,'version',w.version,'text',w.waiver_text,'accepted',exists(select 1 from public.waiver_acceptances a where a.waiver_id=w.id and a.user_id=auth.uid()))) from public.waivers w where w.event_id=p_event and w.active and w.effective_at<=now()),'[]'));
end; $$;
revoke all on function arenax_private.enrollment_view(uuid) from public,anon;
grant execute on function arenax_private.enrollment_view(uuid) to authenticated;
create function public.get_enrollment(p_event uuid) returns jsonb language sql stable security invoker set search_path='' as $$ select arenax_private.enrollment_view(p_event); $$;
revoke all on function public.get_enrollment(uuid) from public,anon;
grant execute on function public.get_enrollment(uuid) to authenticated;
notify pgrst,'reload schema';
