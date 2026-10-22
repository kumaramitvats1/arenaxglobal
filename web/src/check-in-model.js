const uuid=/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export function parsePass(text,eventId){
 if(typeof text!=='string'||text.length>1024)throw new Error('This is not a valid ArenaX pass.');
 let pass;try{pass=JSON.parse(text);}catch{throw new Error('Scan an ArenaX event pass or paste its full pass code.');}
 if(pass?.type!=='arenax-check-in'||pass.v!==1||!uuid.test(pass.event)||!uuid.test(pass.participant)||typeof pass.token!=='string'||!/^[0-9a-f]{64}$/.test(pass.token))throw new Error('This is not a valid ArenaX pass.');
 if(pass.event!==eventId)throw new Error('This pass belongs to a different event. Open that event’s check-in desk.');
 return {event:pass.event,participant:pass.participant,token:pass.token};
}
export function encodePass(event,participant,token){const text=JSON.stringify({type:'arenax-check-in',v:1,event,participant,token});parsePass(text,event);return text;}
export const checkInOpen=status=>!['DRAFT','CANCELLED','COMPLETED'].includes(status);
