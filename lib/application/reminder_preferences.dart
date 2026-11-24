import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/prayer_schedule.dart';
import '../domain/prayer_sound.dart';

class ReminderPreferences {
  ReminderPreferences({
    required Set<PrayerKind> enabled,
    required this.lead,
    required this.exact,
    Map<PrayerKind, PrayerSound> sounds = const {},
  }) : enabled = Set.unmodifiable(enabled.where((p) => p.obligatory)),
       sounds = Map.unmodifiable(sounds);
  final Set<PrayerKind> enabled;
  final int lead;
  final bool exact;
  final Map<PrayerKind, PrayerSound> sounds;
  static const key = 'reminder_config_v1';
  static int validLead(int? value) =>
      [0, 5, 10, 15, 30].contains(value) ? value! : 0;

  static ReminderPreferences? read(SharedPreferences prefs) {
    final raw = prefs.getString(key);
    if (raw != null) {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic> ||
          data['enabled'] is! List ||
          data['lead'] is! int ||
          data['exact'] is! bool) {
        throw const FormatException('Invalid reminder configuration');
      }
      return ReminderPreferences(
        enabled:
            PrayerKind.values
                .where((p) => (data['enabled'] as List).contains(p.name))
                .toSet(),
        lead: validLead(data['lead'] as int),
        exact: data['exact'] as bool,
        sounds: {
          for (final p in PrayerKind.values.where((p) => p.obligatory))
            p: PrayerSound.parse(
              data['sounds'] is Map ? (data['sounds'] as Map)[p.name] : null,
            ),
        },
      );
    }
    final legacy = prefs.getStringList('reminder_prayers');
    if (legacy == null) return null;
    return ReminderPreferences(
      enabled: PrayerKind.values.where((p) => legacy.contains(p.name)).toSet(),
      lead: validLead(prefs.getInt('reminder_lead')),
      exact: prefs.getBool('reminder_exact') ?? false,
    );
  }

  Future<void> save(SharedPreferences prefs) async {
    if (!await prefs.setString(
      key,
      jsonEncode({
        'enabled': enabled.map((p) => p.name).toList(),
        'lead': validLead(lead),
        'exact': exact,
        'sounds': {
          for (final entry in sounds.entries) entry.key.name: entry.value.name,
        },
      }),
    )) {
      throw StateError('Unable to save reminder configuration');
    }
  }
}
