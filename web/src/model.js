export const escapeHTML=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
export function workspaces({profile,roles=[],staff=[],captainTeams=[]}){
 if(profile?.account_status!=='ACTIVE')return [];
 const active=roles.filter(r=>r.status==='ACTIVE');
 return [...(active.some(r=>r.role==='SUPER_ADMIN')?['admin','organizer']:active.some(r=>r.role==='ORGANIZER')?['organizer']:[]),...(captainTeams.length?['captain']:[]),...(staff.some(s=>['ASSIGNED','CONFIRMED'].includes(s.status))?['staff']:[]),'player'];
}
export function safeRoute(hash){return /^#\/(dashboard|events|profile|enrollment|tournament|check-in|(?:event|enrollment|tournament|check-in)\/[a-zA-Z0-9-]+)$/.test(hash)?hash:'#/dashboard';}
export const labels={admin:'Super Admin',organizer:'Organizer',captain:'Captain',staff:'Event Staff',player:'Player'};
export const pretty=v=>String(v??'').toLowerCase().replaceAll('_',' ').replace(/\b\w/g,c=>c.toUpperCase());
export function calendarDate(s){if(!s)return 'Dates to be announced';return new Intl.DateTimeFormat('en-GB',{day:'numeric',month:'short',year:'numeric',timeZone:'UTC'}).format(new Date(s+'T12:00:00Z'));}
