import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:workmanager/workmanager.dart';
import '../application/reminder_preferences.dart';
import '../domain/prayer_schedule.dart';
import '../domain/reminders.dart';
import 'notifications.dart';
import 'reminder_lock.dart';
import 'schedule_repository.dart';

const reminderWorkName = 'mihrab.reminder.refresh.v1';

@pragma('vm:entry-point')
void reminderDispatcher() {
  Workmanager().executeTask((task, input) async {
    if (task != reminderWorkName) return true;
    try {
      WidgetsFlutterBinding.ensureInitialized();
      tz.initializeTimeZones();
      await ReminderLock.run(() async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.reload();
        final config = ReminderPreferences.read(prefs);
        if (config == null) return;
        final city = City.all[(prefs.getInt('city') ?? 0).clamp(0, City.all.length - 1).toInt()];
        final plan = ReminderPlanner.plan(city, DateTime.now(),
          hanafi: prefs.getBool('hanafi') ?? true, enabled: config.enabled,
          minutesBefore: config.lead, repository: LocalScheduleRepository(prefs));
        await Notifications().replace(plan, preferExact: config.exact);
        await prefs.setString('reminder_last_background_success', DateTime.now().toUtc().toIso8601String());
      });
      return true;
    } catch (error) {
      debugPrint('MIHRAB background reminder refresh failed: $error');
      return false;
    }
  });
}

Future<void> initializeBackgroundReminders() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  await Workmanager().initialize(reminderDispatcher);
  await Workmanager().registerPeriodicTask(reminderWorkName, reminderWorkName,
    frequency: const Duration(hours: 12),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: const Duration(minutes: 15));
}
