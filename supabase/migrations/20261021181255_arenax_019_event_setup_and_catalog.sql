-- Additive APIs. Existing event policies and tournament lifecycle are preserved.
begin;
-- Evaluate the new row's organization directly during INSERT ... RETURNING.
-- can_manage_event(id) reads the table under a stable snapshot and cannot see it yet.
create policy "Organizers can read own event drafts" on public.events
for select to authenticated using (public.is_organizer(organization_id));
create function arenax_private.event_catalog(p_event_id uuid, p_offset integer)
returns jsonb language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb) from (
 select e.id,e.event_name,e.description,e.status,e.start_date,e.end_date,
 e.registration_type,e.registration_fee,e.currency,e.pricing_model,
 jsonb_build_object('name',s.name) as sports,
 jsonb_build_object('name',v.name,'city',v.city,'state',v.state,'country',v.country) as venues
 from public.events e join public.sports s on s.id=e.sport_id
 left join public.venues v on v.id=e.venue_id
 where e.status in ('PUBLISHED','REGISTRATION_OPEN','REGISTRATION_CLOSED','IN_PROGRESS','COMPLETED')
 and (p_event_id is null or e.id=p_event_id)
 order by e.start_date desc,e.id limit 50 offset greatest(0,least(coalesce(p_offset,0),100000))
 ) x;
$$;
revoke all on function arenax_private.event_catalog(uuid,integer) from public;
grant usage on schema arenax_private to anon;
grant execute on function arenax_private.event_catalog(uuid,integer) to anon,authenticated;
create function public.get_event_catalog(p_event_id uuid default null,p_offset integer default 0)
returns jsonb language sql stable security invoker set search_path='' as $$
 select arenax_private.event_catalog(p_event_id,p_offset);
$$;
revoke all on function public.get_event_catalog(uuid,integer) from public;
grant execute on function public.get_event_catalog(uuid,integer) to anon,authenticated;

create function public.save_event_setup(p_payload jsonb,p_event_id uuid default null,p_expected_updated_at timestamptz default null)
returns uuid language plpgsql security invoker set search_path='' as $$
declare
 old_event public.events%rowtype;
 org uuid; sport uuid; venue uuid; v_saved_id uuid;
 name text; v_description text; starts date; ends date; reg text; pricing text; v_currency text; fee numeric; target_status text;
begin
 if auth.uid() is null or not arenax_private.is_active_user() then raise exception 'Active account required' using errcode='42501'; end if;
 if p_payload is null or jsonb_typeof(p_payload)<>'object' then raise exception 'Event details required' using errcode='22023'; end if;
 org:=(p_payload->>'organization_id')::uuid;
 if org is null or not public.is_organizer(org) then raise exception 'Organizer access required' using errcode='42501'; end if;
 if p_event_id is not null then
   select * into old_event from public.events where id=p_event_id for update;
   if not found or old_event.organization_id<>org or not public.can_manage_event(p_event_id) then raise exception 'Event unavailable' using errcode='42501'; end if;
   if old_event.status<>'DRAFT' then raise exception 'Only draft events can be edited in setup' using errcode='22023'; end if;
   if p_expected_updated_at is null or old_event.updated_at is distinct from p_expected_updated_at then raise exception 'This event changed. Reload before saving.' using errcode='40001'; end if;
   if exists(select 1 from public.registrations where event_id=p_event_id) or exists(select 1 from public.matches where event_id=p_event_id) or exists(select 1 from public.teams where event_id=p_event_id) then raise exception 'Event already has competition data' using errcode='22023'; end if;
 end if;
 name:=btrim(p_payload->>'event_name'); v_description:=coalesce(p_payload->>'description','');
 starts:=(p_payload->>'start_date')::date; ends:=(p_payload->>'end_date')::date;
 sport:=(p_payload->>'sport_id')::uuid; venue:=nullif(p_payload->>'venue_id','')::uuid;
 reg:=p_payload->>'registration_type'; pricing:=p_payload->>'pricing_model'; v_currency:=upper(p_payload->>'currency'); fee:=(p_payload->>'registration_fee')::numeric;
 target_status:=coalesce(p_payload->>'status','DRAFT');
 if name is null or length(name) not between 3 and 160 or length(v_description)>5000 then raise exception 'Name must be 3–160 characters; description maximum 5000' using errcode='22023'; end if;
 if starts is null or ends is null or ends<starts then raise exception 'Valid event dates required' using errcode='22023'; end if;
 if reg is null or reg not in ('TEAM','INDIVIDUAL','BOTH') or pricing is null or pricing not in ('FREE','PER_TEAM','PER_PLAYER') or (reg='INDIVIDUAL' and pricing='PER_TEAM') then raise exception 'Invalid registration or pricing model' using errcode='22023'; end if;
 if v_currency is null or v_currency !~ '^[A-Z]{3}$' or fee is null or fee<0 or fee>99999999.99 or fee<>round(fee,2) or (pricing='FREE' and fee<>0) then raise exception 'Invalid currency or fee' using errcode='22023'; end if;
 if target_status not in ('DRAFT','PUBLISHED') then raise exception 'Setup can only save drafts or publish' using errcode='22023'; end if;
 if not exists(select 1 from public.sports where id=sport and active) then raise exception 'Choose an active sport' using errcode='22023'; end if;
 if venue is not null and not exists(select 1 from public.venues where id=venue and organization_id=org and active) then raise exception 'Choose an active venue in this organization' using errcode='22023'; end if;
 if p_event_id is null then
 insert into public.events(organization_id,sport_id,venue_id,event_name,description,start_date,end_date,registration_type,pricing_model,currency,registration_fee,status,created_by)
 values(org,sport,venue,name,v_description,starts,ends,reg,pricing,v_currency,fee,target_status,auth.uid()) returning id into v_saved_id;
 else
 update public.events set sport_id=sport,venue_id=venue,event_name=name,description=v_description,start_date=starts,end_date=ends,registration_type=reg,pricing_model=pricing,currency=v_currency,registration_fee=fee,status=target_status,updated_at=clock_timestamp() where id=p_event_id returning id into v_saved_id;
 end if;
 return v_saved_id;
end;
$$;
revoke all on function public.save_event_setup(jsonb,uuid,timestamptz) from public,anon;
grant execute on function public.save_event_setup(jsonb,uuid,timestamptz) to authenticated;
notify pgrst,'reload schema';
commit;
