import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('mihrabPwa')
external JSObject? get _mihrabPwa;

class WebBridgeImpl {
  static bool get isWeb => true;

  static JSObject get _api {
    final api = _mihrabPwa;
    if (api == null) {
      throw StateError('mihrabPwa is not loaded');
    }
    return api;
  }

  static Future<String> requestNotifications() async {
    try {
      final result = _api.callMethod('requestNotifications'.toJS);
      if (result is JSPromise) {
        final value = await result.toDart;
        return value?.toString() ?? 'denied';
      }
      return result?.toString() ?? 'denied';
    } catch (_) {
      return 'unsupported';
    }
  }

  static String notificationPermission() {
    try {
      final result = _api.callMethod('notificationPermission'.toJS);
      return result?.toString() ?? 'unsupported';
    } catch (_) {
      return 'unsupported';
    }
  }

  static Future<bool> showNotification({
    required String title,
    required String body,
    String tag = 'mihrab',
  }) async {
    try {
      final result = _api.callMethod(
        'showNotification'.toJS,
        title.toJS,
        body.toJS,
        tag.toJS,
      );
      if (result is JSPromise) {
        final value = await result.toDart;
        return value == true;
      }
      return result == true;
    } catch (_) {
      return false;
    }
  }

  static Future<int> scheduleReminders(List<Map<String, Object?>> items) async {
    try {
      final json = jsonEncode(items);
      final result = _api.callMethod('scheduleReminders'.toJS, json.toJS);
      if (result is JSPromise) {
        final value = await result.toDart;
        if (value is num) return value.toInt();
        return int.tryParse(value?.toString() ?? '') ?? 0;
      }
      if (result is num) return result.toInt();
      return int.tryParse(result?.toString() ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> clearReminders() async {
    try {
      final result = _api.callMethod('clearReminders'.toJS);
      if (result is JSPromise) await result.toDart;
    } catch (_) {}
  }

  static Future<({double lat, double lng, double accuracy})> getPosition() async {
    try {
      final result = _api.callMethod('getPosition'.toJS);
      final dynamic value = result is JSPromise ? await result.toDart : result;
      final map = jsonDecode(value.toString()) as Map<String, dynamic>;
      return (
        lat: (map['lat'] as num).toDouble(),
        lng: (map['lng'] as num).toDouble(),
        accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0,
      );
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Разрешите') ||
          msg.contains('GPS') ||
          msg.contains('Гео') ||
          msg.contains('Таймаут') ||
          msg.contains('координат')) {
        throw msg.replaceAll('Exception: ', '').replaceAll('"', '');
      }
      rethrow;
    }
  }
}
