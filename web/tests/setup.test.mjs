import test from 'node:test';
import assert from 'node:assert/strict';
import {eventPayload} from '../src/setup.js';
const base={event_name:'Austin Cup',start_date:'2027-06-05',end_date:'2027-06-07',registration_fee:'125.50',currency:'usd',registration_type:'TEAM',pricing_model:'PER_TEAM',venue_id:''};
test('event payload uses numeric USD fee and optional venue',()=>{const v=eventPayload(base,'DRAFT');assert.equal(v.registration_fee,125.5);assert.equal(v.currency,'USD');assert.equal(v.venue_id,null);assert.equal(v.status,'DRAFT');});
test('free pricing always submits a zero fee',()=>assert.equal(eventPayload({...base,pricing_model:'FREE'},'DRAFT').registration_fee,0));
test('invalid dates and precision are rejected before saving',()=>{assert.throws(()=>eventPayload({...base,end_date:'2027-06-01'},'DRAFT'));assert.throws(()=>eventPayload({...base,registration_fee:'1.234'},'DRAFT'));});
test('individual registrations cannot use per-team pricing',()=>assert.throws(()=>eventPayload({...base,registration_type:'INDIVIDUAL'},'DRAFT')));
