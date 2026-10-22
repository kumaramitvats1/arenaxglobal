export function fixturePlan(teams,assignments){
 if(teams.length<4||teams.length>16)throw new Error('This format needs 4–16 approved teams.');
 const ids=teams.map(t=>t.id);
 if(new Set(ids).size!==ids.length||ids.some(id=>!['A','B'].includes(assignments[id])))throw new Error('Assign every approved team to a group.');
 const a=ids.filter(id=>assignments[id]==='A'),b=ids.filter(id=>assignments[id]==='B');
 if(a.length<2||b.length<2||a.length>8||b.length>8||Math.abs(a.length-b.length)>1)throw new Error('Keep groups balanced, with 2–8 teams in each group.');
 const pairs=group=>group.flatMap((home,i)=>group.slice(i+1).map(away=>({home,away})));
 const groupMatches=[...pairs(a).map(m=>({...m,group:'A'})),...pairs(b).map(m=>({...m,group:'B'}))];
 return {a,b,groupMatches,total:groupMatches.length+3};
}
