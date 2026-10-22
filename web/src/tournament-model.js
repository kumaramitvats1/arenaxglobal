export const scoreable=m=>['DRAFT','SCHEDULED','READY','IN_PROGRESS'].includes(m.status)&&m.result_status==='PENDING'&&!!m.home_team_id&&!!m.away_team_id&&['GROUP','SEMIFINAL','FINAL','THIRD_PLACE'].includes(m.stage);
export const overs=balls=>`${Math.floor(Number(balls)/6)}.${Number(balls)%6}`;
export function scorePayload(values,match){
 const payload={p_match_id:match.id};
 for(const field of ['home_runs','home_wickets','home_balls','away_runs','away_wickets','away_balls','max_balls']){
  const raw=values[field];const n=Number(raw);
  if(raw===''||raw==null||!Number.isSafeInteger(n)||n<0)throw new Error('Enter a whole number in every score field.');
  payload['p_'+field]=n;
 }
 if(payload.p_home_wickets>10||payload.p_away_wickets>10)throw new Error('Wickets must be between 0 and 10.');
 if(payload.p_max_balls<1||payload.p_max_balls>600||payload.p_home_balls<1||payload.p_away_balls<1||payload.p_home_balls>payload.p_max_balls||payload.p_away_balls>payload.p_max_balls)throw new Error('Balls faced must be between 1 and the match maximum (up to 600).');
 if(payload.p_home_runs>100000||payload.p_away_runs>100000)throw new Error('Runs exceed the supported limit.');
 if(match.stage!=='GROUP'&&payload.p_home_runs===payload.p_away_runs)throw new Error('Knockout ties require a resolved winner; tie-break entry is not supported yet.');
 return payload;
}
export function progression(matches){
 const groups=matches.filter(m=>m.stage==='GROUP'),semis=matches.filter(m=>m.stage==='SEMIFINAL'),finals=matches.filter(m=>m.stage==='FINAL');
 const finished=m=>m.status==='COMPLETED'&&m.result_status==='CONFIRMED';
 return {
  semifinals:groups.length>0&&groups.every(finished)&&semis.length===2&&semis.every(m=>!m.home_team_id&&!m.away_team_id&&m.result_status==='PENDING'),
  complete:finals.length===1&&finished(finals[0])&&!!finals[0].winner_team_id&&matches.filter(m=>m.stage!=='FRIENDLY'&&m.stage!=='OTHER').every(m=>['COMPLETED','CANCELLED','FORFEITED'].includes(m.status))
 };
}
