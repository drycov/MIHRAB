# Firebase / FCM integration preview

Dependencies: firebase_core and firebase_messaging. Native registration is explicitly opt-in; default builds have no Firebase project configured. No analytics, Firestore, Auth or Crashlytics added. Existing local notifications and Web Push remain independent.

Register Android and iOS apps with ID kz.zeus.mihrab in Firebase Console. For each platform supply its own FirebaseOptions via a local --dart-define-from-file=firebase-defines.local.json:
```json
{
  "MIHRAB_FIREBASE_ENABLED": "true",
  "FIREBASE_API_KEY": "",
  "FIREBASE_APP_ID": "",
  "FIREBASE_MESSAGING_SENDER_ID": "",
  "FIREBASE_PROJECT_ID": ""
}
```
Fill actual client configuration from Firebase Console. Never use service account keys in app defines. Explicit Dart options avoid requiring google-services.json in unconfigured CI; Android native background initialization and plugin/AGP compatibility must be verified. Follow FlutterFire setup for native platform configuration as needed. For iOS configure Push Notifications entitlement with the correct provisioning profile, upload APNs authentication key in Firebase Console, enable Background Modes / Remote notifications for background data processing, and verify the existing App Group remains present. No signing entitlement or team is fabricated.

Settings → Firebase / FCM → Enable FCM, grant permission, copy token and use Firebase Console test message. APNs token may not be available immediately; retry after registration. Disable FCM turns off auto-init and deletes token, but does not revoke OS permission. Foreground messages currently display only while the Firebase settings screen is mounted. OS-handled notification payloads in background require real-device verification; background data handlers and app-wide routing are not implemented.

Web: Firebase Core options are supported by the runtime, but FCM token creation intentionally disabled to avoid conflict with existing mihrab-sw.js and raw PushManager subscription. Next integrate a single worker using Firebase JS SDK and explicit serviceWorkerRegistration, with mutually exclusive transport selection. No competing firebase-messaging-sw.js added. Backend FCM HTTP v1 sending, automatic token synchronization and prayer scheduling over FCM are pending.

Before enabling publicly update privacy policy and store declarations for Firebase Installations/FCM identifiers and Google processing. Build and test all platforms; dependency resolution and native builds not yet verified.

References: https://firebase.google.com/docs/flutter/setup ; https://firebase.google.com/docs/cloud-messaging/flutter/get-started ; https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages
