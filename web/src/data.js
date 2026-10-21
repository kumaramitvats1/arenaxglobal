import {createClient} from '@supabase/supabase-js';
export const supabase=createClient('https://uzuiagwfmbbjztqvrsxn.supabase.co','sb_publishable_vj-n1W3u8h3k1xl9d1SSmA__oALXbD4',{auth:{flowType:'pkce',detectSessionInUrl:true,persistSession:true,autoRefreshToken:true}});
const unwrap=r=>{if(r.error)throw r.error;return r.data;};
export async function loadAccount(){
 const {data:{user},error}=await supabase.auth.getUser();if(error||!user)throw new Error('Please sign in again.');
 const profile=unwrap(await supabase.from('profiles').select('id,first_name,last_name,account_status').eq('id',user.id).single());
 if(profile.account_status!=='ACTIVE')return {user,profile};
 const [roles,staff,teams,members,registrations,events]=await Promise.all([
 supabase.from('user_roles').select('role,status,organization_id,event_id,team_id').eq('user_id',user.id).eq('status','ACTIVE'),
 supabase.from('event_staff_assignments').select('event_id,staff_role,status').eq('user_id',user.id).in('status',['ASSIGNED','CONFIRMED']),
 supabase.from('teams').select('id,event_id,team_name,captain_user_id'),
 supabase.from('team_members').select('team_id,team_role,status,invitation_status').eq('user_id',user.id).eq('status','ACTIVE').eq('invitation_status','ACCEPTED'),
 supabase.from('registrations').select('id,event_id,registration_status,payment_status,registration_type').eq('user_id',user.id),
 supabase.from('events').select('id,event_name,description,status,start_date,end_date,organization_id,sport_id,venue_id,registration_type,registration_fee,currency,pricing_model,sports(name),venues(name,city,country)').order('start_date',{ascending:false})]);
 const r=unwrap(roles),t=unwrap(teams);
 return {user,profile,roles:r,staff:unwrap(staff),teams:t,members:unwrap(members),registrations:unwrap(registrations),events:unwrap(events),captainTeams:t.filter(t=>t.captain_user_id===user.id||r.some(r=>r.role==='CAPTAIN'&&r.team_id===t.id))};
}
export async function loadMatches(id){return unwrap(await supabase.from('matches').select('id,match_code,stage,status,home_team_id,away_team_id,winner_team_id,scheduled_start').eq('event_id',id).order('match_number'));}
export async function saveProfile(user,first,last){const row=unwrap(await supabase.from('profiles').update({first_name:first,last_name:last}).eq('id',user.id).select('id').single());if(!row)throw new Error('Your profile could not be saved.');}
export const demoAccount={user:{id:'sample-player',email:'sample@arenax.example'},profile:{first_name:'Alex',last_name:'Morgan',account_status:'ACTIVE'},roles:[],staff:[{event_id:'sample-cup',staff_role:'SCORER',status:'CONFIRMED'}],teams:[{id:'sample-austin',event_id:'sample-cup',team_name:'Austin'}],captainTeams:[],members:[{team_id:'sample-austin',status:'ACTIVE',invitation_status:'ACCEPTED'}],registrations:[],events:[{id:'sample-cup',event_name:'ArenaX Texas Cricket Cup 2027',description:'A celebration of Texas cricket, team spirit and local competition. This sample event illustrates the portal; sign in to see the current tournament records.',status:'COMPLETED',start_date:'2027-02-06',end_date:'2027-02-14',registration_type:'TEAM',registration_fee:150,currency:'USD',pricing_model:'PER_TEAM',sports:{name:'Cricket'},venues:{name:'Sample Texas cricket ground',city:'Austin, Texas',country:'USA'}}]};
