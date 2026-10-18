import fs from 'node:fs';
// Catalog export contains schema metadata only; no user rows or credentials.
const {catalog: c, details: d} = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const q = s => '"' + s.replaceAll('"', '""') + '"';
const literal = s => "'" + s.replaceAll("'", "''") + "'";
const excluded = new Set(['event_check_ins']);
const legacy = o => o.schema === 'public' && !excluded.has(o.table ?? o.name);
const functions = c.functions.filter(f => f.schema === 'public' && !['can_check_in_event','issue_event_check_in_qr','check_in_event_participant'].includes(f.name));
if (d.types?.length || c.tables.some(t => t.kind !== 'r')) throw new Error('Unsupported catalog object: use pg_dump instead');
const sql = [
 '-- Reconstructed legacy schema through 016A, captured 2026-10-18.',
 '-- Fresh Supabase database ONLY. Not a historical sequence of migrations.',
 '-- Apply before migrations 017 onward. Contains no production/test user data.',
 'begin;',
 "do $$ begin if to_regclass('public.organizations') is not null then raise exception 'Legacy baseline requires an empty application schema'; end if; end; $$;",
 'set local search_path = public, extensions;',
 'set local check_function_bodies = off;',
 'create schema if not exists extensions;',
 'create extension if not exists pgcrypto with schema extensions;'
];
for (const t of c.tables.filter(legacy).sort((a,b)=>a.name.localeCompare(b.name))) {
 const columns = d.columns.filter(x=>x.schema===t.schema && x.table===t.name);
 if (columns.some(x=>x.identity || x.generated)) throw new Error('Unsupported generated column');
 sql.push(`create table public.${q(t.name)} (\n${columns.map(x=>'  '+q(x.name)+' '+x.type+(x.default?' default '+x.default:'')+(x.notnull?' not null':'')).join(',\n')}\n);`);
 sql.push(`alter table public.${q(t.name)} ${t.rls?'enable':'disable'} row level security;`);
 if(t.force_rls) sql.push(`alter table public.${q(t.name)} force row level security;`);
}
for (const x of d.constraints.filter(legacy).sort((a,b)=>(a.type==='f')-(b.type==='f') || a.name.localeCompare(b.name))) sql.push(`alter table public.${q(x.table)} add constraint ${q(x.name)} ${x.definition};`);
for (const x of d.indexes.filter(legacy)) sql.push(x.definition+';');
for (const f of functions) sql.push(f.definition.trim()+';');
for (const p of d.policies.filter(p=>p.schemaname==='public' && !excluded.has(p.tablename))) {
 sql.push(`create policy ${q(p.policyname)} on public.${q(p.tablename)} as ${p.permissive} for ${p.cmd} to ${p.roles.map(r=>r==='public'?'public':q(r)).join(', ')}${p.qual?' using ('+p.qual+')':''}${p.with_check?' with check ('+p.with_check+')':''};`);
}
for (const t of c.triggers) sql.push(t.definition+';');
for (const t of c.tables.filter(legacy)) sql.push(`revoke all on public.${q(t.name)} from public, anon, authenticated, service_role;`);
for (const g of d.grants.filter(g=>g.table_schema==='public' && !excluded.has(g.table_name) && g.grantee!=='postgres')) sql.push(`grant ${g.privilege_type} on public.${q(g.table_name)} to ${g.grantee==='PUBLIC'?'public':q(g.grantee)}${g.is_grantable==='YES'?' with grant option':''};`);
for (const f of functions) {
 const signature = `public.${q(f.name)}(${f.identity_args})`;
 sql.push(`revoke all on function ${signature} from public, anon, authenticated, service_role;`);
 for(const entry of f.acl ?? []) {
   const [role,permissions] = entry.split('=');
   if(role==='postgres') continue;
   if(permissions.startsWith('X')) sql.push(`grant execute on function ${signature} to ${role?q(role):'public'};`);
 }
}
sql.push('grant usage on schema public to anon, authenticated, service_role;','commit;','');
fs.mkdirSync('supabase/baselines',{recursive:true});
fs.writeFileSync('supabase/baselines/legacy_through_016.sql',sql.join('\n\n').replaceAll('\r',''));
console.log(JSON.stringify({tables:c.tables.filter(legacy).length,functions:functions.length,policies:d.policies.filter(p=>p.schemaname==='public' && !excluded.has(p.tablename)).length}));
