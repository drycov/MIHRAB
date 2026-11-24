# Web Push client preview

Settings → PWA → Web Push. Explicit consent and browser permission required; independent prayer choices and lead minutes are stored locally. Existing ReminderPlanner supplies UTC times only. No GPS, diary or reading history is uploaded. Manual synchronization only; after six days no additional reminders are scheduled. No automatic background renewal.

The meta mihrab-push-api in web/index.html is deliberately empty. Set a verified HTTPS Worker origin before building a private test release. No public enablement until subscription ownership, rate limits, consent/privacy policy, real-device provider tests, token recovery and server-side deletion reliability are addressed. Browser localStorage holds a bearer credential; XSS can expose it. Scope-separated storage keys prevent accidental project collisions. Unsubscribe currently requires reachable backend; failures need retry, and browser settings can revoke permission. A 404 after server expiry may require manual cleanup; do not clear credentials blindly. Browser permission and actual push subscription are distinct from stored registration state. No test-push endpoint or production configuration added.

Run flutter analyze/test and release web build, then generate PWA worker. Verify Android Chrome and installed iOS Safari, grant/deny, failed schedule upload, manual sync, unsubscribe, offline errors, no requests before consent. Not yet executed.

PWA icon exports are generated before precache hashes, including the notification icon. See docs/branding.md.
