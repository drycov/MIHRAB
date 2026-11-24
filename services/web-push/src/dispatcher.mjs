import {sendPush} from './push.mjs';
const names={ru:['Фаджр','Зухр','Аср','Магриб','Иша'],kk:['Таң','Бесін','Екінті','Ақшам','Құптан'],ar:['الفجر','الظهر','العصر','المغرب','العشاء'],en:['Fajr','Dhuhr','Asr','Maghrib','Isha']};
export function payload(row) {
 const i=['fajr','dhuhr','asr','maghrib','isha'].indexOf(row.kind);
 const name=(names[row.locale]||names.ru)[i];
 return {title:'MIHRAB',body:name,tag:'prayer-'+row.reminder_id,lead:row.lead};
}
export async function dispatch(env,at=Date.now(),send=sendPush) {
 if(env.ENABLE_DELIVERY!=='true'||env.ENABLE_REGISTRATION!=='true'||!env.VAPID_PRIVATE_KEY||!env.VAPID_PUBLIC_KEY||!env.VAPID_SUBJECT) return;
 // Do not send outdated reminders. Ambiguous transport outcomes are terminal
 // to avoid duplicate notifications; this is at-most-one attempt, not guaranteed delivery.
 await env.DB.prepare("UPDATE scheduled_notifications SET state='failed' WHERE state='pending' AND due_at<?").bind(at-120000).run();
 const {results}=await env.DB.prepare("SELECT n.*,s.endpoint,s.p256dh,s.auth,s.locale FROM scheduled_notifications n JOIN subscriptions s ON s.id=n.subscription_id WHERE n.state='pending' AND n.due_at BETWEEN ? AND ? AND s.expires_at>? ORDER BY n.due_at LIMIT 20").bind(at-120000,at,at).all();
 for(const row of results) {
  const claim=await env.DB.prepare("UPDATE scheduled_notifications SET state='claimed' WHERE subscription_id=? AND reminder_id=? AND state='pending' AND due_at=? AND EXISTS (SELECT 1 FROM subscriptions WHERE id=? AND expires_at>?)").bind(row.subscription_id,row.reminder_id,row.due_at,row.subscription_id,Date.now()).run();
  if(!claim.meta.changes) continue;
  let status=0;
  try {status=await send({endpoint:row.endpoint,keys:{p256dh:row.p256dh,auth:row.auth}},payload(row),env);}catch{}
  if(status===404||status===410) await env.DB.prepare('DELETE FROM subscriptions WHERE id=?').bind(row.subscription_id).run();
  else await env.DB.prepare("UPDATE scheduled_notifications SET state=? WHERE subscription_id=? AND reminder_id=? AND state='claimed'").bind(status>=200&&status<300?'sent':'failed',row.subscription_id,row.reminder_id).run();
 }
}
