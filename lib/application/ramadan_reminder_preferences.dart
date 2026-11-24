import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/ramadan_reminders.dart';

abstract final class RamadanReminderPreferences {
  static const key = 'ramadan_reminders_v1';
  static RamadanReminderSettings read(SharedPreferences prefs) {
    final raw = prefs.getString(key);
    if (raw == null) return const RamadanReminderSettings();
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic>)
      throw const FormatException('Invalid Ramadan reminder settings');
    return RamadanReminderSettings(
      suhoor: data['suhoor'] == true,
      iftar: data['iftar'] == true,
      suhoorLead: RamadanReminderSettings.validLead(data['suhoorLead'], 30),
      iftarLead: RamadanReminderSettings.validLead(data['iftarLead'], 10),
    );
  }

  static Future<void> save(
    SharedPreferences prefs,
    RamadanReminderSettings config,
  ) async {
    if (!await prefs.setString(
      key,
      jsonEncode({
        'suhoor': config.suhoor,
        'iftar': config.iftar,
        'suhoorLead': config.suhoorLead,
        'iftarLead': config.iftarLead,
      }),
    )) {
      throw StateError('Unable to save Ramadan reminders');
    }
  }
}
