// Explicit opt-in only. No network calls until user requests an operation.
(() => {
  const storageKey = 'mihrab.push.v1:' + new URL('.', document.baseURI).pathname;
  const load = () => { try { return JSON.parse(localStorage.getItem(storageKey)); } catch (_) { return null; } };
  const config = () => {
    const raw = document.querySelector('meta[name="mihrab-push-api"]')?.content;
    if (!raw) return null;
    try { const u = new URL(raw); return u.protocol === 'https:' && !u.username && !u.password && u.pathname === '/' && !u.search && !u.hash ? u.origin : null; } catch (_) { return null; }
  };
  const supported = () => window.isSecureContext && 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;
  async function registration() {
    const r = await navigator.serviceWorker.getRegistration(new URL('.', document.baseURI).pathname);
    if (!r?.active || !r.active.scriptURL.endsWith('/mihrab-sw.js')) throw Error('worker_unavailable');
    return r;
  }
  async function api(path, method, data, credentials) {
    const base = config();
    if (!base || (credentials && credentials.origin !== base)) throw Error('not_configured');
    const response = await fetch(base + path, {method, credentials:'omit', redirect:'error', cache:'no-store', signal:AbortSignal.timeout(15000),
      headers:{...(data === undefined ? {} : {'Content-Type':'application/json'}), ...(credentials ? {Authorization:'Bearer '+credentials.token} : {})},
      ...(data === undefined ? {} : {body:JSON.stringify(data)})});
    if (!response.ok) throw Error('http_'+response.status);
    return response.json();
  }
  function key(s) {
    if (typeof s !== 'string' || !/^[A-Za-z0-9_-]{87}$/.test(s)) throw Error('invalid_key');
    const bytes = Uint8Array.from(atob(s.replaceAll('-','+').replaceAll('_','/')+'='), c=>c.charCodeAt(0));
    if(bytes.length!==65 || bytes[0]!==4) throw Error('invalid_key');
    return bytes;
  }
  let busy = false;
  async function run(operation) {
    if (busy) return 'busy';
    busy = true;
    try { await operation(); return 'ok'; } catch (_) { return 'error'; } finally { busy = false; }
  }
  async function sync(rows) {
    const c = load();
    if (!c) throw Error('not_subscribed');
    const sub = await (await registration()).pushManager.getSubscription();
    if (!sub || sub.endpoint !== c.endpoint || Notification.permission !== 'granted') throw Error('subscription_changed');
    const future = rows.filter(r=>r.dueAt>Date.now()+20000);
    await api('/v1/subscriptions/'+c.id+'/schedule','PUT',{reminders:future},c);
    localStorage.setItem(storageKey,JSON.stringify({...c,until:future.reduce((n,r)=>Math.max(n,r.dueAt),0)}));
  }
  window.mihrabPush = {
    status: () => JSON.stringify({configured:!!config(),supported:supported(),subscribed:!!load(),until:load()?.until || 0,permission: supported()?Notification.permission:'unsupported'}),
    subscribe: (locale,raw) => run(async () => {
      if(!supported() || !config() || load()) throw Error('unavailable');
      // Call permission directly within user activation, before network awaits.
      if(await Notification.requestPermission() !== 'granted') throw Error('denied');
      const r = await registration();
      const k = key((await api('/v1/vapid-public-key','GET')).key);
      let sub = await r.pushManager.getSubscription(), created = false, c;
      try {
        if(!sub) {sub = await r.pushManager.subscribe({userVisibleOnly:true,applicationServerKey:k}); created=true;}
        const result = await api('/v1/subscriptions','POST',{subscription:sub.toJSON(),locale,consent:true});
        if(!/^[a-f0-9-]{36}$/.test(result.id)||!/^[a-f0-9]{64}$/.test(result.token)) throw Error('invalid_response');
        c = {id:result.id,token:result.token,origin:config(),endpoint:sub.endpoint,until:0};
        localStorage.setItem(storageKey,JSON.stringify(c));
        await sync(JSON.parse(raw));
      } catch(e) {
        // Preserve credentials after registration so a failed sync can be retried.
        if(!c && created) await sub.unsubscribe().catch(()=>{});
        throw e;
      }
    }),
    sync: raw => run(()=>sync(JSON.parse(raw))),
    unsubscribe: () => run(async()=>{
      const c=load();
      if(c) await api('/v1/subscriptions/'+c.id,'DELETE',undefined,c);
      const r=await registration(), sub=await r.pushManager.getSubscription();
      if(sub) await sub.unsubscribe();
      localStorage.removeItem(storageKey);
    })
  };
})();
