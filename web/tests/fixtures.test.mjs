import test from 'node:test';import assert from 'node:assert/strict';import {fixturePlan} from '../src/fixture-model.js';
const teams=n=>Array.from({length:n},(_,i)=>({id:String(i),team_name:'Texas '+i}));
const assignment=ts=>Object.fromEntries(ts.map((t,i)=>[t.id,i%2?'B':'A']));
test('eight approved teams create twelve unique group matches plus knockouts',()=>{const ts=teams(8),p=fixturePlan(ts,assignment(ts));assert.equal(p.total,15);assert.equal(new Set(p.groupMatches.map(m=>[m.home,m.away].sort().join(':'))).size,12);assert.ok(p.groupMatches.every(m=>m.home!==m.away));});
test('minimum and odd team counts form balanced groups',()=>{for(const n of [4,5,15,16]){const ts=teams(n),p=fixturePlan(ts,assignment(ts));assert.equal(p.a.length+p.b.length,n);assert.ok(Math.abs(p.a.length-p.b.length)<=1);}});
test('missing, duplicate and unbalanced groups fail before review',()=>{const ts=teams(4);assert.throws(()=>fixturePlan(ts,{}));assert.throws(()=>fixturePlan(ts,Object.fromEntries(ts.map(t=>[t.id,'A']))));assert.throws(()=>fixturePlan([ts[0],...ts.slice(0,3)],assignment(ts)));for(const n of [0,3,17]){const ts=teams(n);assert.throws(()=>fixturePlan(ts,assignment(ts)));}});
