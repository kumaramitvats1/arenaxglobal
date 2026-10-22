import {fixtureSetup} from './fixture-setup.js';
import {supabase} from './data.js';
import {escapeHTML as h,pretty} from './model.js';
import {scoreable,scorePayload,overs,progression} from './tournament-model.js';
const unwrap=r=>{if(r.error)throw r.error;return r.data;};
const when=s=>s?new Date(s).toLocaleString('en-US',{timeZone:'America/Chicago',dateStyle:'medium',timeStyle:'short'}):'Time to be announced';
const local=s=>s?new Date(new Date(s).getTime()-new Date(s).getTimezoneOffset()*60000).toISOString().slice(0,16):'';
export async function tournamentPage({account,demo,workspace,shell},eventId){
 const event=account.events.find(e=>e.id===eventId),route='#/tournament/'+eventId;
 if(!event){shell('<div class="empty"><h1>Event unavailable</h1><a href="#/events">Back to events</a></div>');return;}
 shell('<div class="loading">Loading fixtures and standings…</div>','tournament');
 let data;
 async function load(){
  if(demo&&eventId==='sample-frisco'){
   const teams=['Austin Aces','Dallas Stars','Houston Hawks','San Antonio Strikers'].map((team_name,i)=>({id:'sample-team-'+i,team_name}));
   const current=account.tournaments?.[eventId]||{matches:[],teams,groups:[],standings:[],eligible:teams};
   return {...current,manage:['organizer','admin'].includes(workspace),score:workspace==='staff'};
  }
  if(demo){const done=event.status==='COMPLETED';return account.tournaments?.[eventId]??{manage:['organizer','admin'].includes(workspace),score:workspace==='staff',matches:done?[{id:'sample-final',match_code:'FINAL',stage:'FINAL',status:'COMPLETED',result_status:'CONFIRMED',home_team_id:'sample-austin',away_team_id:'sample-houston',winner_team_id:'sample-austin',innings:[{team_id:'sample-austin',runs:92,wickets:4,balls_faced:48},{team_id:'sample-houston',runs:80,wickets:7,balls_faced:48}],result:{result_summary:'Austin won by 12 runs'},scheduled_start:'2027-02-14T16:00:00Z'}]:[],teams:[{id:'sample-austin',team_name:'Austin'},{id:'sample-houston',team_name:'Houston'}],groups:[],standings:[]};}
  const [matches,groups,teams,manager,scorer,fresh]=await Promise.all([
   supabase.from('matches').select('id,match_code,match_number,stage,status,result_status,home_team_id,away_team_id,winner_team_id,scheduled_start,scheduled_end,updated_at,innings:cricket_innings(team_id,runs,wickets,balls_faced),result:match_results(result_summary,verified,verified_at)').eq('event_id',eventId).order('match_number'),
   supabase.from('groups').select('id,name,divisions!inner(event_id)').eq('divisions.event_id',eventId),
   supabase.from('teams').select('id,team_name').eq('event_id',eventId),
   supabase.rpc('can_manage_event',{p_event_id:eventId}),supabase.rpc('has_event_staff_role',{p_event_id:eventId,p_staff_role:'SCORER'}),
   supabase.from('events').select('status').eq('id',eventId).single()]);
  const gs=unwrap(groups);event.status=unwrap(fresh).status;
  const standings=gs.length?unwrap(await supabase.from('standings').select('group_id,team_id,rank,played,won,lost,tied,no_result,points,net_run_rate').in('group_id',gs.map(g=>g.id)).order('rank')):[];
  const manage=unwrap(manager),ts=unwrap(teams);let eligible=[];
  if(manage&&event.status==='REGISTRATION_CLOSED'&&!unwrap(matches).length){
   const approved=unwrap(await supabase.from('registrations').select('team_id').eq('event_id',eventId).eq('registration_type','TEAM').eq('registration_status','APPROVED'));
   const ids=new Set(approved.map(r=>r.team_id));eligible=ts.filter(t=>ids.has(t.id)).sort((a,b)=>a.team_name.localeCompare(b.team_name));
  }
  return {matches:unwrap(matches),groups:gs,teams:ts,manage,score:unwrap(scorer),standings,eligible};
 }
 try{data=await load();}catch(error){if(location.hash===route)shell(`<div class="notice error">${h(error.message||'Tournament could not be loaded.')}</div><a href="#/event/${h(eventId)}">Back to event</a>`,'tournament');return;}
 if(location.hash!==route)return;
 const team=id=>data.teams.find(t=>t.id===id)?.team_name||'To be decided';
 let filter='all';
 const cricket=event.sports?.name?.toLowerCase()==='cricket';
 function draw(note=''){
  if(location.hash!==route)return;
  const active=event.status==='IN_PROGRESS',next=progression(data.matches),final=data.matches.find(m=>m.stage==='FINAL'&&m.status==='COMPLETED'&&m.result_status==='CONFIRMED'&&m.winner_team_id);
  shell(`<a class="textlink" href="#/event/${h(eventId)}">← Event details</a><div class="page-head"><div><span class="eyebrow">The competition desk</span><h1>Fixtures & standings</h1><p>${h(event.event_name)} · ${h(pretty(event.status))}</p></div><button class="secondary" id="t-refresh">Refresh results</button></div><div id="t-message" aria-live="polite">${note?`<div class="notice success">${h(note)}</div>`:''}</div>${event.status==='COMPLETED'?`<section class="hero"><div><span class="eyebrow">Tournament complete</span><h2>${final?h(team(final.winner_team_id))+' · Champions':'Final results'}</h2><p>Confirmed results are preserved for everyone to revisit.</p></div></section>`:''}${!cricket?'<div class="notice">Fixtures and published results are available here. Score entry for this sport is not available yet.</div>':''}${data.manage?`<section class="card tournament-controls"><h2>Organizer controls</h2><p>Prepare fixtures, close registration, then start the competition. Confirmed results are locked.</p><div class="form-actions">${cricket&&event.status==='REGISTRATION_CLOSED'&&!data.matches.length?'<button id="fixture-create">Set up cricket fixtures</button>':''}${event.status==='REGISTRATION_CLOSED'&&data.matches.length?'<button data-control="start">Start tournament</button>':''}${active&&cricket&&next.semifinals?'<button data-control="semifinals">Resolve semifinalists</button>':''}${active&&cricket&&next.complete?'<button data-control="complete">Complete tournament</button>':''}<a class="button secondary" href="#/enrollment/${h(eventId)}">Registration controls</a></div>${!data.matches.length?'<p class="muted">No fixtures yet. For cricket, approve 4–16 team registrations and close registration to set up two balanced groups.</p>':''}</section>`:''}<div class="section-head"><h2>Match schedule</h2><span class="muted">Times: America/Chicago</span></div><label class="field">Show matches<select id="t-filter"><option value="all">All matches</option><option value="upcoming">Upcoming</option><option value="completed">Completed</option><option value="GROUP">Group stage</option><option value="SEMIFINAL">Semifinals</option><option value="FINAL">Final</option></select></label><div id="t-fixtures"></div><div id="t-editor"></div><div class="section-head"><h2>Group standings</h2><span class="muted">Based on confirmed results</span></div>${data.groups.length?data.groups.map(g=>`<section class="card"><h3 class="standings-title">${h(g.name)}</h3><div class="table-wrap"><table><thead><tr><th>Rank</th><th>Team</th><th>Played</th><th>Won</th><th>Lost</th><th>Tied</th><th>No result</th><th>Points</th>${cricket?'<th>Net run rate</th>':''}</tr></thead><tbody>${data.standings.filter(s=>s.group_id===g.id).map(s=>`<tr><td>${h(s.rank??'—')}</td><td>${h(team(s.team_id))}</td><td>${s.played}</td><td>${s.won}</td><td>${s.lost}</td><td>${s.tied}</td><td>${s.no_result}</td><td><strong>${h(s.points)}</strong></td>${cricket?`<td>${Number(s.net_run_rate).toFixed(4)}</td>`:''}</tr>`).join('')||'<tr><td colspan="9">Standings have not been prepared yet.</td></tr>'}</tbody></table></div></section>`).join(''):'<div class="empty"><p>No group standings are available for this event yet.</p></div>'}`,'tournament');
  document.querySelector('#t-filter').value=filter;document.querySelector('#t-filter').onchange=e=>{filter=e.target.value;fixtures();};fixtures();
  document.querySelector('#t-refresh').onclick=()=>refresh();
  document.querySelector('#fixture-create')?.addEventListener('click',()=>fixtureSetup({teams:data.eligible||[],editor,submit:plan=>{
   if(!demo){run(()=>supabase.rpc('generate_cricket_fixtures',{p_event:eventId,p_group_a:plan.a,p_group_b:plan.b}));return;}
   const groups=[{id:'sample-group-A',name:'Group A'},{id:'sample-group-B',name:'Group B'}];
   const matches=plan.groupMatches.map((m,i)=>({id:'sample-fixture-'+i,match_code:'M'+String(i+1).padStart(2,'0'),stage:'GROUP',home_team_id:m.home,away_team_id:m.away,status:'DRAFT',result_status:'PENDING',innings:[]}));
   for(const code of ['SF1','SF2','FINAL'])matches.push({id:'sample-'+code,match_code:code,stage:code==='FINAL'?'FINAL':'SEMIFINAL',status:'DRAFT',result_status:'PENDING',innings:[]});
   const standings=[...plan.a.map(team_id=>({team_id,group_id:groups[0].id})),...plan.b.map(team_id=>({team_id,group_id:groups[1].id}))].map(s=>({...s,played:0,won:0,lost:0,tied:0,no_result:0,points:0,net_run_rate:0}));
   account.tournaments??={};account.tournaments[eventId]={...data,groups,matches,standings};data=account.tournaments[eventId];draw('Sample fixtures generated in memory only. No live records were changed.');
  }}));
  document.querySelectorAll('[data-control]').forEach(b=>b.onclick=()=>{
   const action=b.dataset.control;
   const labels={start:'Start this tournament?',semifinals:'Resolve semifinalists from confirmed group standings?',complete:'Complete this tournament and lock its results?'};
   editor(`<h2>${labels[action]}</h2><p>This changes the event for all participants.</p><button id="t-confirm">Confirm ${h(action==='semifinals'?'advancement':action)}</button>`);
   document.querySelector('#t-confirm').onclick=()=>run(()=>action==='start'?supabase.rpc('tournament_control',{p_event:eventId,p_action:'start'}):supabase.rpc(action==='complete'?'complete_tournament':'resolve_semifinalists',{p_event_id:eventId}));
  });
 }
 function fixtures(){
  const rows=data.matches.filter(m=>filter==='all'||filter==='completed'&&m.status==='COMPLETED'||filter==='upcoming'&&!['COMPLETED','CANCELLED','FORFEITED'].includes(m.status)||m.stage===filter);
  document.querySelector('#t-fixtures').innerHTML=rows.length?rows.map(m=>{
   const innings=id=>{const i=m.innings?.find(i=>i.team_id===id);return i?`${i.runs}/${i.wickets} (${overs(i.balls_faced)} overs)`:'';};
   const result=Array.isArray(m.result)?m.result[0]:m.result;
   return `<article class="card match-card"><div class="section-head"><strong>${h(m.match_code||pretty(m.stage))} · ${h(pretty(m.stage))}</strong><span class="badge">${h(pretty(m.status))}</span></div><div class="match-teams"><div><h3>${h(team(m.home_team_id))}</h3><strong>${h(innings(m.home_team_id))}</strong></div><span class="muted">vs</span><div><h3>${h(team(m.away_team_id))}</h3><strong>${h(innings(m.away_team_id))}</strong></div></div><p class="meta">${h(when(m.scheduled_start))}</p>${result?.result_summary?`<p>${h(result.result_summary)} · ${h(pretty(m.result_status))}</p>`:''}<div class="form-actions">${event.status==='IN_PROGRESS'&&cricket&&(data.manage||data.score)&&scoreable(m)?`<button data-score="${h(m.id)}">Enter cricket result</button>`:''}${data.manage&&['REGISTRATION_CLOSED','IN_PROGRESS'].includes(event.status)&&['DRAFT','READY','SCHEDULED','POSTPONED'].includes(m.status)&&m.result_status==='PENDING'?`<button class="secondary" data-schedule="${h(m.id)}">Schedule match</button>`:''}</div></article>`;
  }).join(''):'<div class="empty"><h3>No matches to show</h3><p>Try another filter or return when fixtures are available.</p></div>';
  document.querySelectorAll('[data-score]').forEach(b=>b.onclick=()=>scoreForm(data.matches.find(m=>m.id===b.dataset.score)));
  document.querySelectorAll('[data-schedule]').forEach(b=>b.onclick=()=>scheduleForm(data.matches.find(m=>m.id===b.dataset.schedule)));
 }
 function editor(html){const el=document.querySelector('#t-editor');el.innerHTML=`<section class="card tournament-editor">${html}<p><button class="quiet" id="t-cancel">Cancel</button></p><div id="t-edit-message" aria-live="polite"></div></section>`;document.querySelector('#t-cancel').onclick=()=>el.innerHTML='';el.scrollIntoView({behavior:'smooth',block:'center'});el.querySelector('input,button')?.focus();}
 function error(message){const el=document.querySelector('#t-edit-message')||document.querySelector('#t-message');if(el)el.innerHTML=`<div class="notice error">${h(message)}</div>`;}
 async function refresh(note=''){try{data=await load();draw(note);}catch(e){error(e.message||'Could not refresh. Try again.');}}
 async function run(fn){document.querySelectorAll('#t-editor button').forEach(b=>b.disabled=true);try{if(demo)throw new Error('This tour is read-only for tournament controls. Sign in to manage a real event.');unwrap(await fn());await refresh('Tournament updated.');}catch(e){if(location.hash===route){error(e.message||'Could not save. Refresh and try again.');document.querySelectorAll('#t-editor button').forEach(b=>b.disabled=false);}}}
 function scoreForm(m){
  editor(`<h2>Record ${h(m.match_code||'match')} result</h2><p>The home team bats first; the away team bats second. Enter completed innings totals. Confirming locks this result and updates standings or knockout advancement.</p><form id="t-score-form"><div class="score-grid">${['home','away'].map(side=>`<fieldset><legend>${h(team(m[side+'_team_id']))} · ${side==='home'?'1st':'2nd'} innings</legend>${[['runs','Runs',100000,0],['wickets','Wickets',10,0],['balls','Balls faced',600,1]].map(([key,label,max,min])=>`<label class="field">${label}<input name="${side}_${key}" type="number" min="${min}" max="${max}" step="1" required></label>`).join('')}</fieldset>`).join('')}</div><label class="field">Maximum balls per innings<input name="max_balls" type="number" min="1" max="600" step="1" value="48" required></label><p class="muted">Use balls, not decimal overs: 7.5 overs = 47 balls.</p><label class="consent"><input type="checkbox" required> I have checked both innings. Confirm this final result.</label><p><button type="submit">Confirm result</button></p></form>`);
  document.querySelector('#t-score-form').onsubmit=e=>{e.preventDefault();try{const p=scorePayload(Object.fromEntries(new FormData(e.currentTarget)),m);run(()=>supabase.rpc('record_cricket_result',p));}catch(e){error(e.message);}};
 }
 function scheduleForm(m){
  const zone=Intl.DateTimeFormat().resolvedOptions().timeZone;
  editor(`<h2>Schedule ${h(m.match_code||'match')}</h2><p>Enter times in your device timezone: ${h(zone)}. Match lists display America/Chicago. Existing venue and team-rest checks apply.</p><form id="t-schedule-form"><label class="field">Start<input name="start" type="datetime-local" value="${h(local(m.scheduled_start))}" required></label><label class="field">End<input name="end" type="datetime-local" value="${h(local(m.scheduled_end))}" required></label><button type="submit">Save schedule</button></form>`);
  document.querySelector('#t-schedule-form').onsubmit=e=>{e.preventDefault();const v=Object.fromEntries(new FormData(e.currentTarget));try{const start=new Date(v.start).toISOString(),end=new Date(v.end).toISOString();if(end<=start)throw new Error('End must be after start.');run(()=>supabase.rpc('tournament_control',{p_event:eventId,p_action:'schedule',p_data:{match_id:m.id,start,end,expected_updated_at:m.updated_at}}));}catch(e){error(e.message);}};
 }
 draw();
}
