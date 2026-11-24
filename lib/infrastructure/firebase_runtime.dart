import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Configuration is injected per platform. No credentials or project IDs
/// are assumed. Local reminders remain independent.
abstract final class FirebaseRuntime {
  static const enabled = bool.fromEnvironment('MIHRAB_FIREBASE_ENABLED');
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const vapidKey = String.fromEnvironment('FIREBASE_VAPID_KEY');
  static bool get supported => kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  static bool get configured => enabled && supported &&
      apiKey.isNotEmpty && appId.isNotEmpty && senderId.isNotEmpty &&
      projectId.isNotEmpty;
  static Future<FirebaseApp>? _initializing;
  static Future<FirebaseApp> initialize() {
    if (!configured) return Future.error(StateError('Firebase not configured'));
    return _initializing ??= _initialize();
  }
  static Future<FirebaseApp> _initialize() async {
    try {
      final app = await Firebase.initializeApp(options: const FirebaseOptions(
        apiKey: apiKey, appId: appId, messagingSenderId: senderId,
        projectId: projectId, iosBundleId: 'kz.zeus.mihrab',
      ));
      return app;
    } catch (_) {
      _initializing = null;
      rethrow;
    }
  }

  /// Native only until the existing web worker is explicitly integrated
  /// with Firebase JS SDK. Never create a second competing PWA subscription.
  static Future<String?> enableMessaging() async {
    if (kIsWeb || !configured) return null;
    await initialize();
    final messaging = FirebaseMessaging.instance;
    final permission = await messaging.requestPermission();
    if (permission.authorizationStatus != AuthorizationStatus.authorized &&
        permission.authorizationStatus != AuthorizationStatus.provisional) return null;
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        await messaging.getAPNSToken() == null) return null;
    await messaging.setAutoInitEnabled(true);
    return messaging.getToken();
  }

  static Future<void> disableMessaging() async {
    if (kIsWeb || !configured) return;
    await initialize();
    await FirebaseMessaging.instance.setAutoInitEnabled(false);
    await FirebaseMessaging.instance.deleteToken();
  }

  static Future<void> copyToken(String token) =>
      Clipboard.setData(ClipboardData(text: token));
}
