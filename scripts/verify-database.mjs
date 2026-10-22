import fs from 'node:fs';
import assert from 'node:assert/strict';
import { PGlite } from '@electric-sql/pglite';
import { pgcrypto } from '@electric-sql/pglite/contrib/pgcrypto';

// Disposable PostgreSQL runtime. These minimal Auth shims are ONLY for SQL
// tests: they do not replace Supabase Auth, JWT signature or HTTP integration.
const db = new PGlite({ extensions: { pgcrypto } });
try {
 await db.exec(`
 create role anon nologin;
 create role authenticated nologin;
 create role service_role nologin bypassrls;
 create schema auth;
 create table auth.users(id uuid primary key, email text, raw_user_meta_data jsonb default '{}');
 create function auth.uid() returns uuid language sql stable as $$
 select coalesce(nullif(current_setting('request.jwt.claim.sub',true),''),
 nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'sub')::uuid; $$;
 grant usage on schema auth to anon,authenticated,service_role;
 `);
 await db.exec(fs.readFileSync('supabase/baselines/legacy_through_016.sql','utf8'));
 console.log('PASS: legacy baseline restores on empty PostgreSQL');
 for (const file of fs.readdirSync('supabase/migrations').filter(x=>x.endsWith('.sql')).sort()) {
   await db.exec(fs.readFileSync('supabase/migrations/'+file,'utf8'));
   console.log('PASS: migration '+file);
 }
 // Development fixture required by the preserved 017 regression suite.
 await db.exec(`
 insert into auth.users(id,email) values
 ('3514e1cc-fca6-478b-a760-cb83eefac27e','admin@example.test'),
 ('a289ed2b-99c9-4aad-affc-d3ca89ebcfbb','player@example.test');
 do $$ declare o uuid; s uuid; begin
 insert into public.organizations(name,slug) values('ArenaX Test','arenax-test') returning id into o;
 insert into public.sports(name,participation_type) values('Cricket','TEAM') returning id into s;
 insert into public.user_roles(user_id,organization_id,role) values('3514e1cc-fca6-478b-a760-cb83eefac27e',o,'SUPER_ADMIN');
 insert into public.events(organization_id,sport_id,event_name,start_date,end_date,registration_type,status)
 values(o,s,'ArenaX India States Cricket Cup 2027',current_date,current_date,'TEAM','COMPLETED');
 end; $$;
 `);
 for (const path of ['outputs/017_verification.sql','supabase/tests/018_security.sql','supabase/tests/019_event_setup.sql','supabase/tests/020_enrollment.sql','supabase/tests/021_tournament.sql']) {
   const results=await db.exec(fs.readFileSync(path,'utf8'));
   const summary=results.flatMap(r=>r.rows).find(r=>r.verification)?.verification;
   assert.ok(summary?.passed>0,'No verification summary: '+path);
   console.log(JSON.stringify({suite:path,...summary}));
 }
 const final = await db.query('select count(*)::int as n from public.events');
 assert.equal(final.rows[0].n,1,'Transactional test fixtures leaked');
 console.log('PASS: no test fixtures remain after rollback');
} catch (error) {
 console.error(error.message);
 if(error.detail) console.error(error.detail);
 if(error.where) console.error(error.where);
 process.exitCode=1;
} finally { await db.close(); }
