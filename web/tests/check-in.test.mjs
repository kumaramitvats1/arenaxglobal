import test from 'node:test';
import assert from 'node:assert/strict';
import QRCode from 'qrcode';
import jsQR from 'jsqr';
import {encodePass,parsePass,checkInOpen} from '../src/check-in-model.js';
import {safeRoute} from '../src/model.js';
const event='11111111-1111-4111-8111-111111111111',user='22222222-2222-4222-8222-222222222222',token='ab'.repeat(32);
test('issued pass survives actual QR encoding and image decoding',()=>{
 const text=encodePass(event,user,token),qr=QRCode.create(text,{errorCorrectionLevel:'M'}),scale=5,size=(qr.modules.size+8)*scale;
 const pixels=new Uint8ClampedArray(size*size*4).fill(255);
 for(let y=0;y<qr.modules.size;y++)for(let x=0;x<qr.modules.size;x++)if(qr.modules.get(y,x))for(let dy=0;dy<scale;dy++)for(let dx=0;dx<scale;dx++){
  const i=(((y+4)*scale+dy)*size+(x+4)*scale+dx)*4;pixels[i]=pixels[i+1]=pixels[i+2]=0;
 }
 const decoded=jsQR(pixels,size,size);assert.equal(decoded.data,text);assert.deepEqual(parsePass(decoded.data,event),{event,participant:user,token});
});
test('foreign events, malformed tokens, URLs and oversized payloads are rejected',()=>{
 for(const text of ['https://example.test','null','x'.repeat(1025),JSON.stringify({type:'arenax-check-in',v:1,event,participant:user,token:'bad'}),encodePass(user,user,token)])assert.throws(()=>parsePass(text,event));
});
test('closed event controls and authenticated return routes',()=>{
 for(const status of ['DRAFT','COMPLETED','CANCELLED'])assert.equal(checkInOpen(status),false);
 assert.equal(checkInOpen('IN_PROGRESS'),true);assert.equal(safeRoute('#/check-in/'+event),'#/check-in/'+event);
 assert.equal(safeRoute('#/check-in'),'#/check-in');
});
