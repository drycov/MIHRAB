import {validSubscription, validSchedule} from './validation.mjs';

const hash = async value => Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(value))), b => b.toString(16).padStart(2,'0')).join('');
const token = () => Array.from(crypto.getRandomValues(new Uint8Array(32)), b => b.toString(16).padStart(2,'0')).join('');
const now = () => Date.now();

async function body(request) {
  if (!request.headers.get('content-type')?.startsWith('application/json')) throw new Error('Invalid content type');
  const reader = request.body?.getReader();
  if (!reader) throw new Error('Missing body');
  const decoder = new TextDecoder();
  let size = 0, text = '';
  try {
    while (true) {
      const {done,value} = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > 32768) { await reader.cancel(); throw new Error('Body too large'); }
      text += decoder.decode(value,{stream:true});
    }
    return JSON.parse(text + decoder.decode());
  } finally { reader.releaseLock(); }
}

export default {
  async fetch(request, env) {
    const origin = request.headers.get('origin');
    const allowed = (env.ALLOWED_ORIGINS || '').split(',').map(s=>s.trim()).filter(Boolean);
    const headers = {'Cache-Control':'no-store','Vary':'Origin','Content-Type':'application/json'};
    if (origin && allowed.includes(origin)) Object.assign(headers, {
      'Access-Control-Allow-Origin':origin,
      'Access-Control-Allow-Methods':'GET,POST,PUT,DELETE,OPTIONS',
      'Access-Control-Allow-Headers':'Content-Type,Authorization'
    });
    const json = (value,status=200)=>new Response(JSON.stringify(value),{status,headers});
    const path = new URL(request.url).pathname;
    if (path === '/health' && request.method === 'GET') return json({status:'ok',deliveryEnabled:false});
    if (!origin || !allowed.includes(origin)) return json({error:'origin_not_allowed'},403);
    if (request.method === 'OPTIONS') return new Response(null,{status:204,headers});
    // Closed by default. An edge rate limit and verified consent are required before enabling.
    if (env.ENABLE_REGISTRATION !== 'true' || !env.VAPID_PUBLIC_KEY) return json({error:'not_configured'},503);
    try {
      if (path === '/v1/vapid-public-key' && request.method === 'GET') return json({key:env.VAPID_PUBLIC_KEY});
      if (path === '/v1/subscriptions' && request.method === 'POST') {
        const data = await body(request);
        if (!validSubscription(data?.subscription) || !['ru','kk','ar','en'].includes(data.locale) ||
            data.consent !== true) return json({error:'invalid_subscription'},400);
        const id = crypto.randomUUID(), secret = token(), at = now();
        const s = data.subscription;
        const result = await env.DB.prepare('INSERT OR IGNORE INTO subscriptions (id,token_hash,endpoint,p256dh,auth,locale,expires_at,created_at) VALUES (?,?,?,?,?,?,?,?)')
          .bind(id,await hash(secret),s.endpoint,s.keys.p256dh,s.keys.auth,data.locale,at+30*86400000,at).run();
        if (!result.meta.changes) return json({error:'subscription_exists'},409);
        return json({id,token:secret},201);
      }
      const match = /^\/v1\/subscriptions\/([a-f0-9-]{36})(\/schedule)?$/.exec(path);
      if (!match) return json({error:'not_found'},404);
      const secret = request.headers.get('authorization')?.match(/^Bearer ([a-f0-9]{64})$/)?.[1];
      if (!secret) return json({error:'unauthorized'},401);
      const [_,id,schedule] = match;
      const digest = await hash(secret);
      const existing = await env.DB.prepare('SELECT id FROM subscriptions WHERE id=? AND token_hash=? AND expires_at>?').bind(id,digest,now()).first();
      if (!existing) return json({error:'not_found'},404);
      if (!schedule && request.method === 'DELETE') {
        await env.DB.prepare('DELETE FROM subscriptions WHERE id=? AND token_hash=?').bind(id,digest).run();
        return json({deleted:true});
      }
      if (schedule && request.method === 'PUT') {
        const data = await body(request), at = now();
        if (!validSchedule(data?.reminders,at)) return json({error:'invalid_schedule'},400);
        // Only pending future rows are replaced; terminal delivery IDs remain reserved.
        const statements = [
          env.DB.prepare('DELETE FROM scheduled_notifications WHERE subscription_id=? AND state=\'pending\'').bind(id),
          ...data.reminders.map(r=>env.DB.prepare('INSERT OR IGNORE INTO scheduled_notifications(subscription_id,reminder_id,kind,due_at,lead) VALUES (?,?,?,?,?)').bind(id,r.id,r.kind,r.dueAt,r.lead)),
          env.DB.prepare('UPDATE subscriptions SET expires_at=? WHERE id=? AND token_hash=?').bind(at+30*86400000,id,digest)
        ];
        await env.DB.batch(statements);
        return json({accepted:data.reminders.length});
      }
      return json({error:'method_not_allowed'},405);
    } catch (error) {
      if (error instanceof SyntaxError || ['Invalid content type','Missing body','Body too large'].includes(error?.message)) return json({error:'invalid_body'},400);
      // Never log endpoints, tokens, keys or prayer data.
      return json({error:'request_failed'},500);
    }
  },
  async scheduled(_controller,env) {
    const at = now();
    await env.DB.batch([
      env.DB.prepare('DELETE FROM subscriptions WHERE expires_at<=?').bind(at),
      env.DB.prepare('DELETE FROM scheduled_notifications WHERE due_at<?').bind(at-7*86400000)
    ]);
    // Delivery intentionally disabled until VAPID encryption transport and consent UI are verified.
  }
};
