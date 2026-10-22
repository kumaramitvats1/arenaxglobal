import QRCode from 'qrcode';
import jsQR from 'jsqr';
import {supabase} from './data.js';
import {escapeHTML as h,pretty} from './model.js';
import {encodePass,parsePass,checkInOpen} from './check-in-model.js';
let dispose=()=>{};
export function disposeCheckIn(){dispose();dispose=()=>{};}
const unwrap=r=>{if(r.error)throw r.error;return r.data;};
const time=s=>s?new Date(s).toLocaleString('en-US',{timeZone:'America/Chicago',dateStyle:'medium',timeStyle:'short'}):'—';
export async function checkInPage({account,demo,workspace,shell},eventId){
 const event=account.events.find(e=>e.id===eventId),route='#/check-in/'+eventId;
 if(!event){shell('<div class="empty"><h1>Event unavailable</h1><a href="#/events">Back to events</a></div>');return;}
 let stopped=false,stream=null,frame=0,scanVersion=0,expiryTimer=null,passCode=null,allowed=false,own=null,desk={rows:[],has_more:false,checked_in_count:0},search='',offset=0,filter='ALL',request=0;
 const active=()=>!stopped&&location.hash===route;
 function stopCamera(){scanVersion++;cancelAnimationFrame(frame);stream?.getTracks().forEach(t=>t.stop());stream=null;const video=document.querySelector('#check-video');if(video){video.srcObject=null;video.hidden=true;}}
 const hidden=()=>{if(document.hidden)stopCamera();};
 dispose=()=>{stopped=true;request++;stopCamera();clearInterval(expiryTimer);passCode=null;document.removeEventListener('visibilitychange',hidden);window.removeEventListener('pagehide',stopCamera);};
 document.addEventListener('visibilitychange',hidden);window.addEventListener('pagehide',stopCamera);
 function message(text,error=false){if(!active())return;const el=document.querySelector('#check-message');if(el)el.innerHTML=`<div class="notice ${error?'error':'success'}" role="status">${h(text)}</div>`;}
 shell('<div class="loading">Loading event check-in…</div>','check-in');
 async function load(){
  if(demo){allowed=['organizer','admin'].includes(workspace);account.checkIns??={};own=account.checkIns[eventId]?.find(r=>r.user_id===account.user.id)||null;return;}
  const [permission,attendance,fresh]=await Promise.all([supabase.rpc('can_check_in_event',{p_event_id:eventId}),supabase.from('event_check_ins').select('checked_in_at,check_in_method').eq('event_id',eventId).eq('participant_user_id',account.user.id).maybeSingle(),supabase.from('events').select('status').eq('id',eventId).single()]);
  allowed=unwrap(permission);own=unwrap(attendance);event.status=unwrap(fresh).status;
 }
 try{await load();}catch(e){if(active())shell(`<div class="notice error">${h(e.message||'Check-in could not be loaded.')}</div><a href="#/event/${h(eventId)}">Back to event</a>`,'check-in');return;}
 if(!active())return;
 function draw(){
  stopCamera();clearInterval(expiryTimer);passCode=null;
  shell(`<a class="textlink" href="#/event/${h(eventId)}">← Event details</a><div class="page-head"><div><span class="eyebrow">Ready for match day</span><h1>Passes & check-in</h1><p>${h(event.event_name)} · ${h(pretty(event.status))}</p></div><button class="secondary" id="check-refresh">Refresh</button></div><div id="check-message" aria-live="polite"></div>${!checkInOpen(event.status)?'<div class="notice">Check-in is closed for this event. Existing attendance remains available.</div>':''}<section class="card check-card"><h2>My event pass</h2>${own?`<div class="notice success">Checked in · ${h(time(own.checked_in_at))} · ${h(pretty(own.check_in_method))}</div>`:`<p>Show your pass to an organizer or CHECK_IN staff member. An approved registration, settled or exempt payment, and required waivers are needed.</p>${checkInOpen(event.status)?'<button id="issue-pass">Generate my QR pass</button>':''}`}<div id="my-pass"></div></section>${allowed?`<section class="card check-card"><h2>Check-in desk</h2><p>Scan a pass or search the event’s participant list. Confirm the player before recording attendance. Eligibility is checked again by the server.</p>${checkInOpen(event.status)?`<div class="form-actions"><button id="camera-start">Start camera scanner</button><button class="secondary" id="camera-stop">Stop camera</button></div><p class="muted">Camera frames and selected QR images are decoded on this device. If camera access is unavailable, use an image or paste the pass code.</p><video id="check-video" playsinline muted hidden></video><label class="field">Read QR from an image<input id="qr-image" type="file" accept="image/png,image/jpeg,image/webp"></label><form id="pass-code-form"><label class="field">Paste full pass code<textarea name="code" rows="3" maxlength="1024" autocomplete="off" required></textarea></label><button class="secondary" type="submit">Review QR check-in</button></form><div id="check-review"></div>`:''}<form id="check-search"><label class="field">Find participant<input name="search" type="search" maxlength="100" placeholder="Name, team or member code" value="${h(search)}"></label><label class="field">Attendance<select name="filter"><option value="ALL">All participants</option><option value="PENDING">Not checked in</option><option value="PRESENT">Checked in</option></select></label><button class="secondary" type="submit">Search</button></form><div id="check-directory"></div></section>`:'<div class="notice">Only organizers and assigned CHECK_IN staff can check in participants. A SCORER assignment does not grant check-in access.</div>'}<p class="muted">Attendance is recorded once per event, not per match or day. Times shown in America/Chicago. No record means not yet checked in.</p>`,'check-in');
  document.querySelector('#check-refresh').onclick=async()=>{try{await load();if(active()){draw();if(allowed)await directory();}}catch(e){message(e.message,true);}};
  document.querySelector('#issue-pass')?.addEventListener('click',issue);
  if(allowed){document.querySelector('#check-search select').value=filter;document.querySelector('#check-search').onsubmit=e=>{e.preventDefault();const f=new FormData(e.currentTarget);search=String(f.get('search')).trim();filter=String(f.get('filter'));offset=0;directory();};
   document.querySelector('#camera-start')?.addEventListener('click',camera);document.querySelector('#camera-stop')?.addEventListener('click',stopCamera);
   document.querySelector('#qr-image')?.addEventListener('change',imageScan);
   document.querySelector('#pass-code-form')?.addEventListener('submit',e=>{e.preventDefault();const input=e.currentTarget.elements.code;const value=input.value;input.value='';reviewCode(value);});
  }
 }
 async function issue(){
  const button=document.querySelector('#issue-pass');button.disabled=true;passCode=null;clearInterval(expiryTimer);document.querySelector('#my-pass').innerHTML='';
  try{
   if(demo)throw new Error('Sample players do not have live passes. Sign in with an eligible registration to generate your QR.');
   const rows=unwrap(await supabase.rpc('issue_event_check_in_qr',{p_event_id:eventId,p_participant_user_id:account.user.id}));if(!active())return;
   const row=rows?.[0];if(!row)throw new Error('Pass could not be issued.');
   passCode=encodePass(eventId,account.user.id,row.qr_token);
   document.querySelector('#my-pass').innerHTML=`<canvas id="pass-qr" role="img" aria-label="Your private event check-in QR code"></canvas><p>Valid until ${h(time(row.expires_at))} (America/Chicago). A new pass invalidates the previous pass.</p><details><summary>Pass code for staff scanner fallback</summary><textarea id="private-pass-code" readonly aria-label="Private pass code" spellcheck="false"></textarea></details><p>Keep this pass private. It is stored only on this screen.</p>`;
   document.querySelector('#private-pass-code').value=passCode;
   await QRCode.toCanvas(document.querySelector('#pass-qr'),passCode,{width:300,margin:4,errorCorrectionLevel:'M'});
   const expiry=Date.parse(row.expires_at);expiryTimer=setInterval(()=>{if(!active()||Date.now()>=expiry){clearInterval(expiryTimer);passCode=null;if(active())document.querySelector('#my-pass').innerHTML='<div class="notice">Pass expired. Generate a new pass.</div>'; }},1000);
   button.textContent='Replace my QR pass';message('Pass ready. Show it to authorized check-in staff.');
  }catch(e){passCode=null;if(active())document.querySelector('#my-pass').innerHTML='';message(e.message||'Your pass could not be issued.',true);}finally{if(active())button.disabled=false;}
 }
 async function directory(){
  const version=++request;const target=document.querySelector('#check-directory');target.innerHTML='<p>Loading participants…</p>';
  try{
   if(demo){const saved=account.checkIns[eventId]||[];const rows=[{user_id:'sample-player',name:'Alex Morgan',teams:'Austin Aces'},{user_id:'sample-guest',name:'Jordan Lee',teams:'Dallas Stars'}].map(r=>({...r,...saved.find(s=>s.user_id===r.user_id)})).filter(r=>(r.name+' '+r.teams).toLowerCase().includes(search.toLowerCase())&&(filter==='ALL'||filter==='PRESENT'&&r.checked_in_at||filter==='PENDING'&&!r.checked_in_at));desk={rows,has_more:false,checked_in_count:saved.length};}
   else desk=unwrap(await supabase.rpc('get_event_check_in_desk',{p_event:eventId,p_search:search,p_offset:offset,p_filter:filter}));
   if(!active()||version!==request)return;
   target.innerHTML=`<p><strong>${desk.checked_in_count}</strong> checked in for this event</p><div class="table-wrap"><table><thead><tr><th>Participant</th><th>Team</th><th>Attendance</th><th>Checked in by</th><th>Action</th></tr></thead><tbody>${desk.rows.map(r=>`<tr><td>${h(r.name)}<br><small>${h(r.user_id)}</small></td><td>${h(r.teams||'Individual')}</td><td>${r.checked_in_at?`${h(time(r.checked_in_at))}<br>${h(pretty(r.check_in_method))}`:'Not checked in'}</td><td>${h(r.operator_name||'—')}</td><td>${!r.checked_in_at&&checkInOpen(event.status)?`<button class="secondary" data-manual="${h(r.user_id)}">Manual check-in</button>`:'—'}</td></tr>`).join('')||'<tr><td colspan="5">No matching participants.</td></tr>'}</tbody></table></div><div class="form-actions"><button class="secondary" id="check-prev" ${offset===0?'disabled':''}>Previous</button><button class="secondary" id="check-next" ${desk.has_more?'':'disabled'}>Next</button></div>`;
   target.querySelector('#check-prev').onclick=()=>{offset=Math.max(0,offset-50);directory();};target.querySelector('#check-next').onclick=()=>{offset+=50;directory();};
   target.querySelectorAll('[data-manual]').forEach(b=>b.onclick=()=>review(desk.rows.find(r=>r.user_id===b.dataset.manual),'MANUAL',null));
  }catch(e){if(active()&&version===request){target.innerHTML='<p>Participant list could not be loaded. Search again to retry.</p>';message(e.message,true);}}
 }
 async function reviewCode(text){
  stopCamera();try{if(demo)throw new Error('Use manual check-in in the sample workspace.');const pass=parsePass(text,eventId);const result=unwrap(await supabase.rpc('get_event_check_in_desk',{p_event:eventId,p_search:pass.participant,p_offset:0,p_filter:'ALL'}));if(!active())return;const person=result.rows.find(r=>r.user_id===pass.participant);if(!person)throw new Error('Participant is not listed for this event.');review(person,'QR',pass.token);}catch(e){message(e.message||'Pass could not be read.',true);}
 }
 function review(person,method,token){
  stopCamera();if(!person)return;
  const target=document.querySelector('#check-review');target.innerHTML=`<section class="check-review"><h3>Confirm ${h(pretty(method))} check-in</h3><p><strong>${h(person.name)}</strong> · ${h(person.teams||'Individual registration')}</p><p>Verify this is the participant in front of you.</p>${person.checked_in_at?'<p>This participant is already checked in. Their original record is preserved.</p>':'<button id="confirm-check">Confirm attendance</button>'}<button class="secondary" id="cancel-check">Cancel</button></section>`;
  target.scrollIntoView({behavior:'smooth',block:'center'});document.querySelector('#cancel-check').onclick=()=>{token=null;target.innerHTML='';};
  document.querySelector('#confirm-check')?.addEventListener('click',async e=>{
   e.currentTarget.disabled=true;
   try{
    if(demo){const saved=account.checkIns[eventId]??=[];if(!saved.some(r=>r.user_id===person.user_id))saved.push({...person,checked_in_at:new Date().toISOString(),check_in_method:method,operator_name:'Sample organizer'});}
    else unwrap(await supabase.rpc('check_in_event_participant',{p_event_id:eventId,p_participant_user_id:person.user_id,p_method:method,p_qr_token:token}));
    token=null;if(active()){target.innerHTML='';message(demo?'Sample attendance recorded in memory only.':'Attendance recorded. The first check-in time and operator are preserved.');await directory();}
   }catch(error){token=null;if(active()){target.innerHTML='';message(error.message||'Check-in could not be recorded. Search or scan again.',true);}}
  });
 }
 async function camera(){
  stopCamera();if(demo){message('Use manual check-in to try the sample desk. Camera scanning requires a real event pass.',true);return;}
  const version=scanVersion;
  try{
   if(!navigator.mediaDevices?.getUserMedia)throw new Error('Camera is unavailable in this browser. Use a QR image or pass code.');
   const media=await navigator.mediaDevices.getUserMedia({video:{facingMode:{ideal:'environment'}},audio:false});
   if(!active()||version!==scanVersion){media.getTracks().forEach(t=>t.stop());return;}
   stream=media;const video=document.querySelector('#check-video');video.hidden=false;video.srcObject=media;await video.play();
   if(!active()||version!==scanVersion){stopCamera();return;}
   message('Point the camera at the participant’s ArenaX QR pass.');
   const canvas=document.createElement('canvas'),context=canvas.getContext('2d',{willReadFrequently:true});let last=0;
   function tick(now){if(!active()||!stream||version!==scanVersion)return;if(video.readyState>=2&&now-last>200){last=now;const scale=Math.min(1,800/video.videoWidth);canvas.width=video.videoWidth*scale;canvas.height=video.videoHeight*scale;context.drawImage(video,0,0,canvas.width,canvas.height);const pixels=context.getImageData(0,0,canvas.width,canvas.height);const code=jsQR(pixels.data,pixels.width,pixels.height);if(code){reviewCode(code.data);return;}}frame=requestAnimationFrame(tick);}
   frame=requestAnimationFrame(tick);
  }catch(e){stopCamera();message(e.name==='NotAllowedError'?'Camera permission was declined. Use a QR image or paste the pass code.':e.message||'Camera could not start.',true);}
 }
 async function imageScan(e){
  stopCamera();const file=e.target.files?.[0];e.target.value='';if(!file)return;
  let bitmap;
  try{
   if(file.size>10*1024*1024)throw new Error('Choose a QR image smaller than 10 MB.');
   bitmap=await createImageBitmap(file);if(!active())return;
   const scale=Math.min(1,1600/Math.max(bitmap.width,bitmap.height));const canvas=document.createElement('canvas');canvas.width=bitmap.width*scale;canvas.height=bitmap.height*scale;
   const ctx=canvas.getContext('2d',{willReadFrequently:true});ctx.drawImage(bitmap,0,0,canvas.width,canvas.height);const pixels=ctx.getImageData(0,0,canvas.width,canvas.height);const code=jsQR(pixels.data,pixels.width,pixels.height);
   if(!code)throw new Error('No QR code found. Try a clearer image or paste the pass code.');await reviewCode(code.data);
  }catch(error){message(error.message||'QR image could not be read.',true);}finally{bitmap?.close();}
 }
 draw();if(allowed)await directory();
}
