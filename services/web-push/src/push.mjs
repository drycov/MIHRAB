// RFC 8291 / RFC 8188 single-record aes128gcm, RFC 8292 VAPID.
import {validSubscription} from './validation.mjs';
const enc = new TextEncoder();
export const b64 = bytes => btoa(String.fromCharCode(...bytes)).replaceAll('+','-').replaceAll('/','_').replace(/=+$/,'');
export const unb64 = s => Uint8Array.from(atob(s.replaceAll('-','+').replaceAll('_','/') + '='.repeat((4-s.length%4)%4)), c=>c.charCodeAt(0));
const concat = (...parts) => { const out = new Uint8Array(parts.reduce((n,p)=>n+p.length,0)); let at=0; for(const p of parts){out.set(p,at);at+=p.length;} return out; };
async function hkdf(ikm,salt,info,length) {
 const k=await crypto.subtle.importKey('raw',ikm,'HKDF',false,['deriveBits']);
 return new Uint8Array(await crypto.subtle.deriveBits({name:'HKDF',hash:'SHA-256',salt,info},k,length*8));
}
export async function encryptPayload(subscription,payload) {
 const ua=unb64(subscription.keys.p256dh),auth=unb64(subscription.keys.auth);
 if(ua.length!==65 || ua[0]!==4 || auth.length!==16) throw new Error('Invalid keys');
 const pair=await crypto.subtle.generateKey({name:'ECDH',namedCurve:'P-256'},true,['deriveBits']);
 const remote=await crypto.subtle.importKey('raw',ua,{name:'ECDH',namedCurve:'P-256'},false,[]);
 const sender=new Uint8Array(await crypto.subtle.exportKey('raw',pair.publicKey));
 const shared=new Uint8Array(await crypto.subtle.deriveBits({name:'ECDH',public:remote},pair.privateKey,256));
 const ikm=await hkdf(shared,auth,concat(enc.encode('WebPush: info\0'),ua,sender),32);
 const salt=crypto.getRandomValues(new Uint8Array(16));
 const key=await hkdf(ikm,salt,enc.encode('Content-Encoding: aes128gcm\0'),16);
 const nonce=await hkdf(ikm,salt,enc.encode('Content-Encoding: nonce\0'),12);
 const plain=concat(enc.encode(JSON.stringify(payload)),new Uint8Array([2]));
 if(plain.length>3993) throw new Error('Payload too large');
 const aes=await crypto.subtle.importKey('raw',key,'AES-GCM',false,['encrypt']);
 const cipher=new Uint8Array(await crypto.subtle.encrypt({name:'AES-GCM',iv:nonce},aes,plain));
 const header=new Uint8Array(21);header.set(salt);new DataView(header.buffer).setUint32(16,4096);header[20]=sender.length;
 return concat(header,sender,cipher);
}
export async function vapid(endpoint,env) {
 const pub=unb64(env.VAPID_PUBLIC_KEY), priv=unb64(env.VAPID_PRIVATE_KEY);
 if(pub.length!==65 || pub[0]!==4 || priv.length!==32 || !/^(mailto:|https:\/\/)/.test(env.VAPID_SUBJECT||'')) throw new Error('Invalid VAPID configuration');
 const jwk={kty:'EC',crv:'P-256',x:b64(pub.slice(1,33)),y:b64(pub.slice(33)),d:b64(priv),ext:true};
 const key=await crypto.subtle.importKey('jwk',jwk,{name:'ECDSA',namedCurve:'P-256'},false,['sign']);
 const jwt=b64(enc.encode(JSON.stringify({typ:'JWT',alg:'ES256'})))+'.'+b64(enc.encode(JSON.stringify({aud:new URL(endpoint).origin,exp:Math.floor(Date.now()/1000)+3600,sub:env.VAPID_SUBJECT})));
 const signature=await crypto.subtle.sign({name:'ECDSA',hash:'SHA-256'},key,enc.encode(jwt));
 return 'vapid t='+jwt+'.'+b64(new Uint8Array(signature))+', k='+env.VAPID_PUBLIC_KEY;
}
export async function sendPush(subscription,payload,env) {
 if(!validSubscription(subscription)) throw new Error('Invalid endpoint');
 const body=await encryptPayload(subscription,payload);
 const response=await fetch(subscription.endpoint,{method:'POST',redirect:'error',signal:AbortSignal.timeout(10000),headers:{Authorization:await vapid(subscription.endpoint,env),'Content-Encoding':'aes128gcm','Content-Type':'application/octet-stream',TTL:'120',Urgency:'high'},body});
 await response.body?.cancel();
 return response.status;
}
