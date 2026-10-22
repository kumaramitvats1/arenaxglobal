import {escapeHTML as h} from './model.js';
import {fixturePlan} from './fixture-model.js';
export function fixtureSetup({teams,editor,submit}){
 const names=new Map(teams.map(t=>[t.id,t.team_name]));
 const assignments=Object.fromEntries(teams.map((t,i)=>[t.id,i%2?'B':'A']));
 function form(){
  editor(`<h2>Set up cricket fixtures</h2><p>Two round-robin groups. Each team plays every other team in its group once. The top two advance to semifinals, then the final.</p><p>All approved registered teams must be included. This format supports 4–16 teams with balanced groups. Match dates are scheduled separately.</p><form id="fixture-form">${teams.map(t=>`<label class="field">${h(t.team_name)}<select name="${h(t.id)}"><option value="A" ${assignments[t.id]==='A'?'selected':''}>Group A</option><option value="B" ${assignments[t.id]==='B'?'selected':''}>Group B</option></select></label>`).join('')}<div id="fixture-error" class="notice error" hidden role="alert"></div><button type="submit">Review fixtures</button></form>`);
  document.querySelector('#fixture-form').onsubmit=e=>{e.preventDefault();Object.assign(assignments,Object.fromEntries(new FormData(e.currentTarget)));try{review(fixturePlan(teams,assignments));}catch(error){const el=document.querySelector('#fixture-error');el.hidden=false;el.textContent=error.message;}};
 }
 function review(plan){
  editor(`<h2>Review ${plan.total} cricket fixtures</h2><div class="score-grid">${[['A',plan.a],['B',plan.b]].map(([label,ids])=>`<section><h3>Group ${label}</h3><ul>${ids.map(id=>`<li>${h(names.get(id))}</li>`).join('')}</ul></section>`).join('')}</div><div class="table-wrap"><table><thead><tr><th>Group</th><th>Home / first innings</th><th>Away / second innings</th></tr></thead><tbody>${plan.groupMatches.map(m=>`<tr><td>${m.group}</td><td>${h(names.get(m.home))}</td><td>${h(names.get(m.away))}</td></tr>`).join('')}</tbody></table></div><p><strong>SF1:</strong> Group A #1 vs Group B #2<br><strong>SF2:</strong> Group B #1 vs Group A #2<br><strong>Final:</strong> SF1 winner vs SF2 winner</p><p>Group rankings follow the existing points, net run rate, wins and team-name tie-break order. Teams shown first bat first in the current score-entry model.</p><p>Generating saves these groups and fixtures once. Existing brackets cannot be replaced here. Payment status is not changed.</p><div class="form-actions"><button id="fixture-save">Generate ${plan.total} fixtures</button><button class="secondary" id="fixture-back">Edit groups</button></div>`);
  document.querySelector('#fixture-back').onclick=form;
  document.querySelector('#fixture-save').onclick=()=>submit(plan);
 }
 form();
}
