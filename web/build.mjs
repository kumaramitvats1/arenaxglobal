import {build} from 'esbuild';
await build({entryPoints:['src/app.js'],bundle:true,format:'esm',outfile:'dist/app.js',minify:true,target:'es2022',legalComments:'external'});
console.log('Built ArenaX portal');
