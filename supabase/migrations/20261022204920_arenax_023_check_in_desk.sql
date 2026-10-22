-- Minimal event-scoped directory for authorized check-in operators.
-- Does not broaden profile/roster table policies or expose QR tokens.
create function arenax_private.get_check_in_desk(p_event uuid,p_search text default '',p_offset integer default 0,p_filter text default 'ALL')
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
 if auth.uid() is null or not arenax_private.can_check_in(p_event) then
  raise exception 'Only event organizers or CHECK_IN staff can view the check-in desk' using errcode='42501';
 end if;
 if p_offset is null or p_offset<0 or p_offset>100000 or p_search is null or length(p_search)>100 or p_filter is null or p_filter not in ('ALL','PRESENT','PENDING') then
  raise exception 'Invalid search, page or attendance filter' using errcode='22023';
 end if;
 with candidates as (
  select r.user_id as id from public.registrations r where r.event_id=p_event and r.registration_type='INDIVIDUAL' and r.user_id is not null and r.registration_status<>'CANCELLED'
  union
  select tm.user_id from public.registrations r join public.teams t on t.id=r.team_id and t.event_id=p_event join public.team_members tm on tm.team_id=t.id
  where r.event_id=p_event and r.registration_type='TEAM' and r.registration_status<>'CANCELLED' and tm.status='ACTIVE' and tm.invitation_status='ACCEPTED'
  union
  select participant_user_id from public.event_check_ins where event_id=p_event
 ), roster as (
  select p.id as user_id,coalesce(nullif(trim(concat_ws(' ',p.first_name,p.last_name)),''),'Participant') as name,
   coalesce((select string_agg(distinct t.team_name,', ' order by t.team_name) from public.teams t join public.team_members tm on tm.team_id=t.id
    where t.event_id=p_event and tm.user_id=p.id and tm.status='ACTIVE' and tm.invitation_status='ACCEPTED'),'') as teams,
   c.checked_in_at,c.check_in_method,c.checked_in_by,
   case when c.id is not null then coalesce(nullif(trim(concat_ws(' ',operator.first_name,operator.last_name)),''),'Event staff') end as operator_name
  from candidates x join public.profiles p on p.id=x.id
  left join public.event_check_ins c on c.event_id=p_event and c.participant_user_id=p.id
  left join public.profiles operator on operator.id=c.checked_in_by
 ), filtered as (
  select * from roster where (p_filter='ALL' or p_filter='PRESENT' and checked_in_at is not null or p_filter='PENDING' and checked_in_at is null)
  and (trim(p_search)='' or position(lower(trim(p_search)) in lower(name||' '||teams||' '||user_id::text))>0)
 ), page as (select * from filtered order by name,user_id limit 51 offset p_offset)
 select jsonb_build_object('rows',coalesce((select jsonb_agg(to_jsonb(r) order by r.name,r.user_id) from (select * from page order by name,user_id limit 50) r),'[]'::jsonb),
  'has_more',(select count(*)>50 from page),'checked_in_count',(select count(*) from public.event_check_ins where event_id=p_event)) into result;
 return result;
end; $$;
create function public.get_event_check_in_desk(p_event uuid,p_search text default '',p_offset integer default 0,p_filter text default 'ALL')
returns jsonb language sql stable security invoker set search_path='' as $$ select arenax_private.get_check_in_desk(p_event,p_search,p_offset,p_filter); $$;
revoke all on function public.get_event_check_in_desk(uuid,text,integer,text),arenax_private.get_check_in_desk(uuid,text,integer,text) from public,anon,authenticated;
grant execute on function public.get_event_check_in_desk(uuid,text,integer,text),arenax_private.get_check_in_desk(uuid,text,integer,text) to authenticated;
notify pgrst,'reload schema';
