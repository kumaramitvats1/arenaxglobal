import test from 'node:test';
import assert from 'node:assert/strict';
import {activeRoster,registrationEstimate,canReopen} from '../src/enrollment.js';
const event={status:'REGISTRATION_OPEN',pricing_model:'PER_PLAYER',registration_fee:25};
const team={members:[{status:'ACTIVE',invitation:'ACCEPTED'},{status:'ACTIVE',invitation:'PENDING'},{status:'REMOVED',invitation:'ACCEPTED'}]};
test('per-player estimate excludes pending and removed players',()=>{assert.equal(activeRoster(team).length,1);assert.equal(registrationEstimate(event,team),25);});
test('per-team and free estimates retain their fee models',()=>{assert.equal(registrationEstimate({...event,pricing_model:'PER_TEAM'},team),25);assert.equal(registrationEstimate({...event,pricing_model:'FREE'},team),0);});
test('reopening is limited to unpaid registrations while open',()=>{const r={amount_paid:0,payment_status:'PENDING',registration_status:'APPROVED'};assert.equal(canReopen(r,event),true);for(const payment_status of ['PAID','PARTIALLY_PAID','REFUNDED'])assert.equal(canReopen({...r,payment_status},event),false);assert.equal(canReopen(r,{...event,status:'COMPLETED'}),false);assert.equal(canReopen({...r,registration_status:'CANCELLED'},event),false);});
