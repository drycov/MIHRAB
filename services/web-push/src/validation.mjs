export function validSubscription(value) {
  if (!value || typeof value.endpoint !== 'string' || value.endpoint.length > 2048) return false;
  let u;
  try { u = new URL(value.endpoint); } catch { return false; }
  const hosts = ['fcm.googleapis.com', 'updates.push.services.mozilla.com', 'web.push.apple.com'];
  if (u.protocol !== 'https:' || u.username || u.password || u.port || u.hash ||
      !hosts.includes(u.hostname) || u.pathname === '/') return false;
  const key = value.keys?.p256dh, auth = value.keys?.auth;
  return typeof key === 'string' && /^[A-Za-z0-9_-]{87}$/.test(key) &&
    typeof auth === 'string' && /^[A-Za-z0-9_-]{22}$/.test(auth);
}
export function validSchedule(rows, now) {
  if (!Array.isArray(rows) || rows.length > 60) return false;
  const ids = new Set();
  return rows.every(r => {
    if (!r || !Number.isSafeInteger(r.id) || r.id < 100000000 || r.id >= 200000000 ||
        ids.has(r.id) || !['fajr','dhuhr','asr','maghrib','isha'].includes(r.kind) ||
        ![0,5,10,15,30].includes(r.lead) || !Number.isSafeInteger(r.dueAt) ||
        r.dueAt <= now || r.dueAt > now + 6 * 86400000) return false;
    ids.add(r.id); return true;
  });
}
