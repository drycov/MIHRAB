PRAGMA foreign_keys = ON;
CREATE TABLE subscriptions (
 id TEXT PRIMARY KEY,
 token_hash TEXT NOT NULL,
 endpoint TEXT NOT NULL UNIQUE,
 p256dh TEXT NOT NULL,
 auth TEXT NOT NULL,
 locale TEXT NOT NULL CHECK(locale IN ('ru','kk','ar','en')),
 expires_at INTEGER NOT NULL,
 created_at INTEGER NOT NULL
);
CREATE TABLE scheduled_notifications (
 subscription_id TEXT NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
 reminder_id INTEGER NOT NULL,
 kind TEXT NOT NULL CHECK(kind IN ('fajr','dhuhr','asr','maghrib','isha')),
 due_at INTEGER NOT NULL,
 lead INTEGER NOT NULL CHECK(lead IN (0,5,10,15,30)),
 state TEXT NOT NULL DEFAULT 'pending' CHECK(state IN ('pending','claimed','sent','failed')),
 PRIMARY KEY(subscription_id,reminder_id)
);
CREATE INDEX scheduled_due ON scheduled_notifications(state,due_at);
