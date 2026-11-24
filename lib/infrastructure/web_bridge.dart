import 'web_bridge_stub.dart'
    if (dart.library.js_interop) 'web_bridge_web.dart' as impl;

/// Browser PWA helpers (notifications + GPS). No-op on non-web.
abstract final class WebBridge {
  static bool get isWeb => impl.WebBridgeImpl.isWeb;

  static Future<String> requestNotifications() =>
      impl.WebBridgeImpl.requestNotifications();

  static String notificationPermission() =>
      impl.WebBridgeImpl.notificationPermission();

  static Future<bool> showNotification({
    required String title,
    required String body,
    String tag = 'mihrab',
  }) =>
      impl.WebBridgeImpl.showNotification(title: title, body: body, tag: tag);

  /// items: maps with id, title, body, atMs (epoch ms)
  static Future<int> scheduleReminders(List<Map<String, Object?>> items) =>
      impl.WebBridgeImpl.scheduleReminders(items);

  static Future<void> clearReminders() => impl.WebBridgeImpl.clearReminders();

  /// Returns lat/lng/accuracy or throws a user-facing String.
  static Future<({double lat, double lng, double accuracy})> getPosition() =>
      impl.WebBridgeImpl.getPosition();
}
