import {test} from 'node:test';
import assert from 'node:assert/strict';
import {validSubscription,validSchedule} from '../src/validation.mjs';
const good = {endpoint:'https://fcm.googleapis.com/fcm/send/example',keys:{p256dh:'A'.repeat(87),auth:'A'.repeat(22)}};
test('allowlist and credential lengths',()=>{
 assert.equal(validSubscription(good),true);
 for (const endpoint of ['http://fcm.googleapis.com/a','https://127.0.0.1/a','https://fcm.googleapis.com.evil.test/a','https://user@fcm.googleapis.com/a','https://fcm.googleapis.com:8443/a']) assert.equal(validSubscription({...good,endpoint}),false);
 assert.equal(validSubscription({...good,keys:{p256dh:'x',auth:'x'}}),false);
});
test('bounded future schedule and unique IDs',()=>{
 const now=1700000000000,r={id:100000001,kind:'fajr',dueAt:now+60000,lead:5};
 assert.equal(validSchedule([r],now),true);
 assert.equal(validSchedule([r,r],now),false);
 assert.equal(validSchedule([{...r,dueAt:now}],now),false);
 assert.equal(validSchedule([{...r,dueAt:now+7*86400000}],now),false);
 assert.equal(validSchedule([{...r,kind:'sunrise'}],now),false);
 assert.equal(validSchedule([],now),true);
});
