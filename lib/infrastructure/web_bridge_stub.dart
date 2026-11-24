class WebBridgeImpl {
  static bool get isWeb => false;

  static Future<String> requestNotifications() async => 'unsupported';

  static String notificationPermission() => 'unsupported';

  static Future<bool> showNotification({
    required String title,
    required String body,
    String tag = 'mihrab',
  }) async =>
      false;

  static Future<int> scheduleReminders(List<Map<String, Object?>> items) async =>
      0;

  static Future<void> clearReminders() async {}

  static Future<({double lat, double lng, double accuracy})> getPosition() async {
    throw 'Геолокация недоступна';
  }
}
